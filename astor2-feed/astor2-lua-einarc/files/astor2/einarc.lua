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
local logger = common.logger

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

M.logical = {}

M.logical.list = function()
	-- #  RAID level  Physical drives  Capacity  Device   State
	-- 0  linear      0:1              246.00 MB /dev/md0 normal
	logger:debug( "einarc:logical.list() called" )
	local output = run( "logical list" )
	if not output or #output == 0 then
		logger:warn( "einarc:logical.list() no logical disks" )
		return {}
	end
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
		logger:info( "einarc:logical.list() ID " ..
		             string.format( "%d [ %s, %s, %f, %q, %s ]", tostring( id ),
		                            logicals[ id ].level,
		                            table.concat( logicals[ id ].drives, "," ),
		                            logicals[ id ].capacity,
		                            logicals[ id ].device,
		                            logicals[ id ].state ) )
	end
	return logicals
end

M.logical.add = function( raid_level, drives, size, properties )
	assert( raid_level, "raid_level argument is required" )
	logger:debug( "einarc:logical.add() called" )
	local cmd = "logical add " .. raid_level
	if drives then
		cmd = cmd .. " " .. table.concat( drives, "," )
	end
	if size then
		cmd = cmd .. " " .. tostring( size )
	end
	if properties then
		local serialized = {}
		for _, pair in ipairs( properties ) do
			serialized[ #serialized + 1 ] = pair[1] .. "=" .. pair[2]
		end
		cmd = cmd .. " " .. table.concat( properties, "," )
	end
	local output = run( cmd )
	if output == nil then
		error("einarc:logical.add() failed")
	end
end

M.logical.delete = function( logical_id )
	assert( logical_id )
	local output = run( "logical delete " .. tostring( logical_id ) )
	if output == nil then
		error("einarc:logical.delete() failed")
	end
end

M.physical = {}

M.physical.list = function()
	-- ID   Model       Revision  Serial        Size     State
	-- 1:0  ST980310AS            5ST05LK2  76319.09 MB  free
	logger:debug( "einarc:physical.list() called" )
	local output = run( "physical list" )
	if not output or #output == 0 then
		logger:warn( "einarc:physical.list() no physical disks" )
		return {}
	end
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
		logger:info( "einarc:physical.list() ID " ..
		             string.format( "%s [ %q, %q, %q, %f, %s ]", id,
		                            physicals[ id ].model,
		                            physicals[ id ].revision,
		                            physicals[ id ].serial,
		                            physicals[ id ].size,
		                            physicals[ id ].state ) )
	end
	return physicals
end

M.bbu = {}

M.bbu.info = function()
	local output = run( "bbu info" )
end

return M
