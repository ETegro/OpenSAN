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

local function is_disk( disk )
	assert( disk and common.is_string( disk ) )
	local dev_exists = string.match( disk, "^/dev/[^/]+$" )
	if not dev_exists then return false end
	return true
end

--------------------------------------------------------------------------
-- PhysicalVolume
--------------------------------------------------------------------------
M.PhysicalVolume = {}

M.PhysicalVolume.create = function( disk )
	assert( is_disk( disk ) )
	common.system_succeed( "dd if=/dev/zero of=" .. disk .. " bs=512 count=1" )
	common.system_succeed( "pvcreate " .. disk )
end

M.PhysicalVolume.remove = function( disk )
	assert( is_disk( disk ) )
	common.system_succeed( "pvremove " .. disk )
end

M.PhysicalVolume.rescan = function()
	common.system_succeed( "pvscan" )
end

M.PhysicalVolume.list = function()
	local physical_volumes = {}
	for _, line in ipairs( common.system_succeed( "pvdisplay -c" ) ) do
		if string.match( line, ":.*:.*:.*:" ) then
		--   /dev/sda5:build:485822464:-1:8:8:-1:4096:59304:0:59304:Ph8MnV-X6m3-h3Na-XI3L-H2N5-dVc7-ZU20Sy
		local device, capacity, volumes, extent, total, free, allocated = string.match( line, "^%s*([/%w]+):[^:]*:(%d+):[\-%d]+:%d+:%d+:([\-%d]+):(%d+):(%d+):(%d+):(%d+):[\-%w]+$" )
		extent = tonumber( extent )
		if extent == 0 then extent = 4096 end
		capacity = tonumber( capacity ) * 0.5
		total = tonumber( total ) * extent / 1024
		free = tonumber( free ) * extent / 1024
		allocated = tonumber( allocated ) * extent / 1024
		volumes = tonumber( volumes )
		capacity = capacity / 1024
		unusable = capacity % extent / 1024

		assert( common.is_number( total ) )
		assert( common.is_number( free ) )
		assert( common.is_number( allocated ) )
		assert( common.is_number( volumes ) )
		assert( common.is_number( capacity ) )
		assert( common.is_number( unusable ) )
		assert( common.is_number( extent ) )
		assert( is_disk( device ) )

		physical_volumes[ #physical_volumes + 1 ] = {
			total = total,
			free = free,
			allocated = allocated,
			volumes = volumes,
			capacity = capacity,
			unusable = unusable,
			extent = extent,
			device = device
		}
		end
	end
	return physical_volumes
end

M.PhysicalVolume.list2disks = function( physical_volumes )
	return common.keys( common.unique_keys( "device", physical_volumes ) )
end

--------------------------------------------------------------------------
-- VolumeGroup
--------------------------------------------------------------------------
M.VolumeGroup = {}

M.VolumeGroup.create = function( name, disks )
	assert( name and common.is_string( name ) )
	assert( disks and common.is_array( disks ) )

	-- Sanity checks
	for _, volume_group in ipairs( M.VolumeGroup.list( M.PhysicalVolume.list2disks( M.PhysicalVolume.list() ) ) ) do
		if name == volume_group.name then
			error( "lvm:VolumeGroup.create(): such name already exists" )
		end
		for _, disk in ipairs( disks ) do
			assert( is_disk( disk ) )
			if common.is_in_array( disk, volume_group.disks ) then
				error( "lvm:VolumeGroup.create(): disk already is in VolumeGroup" )
			end
		end
	end
	common.system_succeed( "vgcreate " ..
	                       name .. " " ..
	                       table.concat( disks, " " ) )
end

M.VolumeGroup.remove = function( name )
	assert( name and common.is_string( name ) )
	common.system_succeed( "vgremove " .. name )
end

M.VolumeGroup.rescan = function()
	common.system_succeed( "vgscan --mknodes" )
	common.system_succeed( "vgchange -a y" )
end

M.VolumeGroup.list = function( disks )
	assert( disks and common.is_array( disks ) )
	local physical_volumes = {}
	for _, line in ipairs( common.system_succeed( "pvdisplay -c" ) ) do
		if string.match( line, ":.*:.*:.*:" ) then
			local disk, volume_group = string.match( line, "^%s*([/%w]+):([^:]*):%d+:.*$" )
			if volume_group and
					not string.match( volume_group, "orphans_lvm2" ) and
					common.is_in_array( disk, disks ) then
				physical_volumes[ #physical_volumes + 1 ] = { disk = disk, volume_group = volume_group }
			end
		end
	end
	local volume_groups = {}
	for _, line in ipairs( common.system_succeed( "vgdisplay -c" ) ) do
		if string.match( line, ":.*:.*:.*:" ) then
		--   build:r/w:772:-1:0:3:3:-1:0:1:1:242909184:4096:59304:59304:0:L1mhxa-57G6-NKgr-Xy0A-OJIr-zuj5-7CJpkH
		local name, max_volume, extent, total, allocated, free = string.match( line, "^%s*(%w+):[%w/]+:%d+:[%d\-]+:%d+:%d+:%d:([%d\-]+):%d+:%d+:%d+:%d+:(%d+):(%d+):(%d+):(%d+):[\-%w]+$" )
		extent = tonumber( extent )
		max_volume = tonumber( max_volume )
		total = tonumber( total ) * extent / 1024
		allocated = tonumber( allocated ) * extent / 1024
		free = tonumber( free ) * free / 1024
		number = tonumber( string.match( name, "(%d+)$" ) )
		assert( common.is_number( extent ) )
		assert( common.is_number( max_volume ) )
		assert( common.is_number( total ) )
		assert( common.is_number( allocated ) )
		assert( common.is_number( free ) )
		--assert( common.is_number( number ) )

		volume_groups[ #volume_groups + 1 ] = {
			name = name,
			max_volume = max_volume,
			extent = extent,
			total = total,
			allocated = allocated,
			free = free,
			number = number,
			disks = {}
		}
		end
	end
	for _, physical_volume in ipairs( physical_volumes ) do
		for _, volume_group in ipairs( volume_groups ) do
			if volume_group.name == physical_volume.volume_group then
				volume_group.disks[ #volume_group.disks + 1 ] = physical_volume.disk
			end
		end
	end
	return volume_groups
end

--------------------------------------------------------------------------
-- LogicalVolume
--------------------------------------------------------------------------
M.LogicalVolume.remove = function( volume_group, name )
	assert( volume_group and common.is_table( volume_group ) )
	assert( name and common.is_string( name ) )
	common.system_succeed( "lvremove -f " ..
	                       volume_group.name .. "/" ..
	                       name )
end

M.LogicalVolume.rescan = function()
	common.system_succeed( "lvscan" )
end

--------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------
M.DM_MODULES = { "dm_mod", "dm_log", "dm_mirror", "dm_snapshot" }

local function load_modules()
	for _, dm_module in ipairs( M.DM_MODULES ) do
		common.system_succeed( "modprobe " .. dm_module )
	end
end

M.is_running = function()
	-- TODO: replace with sysfs
	for _, line in ipairs( common.system_succeed( "lsmod" ) ) do
		if string.match( line, "dm_mod" ) then
			return true
		end
	end
	return false
end

local function restore_lvm()
	M.PhysicalVolume.rescan()
	M.VolumeGroup.rescan()
	M.LogicalVolume.rescan()
end

M.start = function()
	if M.is_running() then return end
	local succeeded, result = pcall( load_modules )
	if not succeeded then error( "lvm:start() failed" ) end
	restore_lvm()
end

return M
