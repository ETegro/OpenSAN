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

local EINARC_CMD = "einarc -t software -a 0 "
local LOGICAL_STATES = { "normal",
                         "degraded",
                         "initializing",
                         "rebuilding" }
local PHYSICAL_STATES = { "hotspare",
                          "failed",
                          "free" }

--- Check if value is in array
-- @param what Value to be checked
-- @param array Array to search in
-- @return True if exists, false otherwise
local function is_in_array( what, array )
	local is_in_it = false
	for _, v in ipairs( array ) do
		if what == v then
			is_in_it = true
		end
	end
	return is_in_it
end

--- Execute einarc and get it's results
-- @param args "logical add 5 0 0:1,0:2"
-- @return Either an array of output strings from einarc, or nil if
--         einarc failed, or raise "NotImplementedError" if it is so
local function run( args )
	assert( args )
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
	local words = {}
	local pattern = string.format( "([^%s]+)", "," )
	string.gsub( str,
	             pattern,
	             function( word ) words[ #words + 1 ] = word end )
        return words
end

M.adapter = {}

--- einarc adapter get
-- @param property = "raidlevels"
-- @return { "linear", "passthrough", "0", "1", "5", "6", "10" }
M.adapter.get = function( property )
	assert( property )
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
		assert( is_in_array( logicals[ id ].state, LOGICAL_STATES ) == true )
	end
	return logicals
end

--- einarc logical add
-- @param raid_level "passthrough" | "linear" | "0" | "1" | "5" | "6" | "10"
-- @param drives { "0:1", "0:2", "254:1" }
-- @param size 666.0
-- @param properties { "prop1" = "itsvalue", "prop2" = "itsvalue" }
-- @return Raise error if it failed
M.logical.add = function( raid_level, drives, size, properties )
	assert( raid_level, "raid_level argument is required" )
	local cmd = "logical add " .. raid_level
	if drives then
		cmd = cmd .. " " .. table.concat( drives, "," )
	end
	if size then
		cmd = cmd .. " " .. tostring( size )
	end
	if properties then
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
-- @result Raise error if it failed
M.logical.delete = function( logical_id )
	assert( logical_id )
	local output = run( "logical delete " .. tostring( logical_id ) )
	if output == nil then
		error("einarc:logical.delete() failed")
	end
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
		assert( is_in_array( physicals[ id ].state, PHYSICAL_STATES ) == true )
	end
	return physicals
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

return M
