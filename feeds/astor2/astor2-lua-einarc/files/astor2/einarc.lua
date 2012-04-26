--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2012 ETegro Technologies, PLC
                          Sergey Matveev <stargrave@stargrave.org>
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
  
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local M = {}

require( "lfs" )
local common = require( "astor2.common" )

local EINARC_CMD = "einarc -t software -a 0 "

M.LOGICAL_STATES = {
	"normal",
	"degraded",
	"initializing",
	"rebuilding"
}
M.LOGICAL_STATES_MAP = {
	["clean"] = "normal",
	["active"] = "normal",
	["inactive"] = "failed",
	["Not Started"] = "degraded",
	["degraded"] = "degraded",
	["resyncing"] = "initializing",
	["recovering"] = "rebuilding"
}
M.PHYSICAL_STATES = {
	"hotspare",
	"failed",
	"free"
}

------------------------------------------------------------------------
-- Internals
------------------------------------------------------------------------
local function read_line( path )
	if lfs.attributes( path ) then
		return io.input( path ):read()
	end
	return nil
end

local function list_slaves( path )
	local slaves = {}
	for slave in lfs.dir( path .. "/slaves" ) do
		if slave ~= "." and slave ~= ".." then
			slaves[ #slaves + 1 ] = slave
		end
	end
	return slaves
end

local function serial_via_smart( device )
	local result = common.system( "smartctl --all " .. device )
	for _,line in ipairs( result.stdout ) do
		local serial = string.match( line, "^[Ss]erial [Nn]umber:%s*(%w+)" )
		if serial then return serial end
	end
	return nil
end

local function serial_via_udev( device )
	local result = common.system( "udevadm info --query=env --name=" .. device )
	for _,line in ipairs( result.stdout ) do
		local serial = string.match( line, "ID_SERIAL_SHORT=(.*)" )
		if serial then return serial end
		serial = string.match( line, "ID_SERIAL=(.*)" )
		if serial then return serial end
	end
	return nil
end

local function list_devices()
	local path_block = "/sys/block/"
	local devices = {}
	for ent in lfs.dir( path_block ) do
		local device = {
			devnode = ent,
			fdevnode = "/dev/" .. ent,
			path = path_block .. ent
		}
		device.size = math.floor( (tonumber( read_line( device.path .. "/size" ) ) or 0) / 2048 )
		if lfs.attributes( device.path .. "/dm/name" ) then
			local name = read_line( device.path .. "/dm/name" )
			if string.match( name, "^mpath" ) then
				device.type = "multipath"
				device.slaves = list_slaves( device.path )
				device.name = name
				device.uuid = read_line( device.path .. "/dm/uuid" )
				devices[ device.devnode ] = device
			end
		elseif lfs.attributes( device.path .. "/md" ) then
			device.type = "md"
			device.slaves = list_slaves( device.path )
			device.id = tonumber( string.sub( device.devnode, 3, -1 ) )
			devices[ device.devnode ] = device
		elseif string.sub( ent, 1, 2 ) == "sd" then
			device.type = "sd"
			device.model = read_line( device.path .. "/device/model" )
			device.revision = read_line( device.path .. "/device/rev" )
			device.vendor = read_line( device.path .. "/device/vendor" )

			device.serial = serial_via_smart( device.fdevnode )
			if not device.serial then
				device.vendor = read_line( device.path .. "/device/serial" )
			end
			if not device.serial then
				device.serial = serial_via_udev( device.fdevnode )
			end
			if not device.serial then
				device.serial = ""
			end

			devices[ device.devnode ] = device
		end
	end
	return devices
end

function M.phys_to_scsi( name )
	local root = string.match( name, "^dm.(%d+)$" )
	assert( root, "Invalid device name" )
	return "0:" .. tostring( tonumber( root ) + 1 )
end

function M.scsi_to_phys( id )
	local pre, post = string.match( id, "^(%d+):(%d+)$" )
	assert( pre == "0", "Invalid internal ID" )
	return "dm-" .. tostring( tonumber( post ) - 1 )
end

local function run2( args )
	local cycle = 4
	local result
	while cycle > 0 do
		result = common.system( "mdadm " .. args .. " 2>&1" )
		if result.return_code == 0 then
			cycle = 0
		else
			cycle = cycle - 1
			common.sleep(1)
		end
	end
	return result
end

-- TODO: remove
--- Execute einarc and get it's results
-- @param args "logical add 5 0 0:1,0:2"
-- @return Either an array of output strings from einarc, or nil if
--         einarc failed, or raise "NotImplementedError" if it is so
local function run( args )
	assert( args and common.is_string( args ),
	        "empty command line" )
	local result = common.system( EINARC_CMD .. args )
	if result.return_code ~= 0 then
		for _, line in ipairs( result.stderr ) do
			if string.match( line, "NotImplementedError" ) then
				error("NotImplementedError")
			end
		end
		return nil
	end
	return result.stdout
end

local function check_detached_hotspares()
	for _,device in pairs( list_devices() ) do
		if device.type == "md" then
			run2(device.fdevnode .. " --fail detached --remove detached")
		end
	end
end

local function multipath_devices()
	common.system("multipath")
end

------------------------------------------------------------------------
-- Adapter
------------------------------------------------------------------------
M.Adapter = {}
local Adapter_mt = common.Class( M.Adapter )
M.Adapter.raidlevels = {
	"linear",
	"passthrough",
	"0", "1", "4",
	"5", "6", "10"
}
M.Adapter.raidlevels_hotspare_compatible = {
	"1", "4", "5", "6", "10"
}

--- einarc adapter expanders
-- @return { { model = "noname", id = "13" }, ... }
function M.Adapter:expanders()
	local expanders = {}
	local ENCLOSURE_SCSI_ID = 13
	for _, line in ipairs( common.system( "sg_map" ).stdout ) do
		if #common.split_by( line, "%s" ) == 1 then
			local devtype = nil
			local model = nil
			for _, sginfo_line in ipairs( common.system( "sginfo " .. line ).stdout ) do
				if sginfo_line:sub( 1, 11 ) == "Device Type" then
					devtype = sginfo_line:match( "^Device Type%s+(%d+)$" )
				end
				if sginfo_line:sub( 1, 8 ) == "Product:" then
					model = common.strip( sginfo_line:match( "^Product:%s+(.+)$" ) )
				end
			end
			if tonumber( devtype ) == ENCLOSURE_SCSI_ID and model then
				expanders[ #expanders + 1 ] = {
					["id"] = line:sub(8,-1),
					["model"] = model
				}
			end
		end
	end
	return expanders
end

------------------------------------------------------------------------
-- Logical
------------------------------------------------------------------------
M.Logical = {}
local Logical_mt = common.Class( M.Logical )

function M.Logical:new( attrs )
	assert( common.is_number( attrs.id ),
	        "non-number ID" )
	assert( common.is_string( attrs.state ),
	        "unknown state" )
	if attrs.state ~= "failed" then
		assert( common.is_string( attrs.level ),
				"empty level" )
	end
	assert( common.is_non_negative( attrs.capacity ),
	        "non-positive capacity" )
	assert( common.is_string( attrs.device ),
	        "empty device" )
	return setmetatable( attrs, Logical_mt )
end

--- einarc logical list
-- @return { 0 = Logical, 1 = Logical }
function M.Logical.list()
	local logicals = {}
	check_detached_hotspares()
	multipath_devices()
	for _,device in pairs( list_devices() ) do
		if device.type == "md" then
			local logical = common.deepcopy( device )
			for _, what in ipairs( {
				"chunk_size",
				"level",
				"sync_speed",
				"sync_action",
				"sync_completed",
				"resync_start",
				"array_state",
				"degraded"
			} ) do
				logical[ what ] = read_line( device.path .. "/md/" .. what )
			end
			logical.state = M.LOGICAL_STATES_MAP[ logical.array_state ]
			if logical.state ~= "failed" then
				if string.sub( logical.level, 1, 4 ) == "raid" then
					logical.level = string.sub( logical.level, 5, -1 )
				else
					logical.level = "linear"
				end
			end
			logical.drives = {}
			for _,slave in ipairs( logical.slaves ) do
				logical.drives[ #logical.drives + 1 ] = M.phys_to_scsi( slave )
			end
			if logical.state == "normal" and
				logical.sync_completed and
				logical.sync_completed ~= "none" then
				logical.state = "rebuilding"
			end
			logical.capacity = logical.size
			logical.device = logical.fdevnode
			logicals[ logical.id ] = M.Logical:new( logical )
		end
	end
	return logicals
end

--- einarc logical add
-- @param raid_level "passthrough" | "linear" | "0" | "1" | "5" | "6" | "10"
-- @param drives { "0:1", "0:2", "254:1" }
-- @return Raise error if it fails
function M.Logical.add( raid_level, drives, size, properties )
	assert( raid_level, "raid_level argument is required" )
	assert( common.is_array( drives ), "drives have to be an array" )
	-- Find next md device name
	local devices = list_devices()
	local next_md_name = nil
	for i=0,127 do
		local is = tostring(i)
		if not next_md_name and not devices[ "md" .. is ] then
			next_md_name = "/dev/md" .. is
		end
	end
	assert( next_md_name, "no available md name found" )
	local cmd = {
		"yes |",
		"mdadm",
		"--create",
		"--verbose",
		next_md_name,
		"--auto=yes",
		"--force",
		"--level=" .. raid_level,
		"--raid-devices=" .. tostring( #drives ),
	}
	for _,drive in ipairs( drives ) do
		cmd[ #cmd + 1 ] = devices[ M.scsi_to_phys( drive ) ].fdevnode
	end
	local result = common.system( table.concat( cmd, " " ) )
	if result.return_code ~= 0 then
		error("einarc:logical.add() failed:" .. table.concat( result, " " ))
	end
end

--- einarc logical delete
-- @result Raise error if it fails
function M.Logical:delete()
	assert( self.id, "unable to get self object" )
	local result = run2("--stop " .. self.fdevnode)
	for _,id in pairs( self.drives ) do
		M.Physical.zero_superblock( { id = id } )
	end
	if result.return_code ~= 0 then
		error("einarc:logical.delete() failed")
	end
end

--- einarc logical hotspare_add
-- @param physical Physical
-- @return Raise error if it fails
function M.Logical:hotspare_add( physical )
	assert( self.id, "unable to get self object" )
	assert( physical and physical.id, "invalid Physical object" )
	physical:zero_superblock()
	local result = run2( self.fdevnode .. " --add " .. physical.fdevnode )
	if result.return_code ~= 0 then
		error("einarc:logical.hotspare_add() failed")
	end
end

--- einarc logical hotspare_delete
-- @param physical Physical
-- @return Raise error if it fails
function M.Logical:hotspare_delete( physical )
	assert( self.id, "unable to get self object" )
	assert( physical and physical.id, "invalid Physical object" )
	local result = run2( self.fdevnode .. " --remove " .. physical.fdevnode )
	if result.return_code ~= 0 then
		error("einarc:logical.hotspare_delete() failed")
	end
end

--- einarc logical physical_list
-- @return self.physicals = { "physical1_id" = "state", "physical2_id" = "state" }
function M.Logical:physical_list()
	if common.is_table( self.physicals ) then
		return self.physicals
	end
	assert( self.id, "unable to get self object" )
	local devices = list_devices()
	self.physicals = {}
	for _,slave in ipairs( self.slaves ) do
		local state = read_line( self.path .. "/md/dev-" .. slave .. "/state" )
		if state == "in_sync" and
			devices[ slave ] and
			devices[ slave ].slaves[1] and
			devices[ devices[ slave ].slaves[1] ] then
			state = tostring( self.id )
		elseif state == "spare" then
			state = "hotspare"
		else
			state = "failed"
		end
		self.physicals[ M.phys_to_scsi( devices[ slave ].devnode ) ] = state
	end
	return self.physicals
end

--- Retreive logical progress, if it exists
-- @return self.progress = 66.6
function M.Logical:progress_get()
	if common.is_number( self.progress ) then
		return self.progress
	end
	self.progress = nil
	local sync = read_line( self.path .. "/md/sync_completed" )
	if sync then
		local doned, total = string.match( sync, "^(%d+) / (%d+)$" )
		if doned and total then
			self.progress = tonumber( doned ) / tonumber( total )
		end
	end
	return self.progress
end

--- Disable powersaving on logical disk
function M.Logical:powersaving_disable()
	assert( self.id, "unable to get self object" )
	local physicals = M.Physical.list()
	for _,drive in ipairs( self.drives ) do
		physicals[ drive ]:powersaving_disable()
	end
end

--- Enable WriteCache on logical disk
function M.Logical:writecache_enable()
	assert( self.id, "unable to get self object" )
	local physicals = M.Physical.list()
	for _,drive in ipairs( self.drives ) do
		physicals[ drive ]:writecache_enable()
	end
end

--- Disable WriteCache on logical disk
function M.Logical:writecache_disable()
	assert( self.id, "unable to get self object" )
	local physicals = M.Physical.list()
	for _,drive in ipairs( self.drives ) do
		physicals[ drive ]:writecache_disable()
	end
end

--- Is logical disk has WriteCache enabled
-- @return true/false
function M.Logical:is_writecache()
	assert( self.id, "unable to get self object" )
	local enabled = 0
	local physicals = M.Physical.list()
	for _,drive in ipairs( self.drives ) do
		if physicals[ drive ]:is_writecache() then
			enabled = enabled + 1
		end
	end
	return enabled > 0
end

------------------------------------------------------------------------
-- Physical
------------------------------------------------------------------------
M.Physical = {}
local Physical_mt = common.Class( M.Physical )

--- Is this ID is physical id (having "666:13" kind of form)
-- @param id "0:1"
-- @return true/false
function M.Physical.is_id( id )
	if string.match( id, "^%d+:%d+$" ) then
		return true
	else
		return false
	end
end

function M.Physical:new( attrs )
	assert( M.Physical.is_id( attrs.id ),
	        "incorrect physical id" )
	assert( common.is_string( attrs.model ),
	        "empty model" )
	assert( common.is_string( attrs.revision ),
	        "empty revision" )
	assert( common.is_string( attrs.serial ),
	        "empty serial" )
	assert( common.is_non_negative( attrs.size ),
	        "non-positive size" )
	assert( common.is_string( attrs.state ),
	        "incorrect state" )

	-- Strip out whitespaces
	attrs.model = common.strip( attrs.model )
	attrs.serial = common.strip( attrs.serial )
	attrs.revision = common.strip( attrs.revision )

	return setmetatable( attrs, Physical_mt )
end

--- einarc physical list
-- @return { "0:1" = Physical, "0:2" = Physical }
function M.Physical.list()
	local physicals = {}
	local devices = list_devices()
	for _,device in pairs( devices ) do
		if device.type == "multipath" then
			local physical = common.deepcopy( device )
			physical.model = devices[ physical.slaves[1] ].model
			physical.vendor = devices[ physical.slaves[1] ].vendor
			physical.revision = devices[ physical.slaves[1] ].revision
			physical.serial = devices[ physical.slaves[1] ].serial
			physical.id = M.phys_to_scsi( physical.devnode )

			physical.state = "free"
			for _,device_int in pairs( devices ) do
				if device_int.type == "md" and
					common.is_in_array( device.devnode, device_int.slaves ) then
					local physical_list = M.Logical.physical_list( device_int )
					physical.state = physical_list[ M.phys_to_scsi( device.devnode ) ]
				end
			end

			physicals[ physical.id ] = M.Physical:new( physical )
		end
	end
	return physicals
end

function M.Physical:zero_superblock()
	assert( self.id and M.Physical.is_id( self.id ),
	        "unable to get self object" )
	run2("--zero-superblock /dev/" .. M.scsi_to_phys( self.id ))
end

local function sgmaps()
	local maps = {}
	for _,line in ipairs( common.system( "sg_map" ).stdout ) do
		local paired = common.split_by( line, "%s" )
		if #paired == 2 then
			maps[ paired[2] ] = paired[1]
		end
	end
	return maps
end

--- Try to retrieve Physical's WWN
-- @return "345...02"
function M.Physical:wwn()
	assert( self.id, "unable to get self object" )
	local SAS_PAGE = "0x19" -- SAS SSP port control mode page
	local SAS_SUBPAGE = "0x1" -- SAS Phy Control and Discover mode subpage
	local wwns = {}
	for _,line in ipairs( common.system(
		"sginfo -t " ..
		SAS_PAGE .. "," ..
		SAS_SUBPAGE .. " " ..
		sgmaps()[ self.fdevnode ]
	) ) do
		if line:sub(1,11) == "SAS address" then
			wwns[ #wwns + 1 ] = line:match( "^SAS address%s+(%w+)$" )
		end
	end
	if #wwns > 0 then return wwns end

	-- Otherwise we are dealing with SATA
	-- They can contain also two WWNs: the real one and that is visible to system
	for _,line in ipairs( common.system( "sdparm --inquiry " .. self.fdevnode ).stdout ) do
		local wwn = line:match( "^%s+(0x................)" )
		if wwn then wwns[ #wwns + 1 ] = wwn end
	end
	return wwns
end

--- Is physical disk a hotspare
-- @return true/false
function M.Physical:is_hotspare()
	assert( self.id, "unable to get self object" )
	return M.Physical.list()[ self.id ].state == "hotspare"
end

--- Try to get physical's enclosure
-- @return enclosure's number
function M.Physical:enclosure()
	assert( self.id, "unable to get self object" )
	local SES_PAGE = "0xa" -- Additional element status (SES-2)
	if self.state == "failed" then return nil end
	local wwns = self:wwn()

	for _,expander in pairs( M.Adapter:expanders() ) do
		local bay = nil
		for _,line in ipairs( common.system( table.concat( {
			"sg_ses",
			"--page",
			SES_PAGE,
			"/dev/sg" .. expander.id
		}, " " ) ).stdout ) do
			local bay_possible = line:match( "bay number: (%d+)$" )
			if bay_possible then bay = bay_possible end
			local addr = line:match( "%s+SAS address: (%w+)$" )
			if addr and common.is_in_array( addr, wwns ) then
				return expander.id .. ":" .. bay
			end
		end
	end
end

--- Is physical disk has WriteCache enabled
-- @return true/false
function M.Physical:is_writecache()
	assert( self.id, "unable to get self object" )
	local result = common.system( "sdparm --quiet --get WCE " .. self.fdevnode )
	if result.stdout[1] then
		result = common.split_by( result.stdout[1], " " )
		if #result > 1 then
			return result[ 2 ] == "1"
		end
	end
	return false
end

--- Physical disk WriteCache enable
function M.Physical:writecache_enable()
	assert( self.id, "unable to get self object" )
	common.system( "sdparm --set WCE=1 " .. self.fdevnode )
end

--- Physical disk WriteCache disable
function M.Physical:writecache_disable()
	assert( self.id, "unable to get self object" )
	common.system( "sdparm --set WCE=0 " .. self.fdevnode )
end

--- Physical disk powersaving disable
function M.Physical:powersaving_disable()
	assert( self.id, "unable to get self object" )
	-- All commands below may fail, but there is no need to check it
	-- ATA/SATA: Try setting maximum performance mode of power management
	for _,cmd in ipairs({
		"hdparm -B 254", -- ATA/SATA: Lower power management threshold
		"hdparm -B 255", -- ATA/SATA: Try power management turning off at all
		"hdparm -S 0" -- ATA/SATA: Try setting suspend time to zero (disable)
	}) do
		common.system( cmd .. " " .. self.fdevnode )
	end
	for _,v in ipairs({
		"PM_BG", -- SAS: Turn off powermanagement
		"IDLE", -- SAS: Turn off idle timer
		"STANDBY" -- SAS: Turn off standby timer
	}) do
		common.system( "sdparm --set " .. v .. "=0 " .. self.fdevnode )
	end
end

-----------------------------------------------------------------------
-- Physicals sorting
-----------------------------------------------------------------------

--- Split physical ID
-- @param physical_id "2:3"
-- @return two number args 2, 3
function M.Physical.split_id( physical_id )
	assert( M.Physical.is_id( physical_id ),
	        "incorrect physical id" )
	return tonumber( string.match( physical_id , "^(%d+):" ) ),
	       tonumber( string.match( physical_id , ":(%d+)$" ) )
end

--- Sorting physical IDs
-- @param id1 Number to compare with
-- @param id2 Number to compare with
-- @return sort physicals ids
function M.sort_physical_ids( id1, id2 )
	local left1, right1 = M.Physical.split_id( id1 )
	local left2, right2 = M.Physical.split_id( id2 )
	if left1 == left2 then
		return right1 < right2
	else
		return left1 < left2
	end
end

--- Sorted physical list
-- @param physicals { "0:1" = Physical }
-- @return { Physical, Physical }
function M.Physical.sort( physicals )
	assert( common.is_table( physicals ),
	        "no physicals specified" )
	-- Validate that all keys are real physical IDs
	for physical_id,_ in pairs( physicals ) do
		assert( M.Physical.is_id( physical_id ),
		        "incorrect physical id" )
	end

	local state_list = common.unique_keys( "state", physicals )
	local states = common.keys( state_list )
	table.sort( states )
	local sorted_ids = {}
	local sorted_physicals = {}
	for _, state in ipairs( states ) do
		local ids = state_list[ state ]
		table.sort( ids, M.sort_physical_ids )
		for _, id in ipairs( ids ) do
			sorted_ids[ #sorted_ids + 1 ] = id
		end
	end
	for _, id in ipairs( sorted_ids ) do
		sorted_physicals[ #sorted_physicals + 1 ] = physicals[ id ]
	end
	return sorted_physicals
end

return M
