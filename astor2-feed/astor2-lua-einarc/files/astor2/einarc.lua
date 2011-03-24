--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
                          Sergey Matveev <stargrave@stargrave.org>
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
  
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
                 "0", "1", "5",
                 "6", "10" }

--- Execute einarc and get it's results
-- @param args "logical add 5 0 0:1,0:2"
-- @return Either an array of output strings from einarc, or nil if
--         einarc failed, or raise "NotImplementedError" if it is so
local function run( args )
	assert( args and common.is_string( args ) )
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

-- Taken from http://lua-users.org/wiki/SplitJoin
local function split_by_comma( str )
	assert( str and common.is_string( str ) )
	local words = {}
	local pattern = string.format( "([^%s]+)", "," )
	string.gsub( str,
	             pattern,
	             function( word ) words[ #words + 1 ] = word end )
        return words
end

M.adapter = {}

--- einarc adapter get
-- @param property "raidlevels"
-- @return { "linear", "passthrough", "0", "1", "5", "6", "10" }
M.adapter.get = function( property )
	assert( property and common.is_string( property ) )

	-- WARNING: This is performance related issue only for
	-- software einarc module.
	if property == "raidlevels" then
		return M.RAIDLEVELS
	end

	local output = run( "adapter get " .. property )
	if not output then error( "einarc:adapter.get() failed" ) end
	return output
end

M.logical = {}

--- einarc logical list
-- @return { 3 = { level = "1", drives = { "0:1", "0:2" }, capacity = 666.0, device = "/dev/md0", state = "normal" } }
M.logical.list = function()
	-- #  RAID level  Physical drives  Capacity  Device   State
	-- 0  linear      0:1              246.00 MB /dev/md0 normal
	local output = run( "logical list" )
	if not output or #output == 0 then return {} end
	local logicals = {}
	for _, line in ipairs( output ) do
		local id = tonumber( string.match( line, "^([0-9]+)" ) )
		assert( id )
		logicals[ id ] = {
			level = string.match( line, "^[0-9]+\t(.+)\t[0-9:,]+\t.*\t.*\t.*$" ) or "",
			drives = split_by_comma( string.match( line, "^[0-9]+\t.+\t([0-9:,]+)\t.*\t.*\t.*$" ) ) or {},
			capacity = tonumber( string.match( line, "^[0-9]+\t.+\t[0-9:,]+\t([0-9\.]+)\t.*\t.*$" ) ) or 0,
			device = string.match( line, "^[0-9]+\t.+\t[0-9:,]+\t.*\t(.*)\t.*$" ) or "",
			state = string.match( line, "^[0-9]+\t.+\t[0-9:,]+\t.*\t.*\t(.*)$" ) or ""
		}
	end
	return logicals
end

--- einarc logical add
-- @param raid_level "passthrough" | "linear" | "0" | "1" | "5" | "6" | "10"
-- @param drives { "0:1", "0:2", "254:1" }
-- @param size 666.0
-- @param properties { "prop1" = "itsvalue", "prop2" = "itsvalue" }
-- @return Raise error if it fails
M.logical.add = function( raid_level, drives, size, properties )
	assert( raid_level, "raid_level argument is required" )
	local cmd = "logical add " .. raid_level
	if drives then
		assert( common.is_array( drives ), "drives have to be an array" )
		cmd = cmd .. " " .. table.concat( drives, "," )
	end
	if size then
		assert( common.is_number( size ), "size has to be a number" )
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
-- @param logical_id 666
-- @result Raise error if it fails
M.logical.delete = function( logical_id )
	assert( logical_id and common.is_number( logical_id ) )
	local output = run( "logical delete " .. tostring( logical_id ) )
	if output == nil then
		error("einarc:logical.delete() failed")
	end
end

--- einarc logical hotspare_add
-- @param logical_id 0
-- @param physical_id "0:1"
-- @return Raise error if it fails
M.logical.hotspare_add = function( logical_id, physical_id )
	assert( logical_id and common.is_number( logical_id ) )
	assert( physical_id and common.is_string( physical_id ) )
	output = run( "logical hotspare_add " .. tostring( logical_id ) .. " " .. physical_id )
	if not output then error( "einarc:logical.hotspare_add() failed" ) end
end

--- einarc logical hotspare_delete
-- @param logical_id 777
-- @param physical_id "0:1"
-- @return Raise error if it fails
M.logical.hotspare_delete = function( logical_id, physical_id )
	assert( logical_id and common.is_number( logical_id ) )
	assert( physical_id and common.is_string( physical_id ) )
	output = run( "logical hotspare_delete " .. tostring( logical_id ) .. " " .. physical_id )
	if not output then error( "einarc:logical.hotspare_delete() failed" ) end
end

--- einarc logical physical_list
-- @param logical_id 0
-- @return { “physical1_id” = “state”, “physical2_id” = “state” }
M.logical.physical_list = function( logical_id )
	-- 0:1	free
	-- 0:2	hotspare
	assert( logical_id and common.is_number( logical_id ) )
	local output = run( "logical physical_list " .. tostring( logical_id ) )
	if not output then error( "einarc:logical.physical_list() failed" ) end
	local logical_physicals = {}
	for _, line in ipairs( output ) do
		local physical_id = string.match( line, "^([0-9:]+)" )
		assert( physical_id )
		logical_physicals[ physical_id ] = string.match( line, "^[0-9:]+\t(.*)$" ) or ""
	end
	return logical_physicals
end

M.physical = {}

--- einarc physical list
-- @return { "0:1" = { model = "some", revision = "rev", serial = "some", size = 666, state = "free" } }
M.physical.list = function()
	-- ID   Model       Revision  Serial        Size     State
	-- 1:0  ST980310AS            5ST05LK2  76319.09 MB  free
	local output = run( "physical list" )
	if not output or #output == 0 then return {} end
	local physicals = {}
	for _, line in ipairs( output ) do
		local id = string.match( line, "^([0-9:]+)" )
		assert( id )
		physicals[ id ] = {
			model = string.match( line, "^[0-9:]+\t(.*)\t.*\t.*\t.*\t.*$" ) or "",
			revision = string.match( line, "^[0-9:]+\t.*\t(.*)\t.*\t.*\t.*$" ) or "",
			serial = string.match( line, "^[0-9:]+\t.*\t.*\t(.*)\t.*\t.*$" ) or "",
			size = tonumber( string.match( line, "^[0-9:]+\t.*\t.*\t.*\t([0-9\.]+)\t.*$" ) ) or 0,
			state = string.match( line, "^[0-9:]+\t.*\t.*\t.*\t.*\t(.*)$" ) or ""
		}
	end
	return physicals
end

--- einarc physical get
-- @param physical_id "0:1"
-- @param property "hotspare"
-- @return { "0" }
M.physical.get = function( physical_id, property )
	assert( physical_id and common.is_string( physical_id ) )
	assert( property and common.is_string( physical_id ) )
	local output = run( "physical get " .. physical_id .. " " .. property )
	if not output then error( "einarc:physical.get() failed" ) end
	return output
end

--- Is physical disk a hotspare
-- @param physical_id "0:1"
-- @return true/false
M.physical.is_hotspare = function( physical_id )
        assert( physical_id )
	local output = M.physical.get( physical_id, "hotspare" )
	if not output then error( "einarc:physical.get.is_hotspare() failed" ) end
	return output[1] == "1"
end

M.task = {}

--- einarc task list
-- @return { 0 = { what = "something", where = "somewhere", progress = 66.6 } }
M.task.list = function()
	local output = run( "task list" )
	if not output or #output == 0 then
		return {}
	end
	local tasks = {}
	for _, line in ipairs( output ) do
		local id = string.match( line, "^([0-9]+)" )
		assert( id )
		tasks[ id ] = {
			where = string.match( line, "^[0-9]+\t(.*)\t.*\t.*$" ) or "",
			what = string.match( line, "^[0-9]+\t.*\t(.*)\t.*$" ) or "",
			progress = tonumber( string.match( line, "^[0-9]+\t.*\t.*\t(.*)$" ) ) or 0,
		}
	end
	return tasks
end

M.bbu = {}

M.bbu.info = function()
	local output = run( "bbu info" )
end

-----------------------------------------------------------------------
-- Sorting physicals
-----------------------------------------------------------------------

--- Split physical ID
-- @param physical_id "2:3"
-- @return two number args 2, 3
M.physical.split_id = function( physical_id )
	return tonumber( string.match( physical_id , "^([0-9]+):" ) ),
	       tonumber( string.match( physical_id , ":([0-9]+)$" ) )
end

--- Sorting physical IDs
-- @param two number from M.physical.split_id() 2, 3
-- @return sort physicals ids
M.physical.sort_ids = function( id1, id2 )
	local left1, right1 = M.physical.split_id( id1 )
	local left2, right2 = M.physical.split_id( id2 )
	if left1 == left2 then
		return right1 < right2
	else
		return left1 < left2
	end
end

--- Sorting physicals
-- @param { "0:1" = { model = "some", revision = "rev", serial = "some", size = 666, state = "free" } }
-- @return sorted physicals by ID
M.physical.sort_physicals = function( physical_list )
	local physical_ids = common.keys( physical_list )
	table.sort( physical_ids, M.physical.sort_ids )
	return physical_ids
end

--- Sorted physical list
-- @param { "0:1" = { model = "some", revision = "rev", serial = "some", size = 666, state = "free" }
-- @return { { id = "0:1", model = "some", revision = "rev", serial = "some", size = 666, state = "free" } }
M.physical.sorted_list = function( physical_list )
	local state_list = common.unique_keys( "state", physical_list )
	local states = common.keys( state_list )
	table.sort( states )
	local sorted_ids = {}
	local sorted_physical_list = {}
	for _, state in ipairs( states ) do
		local ids = state_list[ state ]
		table.sort( ids, M.physical.sort_ids )
		for _, id in ipairs( ids ) do
			sorted_ids[ #sorted_ids + 1 ] = id
		end
	end
	for _, id in ipairs( sorted_ids ) do
		physical_list[ id ].id = id
		sorted_physical_list[ #sorted_physical_list + 1 ] = physical_list[ id ]
	end
	return sorted_physical_list
end

return M
