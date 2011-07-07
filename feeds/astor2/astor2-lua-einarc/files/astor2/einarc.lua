--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
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

local common = require( "astor2.common" )

local EINARC_CMD = "einarc -t software -a 0 "

M.LOGICAL_STATES = { "normal",
                     "degraded",
                     "initializing",
                     "rebuilding" }
M.PHYSICAL_STATES = { "hotspare",
                      "failed",
                      "free" }
M.RAIDLEVELS = { "linear",
                 "passthrough",
                 "0", "1", "4",
                 "5", "6", "10" }
M.RAIDLEVELS_HOTSPARE_NONCOMPATIBLE = { "linear",
                                        "passthrough",
					"0" }

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

------------------------------------------------------------------------
-- Adapter
------------------------------------------------------------------------
M.Adapter = {}
local Adapter_mt = common.Class( M.Adapter )

--- einarc adapter get
-- @param property "raidlevels"
-- @return { "linear", "passthrough", "0", "1", "5", "6", "10" }
function M.Adapter:get( property )
	assert( property and common.is_string( property ),
	        "no property specified" )

	-- WARNING: This is performance related issue only for
	-- software einarc module.
	if property == "raidlevels" then
		return M.RAIDLEVELS
	end

	local output = run( "adapter get " .. property )
	if not output then error( "einarc:adapter.get() failed" ) end
	return output
end

------------------------------------------------------------------------
-- Logical
------------------------------------------------------------------------
M.Logical = {}
local Logical_mt = common.Class( M.Logical )

function M.Logical:new( attrs )
	assert( common.is_number( attrs.id ),
	        "non-number ID" )
	assert( common.is_string( attrs.level ),
	        "empty level" )
	assert( common.is_positive( attrs.capacity ),
	        "non-positive capacity" )
	assert( common.is_string( attrs.device ),
	        "empty device" )
	assert( common.is_string( attrs.state ),
	        "unknown state" )
	return setmetatable( attrs, Logical_mt )
end

--- einarc logical list
-- @return { 0 = Logical, 1 = Logical }
function M.Logical.list()
	-- #  RAID level  Physical drives  Capacity  Device   State
	-- 0  linear      0:1              246.00 MB /dev/md0 normal
	local output = run( "logical list" )
	if not output or #output == 0 then return {} end
	local logicals = {}
	for _, line in ipairs( output ) do
		local id = tonumber( string.match( line, "^(%d+)" ) )
		assert( id, "unable to retreive an ID" )
		logicals[ id ] = M.Logical:new( {
			id = id,
			level = string.match( line, "^%d+\t(.+)\t[%d:,]*\t.*\t.*\t.*$" ) or "",
			drives = common.split_by( string.match( line, "^%d+\t.+\t([%d:,]*)\t.*\t.*\t.*$" ), "," ) or {},
			capacity = tonumber( string.match( line, "^%d+\t.+\t[%d:,]*\t([%d\.]+)\t.*\t.*$" ) ) or 0,
			device = string.match( line, "^%d+\t.+\t[%d:,]*\t.*\t(.*)\t.*$" ) or "",
			state = string.match( line, "^%d+\t.+\t[%d:,]*\t.*\t.*\t(.*)$" ) or ""
		} )
	end
	return logicals
end

--- einarc logical add
-- @param raid_level "passthrough" | "linear" | "0" | "1" | "5" | "6" | "10"
-- @param drives { "0:1", "0:2", "254:1" }
-- @param size 666.0
-- @param properties { "prop1" = "itsvalue", "prop2" = "itsvalue" }
-- @return Raise error if it fails
function M.Logical.add( raid_level, drives, size, properties )
	assert( raid_level, "raid_level argument is required" )
	local cmd = "logical add " .. raid_level
	if drives then
		assert( common.is_array( drives ), "drives have to be an array" )
		cmd = cmd .. " " .. table.concat( drives, "," )
	end
	if size then
		assert( common.is_positive( size ), "size has to be a positive number" )
		cmd = cmd .. " " .. tostring( size )
	end
	if properties then
		assert( common.is_array( properties ), "properties have to be a table" )
		local serialized = {}
		for k, v in pairs( properties ) do
			serialized[ #serialized + 1 ] = k .. "=" .. v
		end
		cmd = cmd .. " " .. table.concat( properties, "," )
	end
	local output = run( cmd )
	if output == nil then
		error("einarc:logical.add() failed")
	end
end

--- einarc logical delete
-- @result Raise error if it fails
function M.Logical:delete()
	assert( self.id, "unable to get self object" )
	local output = run( "logical delete " .. tostring( self.id ) )
	if output == nil then
		error("einarc:logical.delete() failed")
	end
end

--- einarc logical hotspare_add
-- @param physical_id "0:1"
-- @return Raise error if it fails
function M.Logical:hotspare_add( physical_id )
	assert( self.id, "unable to get self object" )
	assert( physical_id and common.is_string( physical_id ) )
	output = run( "logical hotspare_add " .. tostring( self.id ) .. " " .. physical_id )
	if not output then error( "einarc:logical.hotspare_add() failed" ) end
end

--- einarc logical hotspare_delete
-- @param physical_id "0:1"
-- @return Raise error if it fails
function M.Logical:hotspare_delete( physical_id )
	assert( self.id, "unable to get self object" )
	assert( physical_id and M.Physical.is_id( physical_id ),
	        "incorrect physical id" )
	output = run( "logical hotspare_delete " .. tostring( self.id ) .. " " .. physical_id )
	if not output then error( "einarc:logical.hotspare_delete() failed" ) end
end

--- einarc logical physical_list
-- @return self.physicals = { "physical1_id" = "state", "physical2_id" = "state" }
function M.Logical:physical_list()
	if common.is_table( self.physicals ) then
		return self.physicals
	end
	assert( self.id, "unable to get self object" )
	-- 0:1	free
	-- 0:2	hotspare
	local output = run( "logical physical_list " .. tostring( self.id ) )
	if not output then error( "einarc:logical.physical_list() failed" ) end
	self.physicals = {}
	for _, line in ipairs( output ) do
		local physical_id = string.match( line, "^([%d:]+)" )
		assert( M.Physical.is_id( physical_id ),
		        "incorrect physical id" )
		self.physicals[ physical_id ] = string.match( line, "^[%d:]+\t(.*)$" ) or ""
	end
	return self.physicals
end

--- Retreive logical progress, if it exists
-- @return self.progress = 66.6
function M.Logical:progress_get()
	if common.is_number( self.progress ) then
		return self.progress
	end
	assert( self.id, "unable to get self object" )
	for task_id, task in pairs( einarc.Task.list() ) do
		if task.where == tostring( self.id ) then
			self.progress = task.progress
			return self.progress
		end
	end
	return self.progress
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
	assert( common.is_positive( attrs.size ),
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
	-- ID   Model       Revision  Serial        Size     State
	-- 1:0  ST980310AS            5ST05LK2  76319.09 MB  free
	local output = run( "physical list" )
	if not output or #output == 0 then return {} end
	local physicals = {}
	for _, line in ipairs( output ) do
		local id = string.match( line, "^([%d:]+)" )
		assert( id, "unable to retreive an ID" )
		physicals[ id ] = M.Physical:new( {
			id = id,
			model = string.match( line, "^[%d:]+\t(.*)\t.*\t.*\t.*\t.*$" ) or "",
			revision = string.match( line, "^[%d:]+\t.*\t(.*)\t.*\t.*\t.*$" ) or "",
			serial = string.match( line, "^[%d:]+\t.*\t.*\t(.*)\t.*\t.*$" ) or "",
			size = tonumber( string.match( line, "^[%d:]+\t.*\t.*\t.*\t([%d\.]+)\t.*$" ) ) or 0,
			state = string.match( line, "^[%d:]+\t.*\t.*\t.*\t.*\t(.*)$" ) or ""
		} )
	end
	return physicals
end

--- einarc physical get
-- @param property "hotspare"
-- @return { "0" }
function M.Physical:get( property )
	assert( self.id and M.Physical.is_id( self.id ),
	        "unable to get self object" )
	assert( property and common.is_string( property ),
	        "empty property" )
	local output = run( "physical get " .. self.id .. " " .. property )
	if not output then error( "einarc:physical.get() failed" ) end
	return output
end

--- Is physical disk a hotspare
-- @return true/false
function M.Physical:is_hotspare()
	assert( self.id, "unable to get self object" )
	local output = self:get( "hotspare" )
	if not output then error( "einarc:physical.get.is_hotspare() failed" ) end
	return output[1] == "1"
end

------------------------------------------------------------------------
-- Task
------------------------------------------------------------------------
M.Task = {}
local Task_mt = common.Class( M.Task )

function M.Task:new( attrs )
	assert( common.is_number( attrs.id ),
	        "incorrect task id" )
	assert( common.is_string( attrs.what ),
	        "unexistent what" )
	assert( common.is_string( attrs.where ),
	        "unexistent where" )
	assert( common.is_number( attrs.progress ),
	        "no progress" )
	return setmetatable( attrs, Task_mt )
end

--- einarc task list
-- @return { 0 = Task, 1 = Task }
function M.Task.list()
	local output = run( "task list" )
	if not output or #output == 0 then
		return {}
	end
	local tasks = {}
	for _, line in ipairs( output ) do
		local id = string.match( line, "^(%d+)" )
		assert( id, "unable to retreive an ID" )
		tasks[ id ] = M.Task:new( {
			id = tonumber( id ),
			where = string.match( line, "^%d+\t(.*)\t.*\t.*$" ) or "",
			what = string.match( line, "^%d+\t.*\t(.*)\t.*$" ) or "",
			progress = tonumber( string.match( line, "^%d+\t.*\t.*\t(.*)$" ) ) or 0,
		} )
	end
	return tasks
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
