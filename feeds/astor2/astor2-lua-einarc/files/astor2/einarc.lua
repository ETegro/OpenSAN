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

M.LOGICAL_STATES = {
	"normal",
	"degraded",
	"initializing",
	"rebuilding"
}
M.LOGICAL_STATES_MAP = {
	["clean"] = "normal",
	["clear"] = "normal",
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
--- Try unexceptionally read single line from given file
-- @param path "/sys/block/sda/device/model"
-- @return Either single string or nil
local function read_line( path )
	if lfs.attributes( path ) then
		return io.input( path ):read()
	end
	return nil
end

--- List device's slaves
-- @param path "/sys/block/sda"
-- @return { "dm-0", "dm-1" }
local function list_slaves( path )
	local slaves = {}
	for slave in lfs.dir( path .. "/slaves" ) do
		if slave ~= "." and slave ~= ".." then
			slaves[ #slaves + 1 ] = slave
		end
	end
	return slaves
end

-- Workaround for buggy amd64 Lua build
local function tonumber_unbuggy( s )
	if s then
		local try1 = tonumber( s )
		local try2 = tonumber( s .. "0" ) * 0.1
		if try1 > try2 then
			s = try1
		else
			s = try2
		end
	else
		s = 0
	end
	return s
end

--- List available block devices to work with
-- @return Big hash of different variable data
local function list_devices()
	local path_block = "/sys/block/"
	local devices = {}
	for ent in lfs.dir( path_block ) do
		local device = {
			devnode = ent,
			fdevnode = "/dev/" .. ent,
			path = path_block .. ent
		}
		device.size = math.floor( tonumber_unbuggy( read_line( device.path .. "/size" ) ) / 2048 )
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
			if #device.slaves > 0 then
				devices[ device.devnode ] = device
			end
		elseif string.sub( ent, 1, 2 ) == "sd" then
			device.type = "sd"
			devices[ device.devnode ] = device
		end
	end
	return devices
end

--- Convert system's device ID to SCSI ID
-- @param id "sdb"
-- @return "0:2"
function M.phys_to_scsi( name )
	local root = string.match( name, "^dm.(%d+)$" )
	assert( root, "Invalid device name" )
	return "0:" .. tostring( tonumber( root ) + 1 )
end

--- Convert SCSI ID to system's device ID
-- @param id "0:2"
-- @return "sdb"
function M.scsi_to_phys( id )
	local pre, post = string.match( id, "^(%d+):(%d+)$" )
	assert( pre == "0", "Invalid internal ID" )
	return "dm-" .. tostring( tonumber( post ) - 1 )
end

--- Try to run mdadm with given arguments several times until success
-- @param args "..."
-- @return common.system()'s result
local function run( args )
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

--- List available SAS expanders
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

--- List available Logical disks
-- @return { 0 = Logical, 1 = Logical }
function M.Logical.list()
	local logicals = {}
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
				"raid_disks",
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
			if logical.degraded == "1" then
				logical.state = "degraded"
			end
			if ( logical.state == "normal" or logical.state == "degraded" ) and
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

--- Create new Logical disk
-- @param raid_level "passthrough" | "linear" | ... | "10"
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

--- Delete Logical disk
-- @result Raise error if it fails
function M.Logical:delete()
	assert( self.id, "unable to get self object" )
	local result = run("--stop " .. self.fdevnode)
	for _,id in pairs( self.drives ) do
		M.Physical.zero_superblock( { id = id } )
	end
	if result.return_code ~= 0 then
		error("einarc:logical.delete() failed")
	end
end

--- Add hotspare Physical to Logical
-- @param physical Physical
-- @return Raise error if it fails
function M.Logical:hotspare_add( physical )
	assert( self.id, "unable to get self object" )
	assert( physical and physical.id, "invalid Physical object" )
	physical:zero_superblock()
	local result = run( self.fdevnode .. " --add " .. physical.fdevnode )
	if result.return_code ~= 0 then
		error("einarc:logical.hotspare_add() failed")
	end
end

--- Remove hotspare Physical from Logical
-- @param physical Physical
-- @return Raise error if it fails
function M.Logical:hotspare_delete( physical )
	assert( self.id, "unable to get self object" )
	assert( physical and physical.id, "invalid Physical object" )
	local result = run( self.fdevnode .. " --remove " .. physical.fdevnode )
	if result.return_code ~= 0 then
		error("einarc:logical.hotspare_delete() failed")
	end
end

--- Growing Logical disk
-- @param drives { "0:1", "0:2", "254:1" }
-- @return Raise error if it fails
function M.Logical:grow( drives )
	assert( self.id, "unable to get self object" )
	assert( common.is_array( drives ), "drives have to be an array" )
	for _,physical_id in ipairs( drives ) do
		assert( common.is_in_array( physical_id, common.keys( self.physicals ) ), "disk doesn't belong to logical" )
		assert( self.physicals[ physical_id ] == "hotspare" )
	end
	local physicals = M.Physical.list()
	local hotspare_restore = {}
	for physical_id, physical_state in pairs( self.physicals ) do
		if ( physical_state == "hotspare" and
		     not common.is_in_array( physical_id, drives ) ) then
			self:hotspare_delete( physicals[ physical_id ] )
			hotspare_restore[ #hotspare_restore + 1 ] = physicals[ physical_id ]
		end
	end
	run(
		self.fdevnode ..
		" --grow" ..
		" --raid-devices=" .. tostring( #common.keys( self.physicals ) - #hotspare_restore )
	)
	for _,physical in ipairs( hotspare_restore ) do
		self:hotspare_add( physical )
	end
end

--- List Logical-related Physicals with the states
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
	for i=#self.slaves+1,( tonumber( self.raid_disks ) or #self.slaves ) do
		self.physicals[ "99:" .. i ] = "failed"
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
		local done, total = string.match( sync, "^(%d+) / (%d+)$" )
		done = tonumber_unbuggy( done )
		total = tonumber_unbuggy( total )
		if done >= 0 and total > 0 then
			self.progress = math.floor( 1000 * done / total ) * 0.1
		end
	end
	return self.progress
end

--- Disable powersaving on logical disk
function M.Logical:powersaving_disable()
	assert( self.id, "unable to get self object" )
	local physicals = M.Physical.list()
	local nodes = {}
	for _,drive in ipairs( self.drives ) do
		nodes[ #nodes + 1 ] = physicals[ drive ].frawnode
	end

	-- All commands below may fail, but there is no need to check it
	-- ATA/SATA: Try setting maximum performance mode of power management
	for _,cmd in ipairs({
		"hdparm -B 254", -- ATA/SATA: Lower power management threshold
		"hdparm -B 255", -- ATA/SATA: Try power management turning off at all
		"hdparm -S 0" -- ATA/SATA: Try setting suspend time to zero (disable)
	}) do
		common.system( cmd .. " " .. table.concat( nodes, " " ) )
	end
	for _,v in ipairs({
		"PM_BG", -- SAS: Turn off powermanagement
		"IDLE", -- SAS: Turn off idle timer
		"STANDBY" -- SAS: Turn off standby timer
	}) do
		common.system( "sdparm --set " .. v .. "=0 " .. table.concat( nodes, " " ) )
	end

end

--- Enable WriteCache on logical disk
function M.Logical:writecache_enable()
	assert( self.id, "unable to get self object" )
	local physicals = M.Physical.list()
	local nodes = {}
	for _,drive in ipairs( self.drives ) do
		nodes[ #nodes + 1 ] = physicals[ drive ].frawnode
	end
	common.system( "sdparm --set WCE=1 " .. table.concat( nodes, " " ) )
end

--- Disable WriteCache on logical disk
function M.Logical:writecache_disable()
	assert( self.id, "unable to get self object" )
	local physicals = M.Physical.list()
	local nodes = {}
	for _,drive in ipairs( self.drives ) do
		nodes[ #nodes + 1 ] = physicals[ drive ].frawnode
	end
	common.system( "sdparm --set WCE=0 " .. table.concat( nodes, " " ) )
end

--- Is logical disk has WriteCache enabled
-- @return true/false
function M.Logical:is_writecache()
	assert( self.id, "unable to get self object" )
	local physicals = M.Physical.list()
	local nodes = {}
	for _,drive in ipairs( self.drives ) do
		nodes[ #nodes + 1 ] = physicals[ drive ].frawnode
	end
	for _,line in ipairs( common.system( "sdparm --quiet --get WCE " .. table.concat( nodes, " " ) ).stdout ) do
		if common.split_by( line, " " )[ 2 ] == "1" then return true end
	end
	return false
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
	assert( common.is_non_negative( attrs.size ),
	        "non-positive size" )
	assert( common.is_string( attrs.state ),
	        "incorrect state" )

	-- Strip out whitespaces
	attrs.model = common.strip( attrs.model )
	attrs.revision = common.strip( attrs.revision )

	return setmetatable( attrs, Physical_mt )
end

--- List available Physical disks
-- @return { "0:1" = Physical, "0:2" = Physical }
function M.Physical.list()
	local physicals = {}
	local devices = list_devices()
	for _,device in pairs( devices ) do
		if device.type == "multipath" then
			local physical = common.deepcopy( device )
			physical.slave = devices[ physical.slaves[1] ]
			if physical.slave then
				physical.model = common.strip( read_line( physical.slave.path .. "/device/model" ) or "" )
				physical.revision = common.strip( read_line( physical.slave.path .. "/device/rev" ) or "" )
				physical.serial = "None"
				physical.frawnode = "/dev/" .. physical.slave.devnode
				physical.state = "free"
			else
				physical.model = "None"
				physical.revision = "None"
				physical.vendor = "None"
				physical.frawnode = "/dev/" .. physical.devnode
				physical.state = "failed"
			end
			physical.id = M.phys_to_scsi( physical.devnode )
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

--- Try to determine physical disk's serial, model and revision using S.M.A.R.T.
-- @return { model = "model", serial = "serial", revision = "revision" }
function M.Physical:extended_info()
	assert( self.id, "unable to get self object" )
	local info = {}
	for _,line in ipairs( common.system( "smartctl --info --attributes " .. self.frawnode ).stdout ) do
		-- SAS output
		-- Device: SASBRAND    MODEL      Version: 0001
		local model = line:match( "^[Dd]evice:%s*(.+)%s+[Vv]ersion:.*$" )
		if not model then
			-- ATA output
			-- Device Model:     ATA MODEL
			model = line:match( "^[Dd]evice [Mm]odel:%s*(.+)%s*$" )
		end
		if model then
			model = table.concat( common.split_by( model, "%s" ), " " )
			info.model = model
		end
		-- SAS output
		-- Device: SASBRAND    MODEL      Version: 0001
		local revision = line:match( "^[Dd]evice:%s*.+%s+[Vv]ersion:%s*(.+)%s*$" )
		if not revision then
			-- ATA output
			-- Firmware Version: 1.2b
			revision = line:match( "^[Ff]irmware [Vv]ersion:%s*(.+)%s*$" )
		end
		if revision then info.revision = revision end
		-- SAS/ATA output
		-- Serial Number:    000023VDU03
		local serial = line:match( "^[Ss]erial [Nn]umber:%s*(.+)%s*$" )
		if serial then info.serial = serial end

		-- SAS output
		-- Current Drive Temperature:     25 C
		local temperature = line:match( "^[Cc]urrent [Dd]rive [Tt]emperature:%s*(%d+).*$" )
		if not temperature then
			-- ATA output
			-- 194 Temperature_Celsius     0x0002   253   253   000    Old_age   Always       -       23 (Min/Max 19/41)
			if line:match( "^%s*194%s+[Tt]emperature_[Cc]elsius.*" ) then
				temperature = common.split_by( line, "%s" )[10]:match( "%d+" )
			end
		end
		if temperature then info.temperature = temperature end
	end
	for _,v in ipairs({ "serial", "model", "revision", "temperature" }) do
		info[ v ] = info[ v ] or self[ v ]
	end
	return info
end

--- Zero md-related superblock on Physical
function M.Physical:zero_superblock()
	assert( self.id and M.Physical.is_id( self.id ),
	        "unable to get self object" )
	run("--zero-superblock /dev/" .. M.scsi_to_phys( self.id ))
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
		sgmaps()[ self.frawnode ]
	) ) do
		if line:sub(1,11) == "SAS address" then
			wwns[ #wwns + 1 ] = line:match( "^SAS address%s+(%w+)$" )
		end
	end
	if #wwns > 0 then return wwns end

	-- Otherwise we are dealing with SATA
	-- They can contain also two WWNs: the real one and that is visible to system
	for _,line in ipairs( common.system( "sdparm --inquiry " .. self.frawnode ).stdout ) do
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

--- Try to get Physical's enclosure
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
