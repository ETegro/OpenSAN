--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
                          Sergey Matveev <stargrave@stargrave.org>
  
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.
  
  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local M = {}

local common = require( "astor2.common" )

--- Check if specified string is a disk device
-- It performs simple matching by ^/dev/ regular expression
-- @param disk Disk path to check
-- @return true/false
local function is_disk( disk )
	assert( disk and common.is_string( disk ),
	        "no disk specified" )
	local dev_exists = string.match( disk, "^/dev/[^/]+$" )
	if not dev_exists then return false end
	return true
end

--------------------------------------------------------------------------
-- PhysicalVolume
--------------------------------------------------------------------------
M.PhysicalVolume = {}
local PhysicalVolume_mt = common.Class( M.PhysicalVolume )

function M.PhysicalVolume:new( attrs )
	assert( common.is_number( attrs.total ),
	        "non-number total" )
	assert( common.is_number( attrs.free ),
	        "non-number free" )
	assert( common.is_number( attrs.allocated ),
	        "non-number allocated" )
	assert( common.is_number( attrs.volumes ),
	        "non-number volumes" )
	assert( common.is_positive( attrs.capacity ),
	        "non-positive capacity" )
	assert( common.is_number( attrs.unusable ),
	        "non-number unusable" )
	assert( common.is_number( attrs.extent ),
	        "non-number extent" )
	assert( common.is_string( attrs.volume_group ),
	        "no volume group attribute" )
	assert( is_disk( attrs.device ),
	        "device is not a disk" )
	return setmetatable( attrs, PhysicalVolume_mt )
end

--- Create PhysicalVolume on a disk
-- @param disk Disk on which volume must be created
function M.PhysicalVolume.create( disk )
	assert( is_disk( disk ),
	        "incorrect disk specified" )
	common.system_succeed( "dd if=/dev/zero of=" .. disk .. " bs=512 count=1" )
	common.system_succeed( "lvm pvcreate " .. disk )
end

--- Remove PhysicalVolume
function M.PhysicalVolume:remove()
	assert( is_disk( self.device ),
	        "unable to verify self object" )
	common.system_succeed( "lvm pvremove " .. self.device )
end

--- Rescan all PhysicalVolumes on a system
function M.PhysicalVolume.rescan()
	common.system_succeed( "lvm pvscan" )
end

--- List all PhysicalVolumes
-- @return { PhysicalVolume, PhysicalVolume }
function M.PhysicalVolume.list()
	local physical_volumes = {}
	for _, line in ipairs( common.system_succeed( "lvm pvdisplay -c" ) ) do
		if string.match( line, ":.*:.*:.*:" ) then
		--   /dev/sda5:build:485822464:-1:8:8:-1:4096:59304:0:59304:Ph8MnV-X6m3-h3Na-XI3L-H2N5-dVc7-ZU20Sy
		local device, volume_group, capacity, volumes, extent, total, free, allocated = string.match( line, "^%s*([/%w]+):([^:]*):(%d+):[\-%d]+:%d+:%d+:([\-%d]+):(%d+):(%d+):(%d+):(%d+):[\-%w]+$" )

		extent = tonumber( extent )
		if extent == 0 then extent = 4096 end
		extent = extent / 1024.0 -- Convert it to MiB immediately

		capacity = tonumber( capacity ) * 0.5
		capacity = capacity / 1024
		unusable = capacity % extent

		physical_volumes[ #physical_volumes + 1 ] = M.PhysicalVolume:new( {
			total = tonumber( total ) * extent,
			free = tonumber( free ) * extent,
			allocated = tonumber( allocated ) * extent,
			volumes = tonumber( volumes ),
			capacity = capacity,
			unusable = unusable,
			extent = extent,
			device = device,
			volume_group = volume_group
		} )
		end
	end
	return physical_volumes
end

--------------------------------------------------------------------------
-- VolumeGroup
--------------------------------------------------------------------------
M.VolumeGroup = {}
local VolumeGroup_mt = common.Class( M.VolumeGroup )

function M.VolumeGroup:new( attrs )
	assert( common.is_number( attrs.extent ),
	        "non-number extent" )
	assert( common.is_number( attrs.max_volume ),
	        "non-number max_volume" )
	assert( common.is_number( attrs.total ),
	        "non-number total" )
	assert( common.is_number( attrs.allocated ),
	        "non-number allocated" )
	assert( common.is_number( attrs.free ),
	        "non-number free" )
	--assert( common.is_number( attrs.number ) )
	return setmetatable( attrs, VolumeGroup_mt )
end

function M.VolumeGroup.next_vg_name()
	return "vg" .. tostring( os.time() )
end

--- Create VolumeGroup
-- @param physical_volumes List of PhysicalVolumes to create group on
function M.VolumeGroup.create( physical_volumes )
	assert( physical_volumes and common.is_array( physical_volumes ),
	        "no physical volumes specified" )
	local name = M.VolumeGroup.next_vg_name()

	-- Sanity checks
	for _, volume_group in ipairs( M.VolumeGroup.list( physical_volumes ) ) do
		if name == volume_group.name then
			error( "lvm:VolumeGroup.create(): such name already exists" )
		end
	end
	for _, physical_volume in ipairs( physical_volumes ) do
		if physical_volume.volume_group and
		   not string.match( physical_volume.volume_group, "#orphans_" ) then
			error( "lvm:VolumeGroup.create(): disk already is in VolumeGroup" )
		end
	end

	common.system_succeed( "lvm vgcreate " ..
	                       name .. " " ..
	                       table.concat( common.keys( common.unique_keys( "device", physical_volumes ) ), " " ) )
end

--- Remove VolumeGroup
function M.VolumeGroup:remove()
	assert( self.name and common.is_string( self.name ),
	        "unable to get self object" )
	common.system_succeed( "lvm vgremove " .. self.name )
end

--- Rescan all VolumeGroups on a system
function M.VolumeGroup.rescan()
	common.system_succeed( "lvm vgscan --ignorelockingfailure --mknodes" )
	common.system_succeed( "lvm vgchange -aly --ignorelockingfailure" )
end

--- List all VolumeGroups that are on specified PhysicalVolumes
-- @param physical_volumes PhysicalVolumes to check
-- @return { VolumeGroup, VolumeGroup }
function M.VolumeGroup.list( physical_volumes )
	local volume_groups = {}
	for _, line in ipairs( common.system_succeed( "lvm vgdisplay -c" ) ) do
		if string.match( line, ":.*:.*:.*:" ) then
		--   build:r/w:772:-1:0:3:3:-1:0:1:1:242909184:4096:59304:59304:0:L1mhxa-57G6-NKgr-Xy0A-OJIr-zuj5-7CJpkH
		local name, max_volume, extent, total, allocated, free = string.match( line, "^%s*(%w+):[%w/]+:%d+:[%d\-]+:%d+:%d+:%d:([%d\-]+):%d+:%d+:%d+:%d+:(%d+):(%d+):(%d+):(%d+):[\-%w]+$" )

		extent = tonumber( extent )
		extent = extent / 1024.0

		local physicals_volumes_in_group = {}
		for _, physical_volume in ipairs( physical_volumes ) do
			if physical_volume.volume_group == name then
				physicals_volumes_in_group[ #physicals_volumes_in_group + 1 ] = physical_volume
			end
		end

		if #physicals_volumes_in_group ~= 0 then
		volume_groups[ name ] = M.VolumeGroup:new({
			name = name,
			max_volume = tonumber( max_volume ),
			extent = extent,
			total = tonumber( total ) * extent,
			allocated = tonumber( allocated ) * extent,
			free = tonumber( free ) * free,
			number = tonumber( string.match( name, "(%d+)$" ) ),
			physical_volumes = physicals_volumes_in_group
		})
		end
		end
	end
	return common.values( volume_groups ) or {}
end

--- Create LogicalVolume on a VolumeGroup
-- @param name Name of LogicalVolume
-- @param size Size of LogicalVolume
function M.VolumeGroup:logical_volume( name, size )
	assert( self.name,
	        "unable to get self object" )
	assert( name and common.is_string( name ),
	        "no name specified" )
	assert( size and common.is_positive( size ),
	        "non-positive size specified" )
	local output = common.system( "lvm lvcreate -n " ..
	                              name ..
	                              " -L " ..
				      tostring( size ) ..
				      " " ..
				      self.name )
	local succeeded = false
	for _, line in ipairs( output.stdout ) do
		if string.match( line, "Logical volume \".+\" created" ) then
			succeeded = true
		end
	end
	if not succeeded then
		error("lvm:VolumeGroup:logical_volume() failed: " .. table.concat( output.stdout, "\n" ) )
	end
end

--------------------------------------------------------------------------
-- LogicalVolume
--------------------------------------------------------------------------
M.LogicalVolume = {}
local LogicalVolume_mt = common.Class( M.LogicalVolume )

M.LogicalVolume.name_valid_re = "^[A-Za-z0-9\-_#%%:]+$"

function M.LogicalVolume:new( attrs )
	assert( common.is_string( attrs.name ),
	        "empty name" )
	assert( common.is_string( attrs.device ),
	        "empty device" )
	assert( common.is_table( attrs.volume_group ),
	        "no volume group assigned to" )
	assert( common.is_positive( attrs.size ) )
	if not string.match( attrs.name, M.LogicalVolume.name_valid_re ) then
		error("lvm:LogicalVolume:new() incorrect name supplied")
	end
	if not attrs.snapshots then
		attrs["snapshots"] = {}
	end
	return setmetatable( attrs, LogicalVolume_mt )
end

function M.LogicalVolume:is_snapshot()
	return false
end

--- Remove LogicalVolume
function M.LogicalVolume:remove()
	assert( self.volume_group,
	        "no volume group attached to" )
	assert( self.name,
	        "unable to get self object" )
	common.system_succeed( "lvm lvremove -f " ..
	                       self.volume_group.name .. "/" ..
	                       self.name )
end

--- Rescan all LogicalVolumes on a system
function M.LogicalVolume.rescan()
	common.system_succeed( "lvm lvscan" )
end

--- Create snapshot of logical volume
-- @param size Snapshot size
-- @return Raise error if it fails
function M.LogicalVolume:snapshot( size )
	assert( self.name,
	        "unable to get self object" )
	assert( common.is_string( self.device ),
	        "empty self object's device" )
	assert( common.is_positive( size ),
	        "non-positive size specified" )
	local name = self.name .. os.date("_%Y-%m-%d_%H-%M-%S")
	local output = common.system( "lvm lvcreate -s -n " ..
	                              name ..
	                              " -L " ..
				      tostring( size ) ..
				      " " ..
				      self.device )
	local succeeded = false
	for _, line in ipairs( output.stdout ) do
		if string.match( line, "Logical volume \".+\" created" ) then
			succeeded = true
		end
	end
	if not succeeded then
		error("lvm:LogicalVolume:snapshot() failed: " .. table.concat( output.stdout, "\n" ) )
	end
end

--- List all LogicalVolumes on specified VolumeGroup
-- @param volume_groups VolumeGroups to check
-- @return { LogicalVolume, LogicalVolume }
function M.LogicalVolume.list( volume_groups )
	local result = {}
	local volume_groups_by_name = common.unique_keys( "name", volume_groups )
	for _, line in ipairs( common.system_succeed( "lvm lvs --units m -o lv_name,vg_name,lv_size,origin,snap_percent -O origin" ) ) do
		local splitted = common.split_by( line, " " )
		if splitted[1] == "LV" and splitted[2] == "VG" then
			-- Do nothing
		elseif splitted[4] and result[ splitted[4] ] then
			-- Skip if it is not needed VolumeGroup
			if common.is_in_array( splitted[2], common.keys( volume_groups_by_name ) ) then
				local snapshot = M.Snapshot:new({
					name = splitted[1],
					device = "/dev/" .. splitted[2] .. "/" .. splitted[1],
					volume_group = volume_groups[ volume_groups_by_name[ splitted[2] ][1] ],
					size = tonumber( string.sub( splitted[3], 1, -2 ) ),
					logical_volume = splitted[4],
					allocated = tonumber( splitted[5] )
				})
				result[ splitted[4] ].snapshots[ #result[ splitted[4] ].snapshots + 1 ] = snapshot
			end
		else
			-- Skip if it is not needed VolumeGroup
			if common.is_in_array( splitted[2], common.keys( volume_groups_by_name ) ) then
				result[ splitted[1] ] = M.LogicalVolume:new({
					name = splitted[1],
					device = "/dev/" .. splitted[2] .. "/" .. splitted[1],
					volume_group = volume_groups[ volume_groups_by_name[ splitted[2] ][1] ],
					size = tonumber( string.sub( splitted[3], 1, -2 ) )
				})
			end
		end
	end
	return common.values( result ) or {}
end

--- lvresize command frontend
-- @param size Size argument for lvresize command
-- @param what Target path to be resized
-- @return true/false
local function lvresize( size, logical_volume )
	local succeeded = false
	for _, line in ipairs( common.system_succeed( "echo y | lvm lvresize -L " .. tostring( size ) .. " " .. logical_volume.volume_group.name .. "/" .. logical_volume.name ) ) do
		if string.match( line, "successfully resized" ) then
			succeeded = true
		end
	end
	return succeeded
end

--- LogicalVolume resize
-- @param size New wished size
-- @return Raise error if it fails
function M.LogicalVolume:resize( size )
	assert( self.name,
	        "unable to get self object" )
	assert( common.is_positive( size ),
	        "non-positive size specified" )
	if size == self.size then return end
	if not lvresize( size, self ) then
		error( "lvm:LogicalVolume:resize() failed" )
	end
end

--------------------------------------------------------------------------
-- Snapshot
--------------------------------------------------------------------------
M.Snapshot = {}
local Snapshot_mt = common.Class( M.Snapshot )

function M.Snapshot:new( attrs )
	assert( common.is_string( attrs.name ),
	        "empty name" )
	assert( common.is_string( attrs.device ),
	        "empty device" )
	assert( common.is_table( attrs.volume_group ),
	        "no volume group assigned to" )
	assert( common.is_positive( attrs.size ),
	        "non-positive size" )
	assert( common.is_number( attrs.allocated ),
	        "non-number allocated" )
	assert( common.is_string( attrs.logical_volume ),
	        "no logical volume assigned to" )
	return setmetatable( attrs, Snapshot_mt )
end

function M.Snapshot:is_snapshot()
	return true
end

M.Snapshot.remove = M.LogicalVolume.remove

--- Snapshot resize
-- @param size New wished size
-- @return Raise error if it fails
function M.Snapshot:resize( size )
	assert( self.name,
	        "unable to get self object" )
	assert( common.is_positive( size ),
	        "non-positive size specified" )
	if size <= self.size then return end
	if not lvresize( size, self ) then
		error( "lvm:Snapshot:resize() failed" )
	end
end

--------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------
M.DM_MODULES = { "dm-mod", "dm-log", "dm-mirror", "dm-snapshot" }

--- Load all LVM-related kernel modules
local function load_modules()
	for _, dm_module in ipairs( M.DM_MODULES ) do
		common.system_succeed( "modprobe " .. dm_module )
	end
end

--- Check if LVM is running and ready for actions
-- @return true/false
M.is_running = function()
	-- TODO: replace with sysfs
	for _, line in ipairs( common.system_succeed( "lsmod" ) ) do
		if string.match( line, "dm_mod" ) then
			return true
		end
	end
	return false
end

--- Perform rescan of all LVM-related objects
local function restore_lvm()
	M.PhysicalVolume.rescan()
	M.VolumeGroup.rescan()
	M.LogicalVolume.rescan()
end

--- Start LVM subsystem if it is not running and rescan all related objects
M.start = function()
	if M.is_running() then return end
	local succeeded, result = pcall( load_modules )
	if not succeeded then error( "lvm:start() failed: " .. result ) end
	restore_lvm()
end

return M
