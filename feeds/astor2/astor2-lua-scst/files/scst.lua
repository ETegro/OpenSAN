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

require( "uci" )
local common = require( "astor2.common" )

M.UCI_CONFIG_NAME = "scst"
M.UCI_TYPE_NAME = "astor2-access-pattern"

M.AccessPattern = {}
local AccessPattern_mt = common.Class( M.AccessPattern )

M.AccessPattern.ALLOWED_TARGETDRIVERS = { "iscsi" }

function M.AccessPattern:new( attrs )
	assert( attrs.name )
	assert( attrs.name )
	assert( common.is_in_array( attrs.targetdriver,
				    M.AccessPattern.ALLOWED_TARGETDRIVERS ) )
	assert( common.is_number( attrs.lun ) )
	if attrs.enabled == "1" then
		attrs.enabled = true
	else
		attrs.enabled = false
	end
	if attrs.readonly == "1" then
		attrs.readonly = true
	else
		attrs.readonly = false
	end
	return setmetatable( attrs, AccessPattern_mt )
end

function M.AccessPattern.list()
	local ucicur = uci.cursor()
	local access_patterns = {}
	ucicur:foreach( M.UCI_CONFIG_NAME,
	                M.UCI_TYPE_NAME,
			function( section )
	                	access_patterns[ access_pattern.name ] = M.AccessPattern:new( {
	                		name = section.name,
	                		targetdriver = section.targetdriver,
	                		lun = tonumber( section.lun ),
	                		filename = section.filename,
	                		enabled = section.enabled,
	                		readonly = section.readonly
				} )
			end )
	return access_patterns
end

function M.AccessPattern.add( access_pattern )
	assert( access_pattern )
	local ucicur = uci.cursor()
	local section_name = ucicur:add( M.UCI_CONFIG_NAME, M.UCI_TYPE_NAME )
	ucicur:set( M.UCI_CONFIG_NAME, section_name, "name", access_pattern.name )
	ucicur:set( M.UCI_CONFIG_NAME, section_name, "targetdriver", access_pattern.targetdriver )
	ucicur:set( M.UCI_CONFIG_NAME, section_name, "lun", tostring( access_pattern.lun ) )
	ucicur:set( M.UCI_CONFIG_NAME, section_name, "filename", access_pattern.filename )
	if access_pattern.enabled == true then
		ucicur:set( M.UCI_CONFIG_NAME, section_name, "enabled", "true" )
	end
	if access_pattern.readonly == true then
		ucicur:set( M.UCI_CONFIG_NAME, section_name, "readonly", "true" )
	end
	ucicur:commit( M.UCI_CONFIG_NAME )
end

return M
