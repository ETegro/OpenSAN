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

------------------------------------------------------------------------
-- AccessPattern
------------------------------------------------------------------------
M.AccessPattern = {}
local AccessPattern_mt = common.Class( M.AccessPattern )

M.AccessPattern.ALLOWED_TARGETDRIVERS = { "iscsi" }
M.AccessPattern.UCI_TYPE_NAME = "astor2-access-pattern"

function M.AccessPattern:new( attrs )
	assert( attrs.name )
	assert( common.is_in_array( attrs.targetdriver,
				    M.AccessPattern.ALLOWED_TARGETDRIVERS ) )
	assert( common.is_number( attrs.lun ) )
	if attrs.enabled == "1" or attrs.enabled == true then
		attrs.enabled = true
	else
		attrs.enabled = false
	end
	if attrs.readonly == "1" or attrs.readonly == true then
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
	                M.AccessPattern.UCI_TYPE_NAME,
	                function( section )
	                	access_patterns[ #access_patterns + 1 ] = M.AccessPattern:new( {
	                		section_name = section[ ".name" ],
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

function M.AccessPattern:save()
	assert( self )
	local ucicur = uci.cursor()
	if self.section_name then
		ucicur:delete( M.UCI_CONFIG_NAME,
		               self.section_name )
	end
	self.section_name = ucicur:add( M.UCI_CONFIG_NAME,
					M.AccessPattern.UCI_TYPE_NAME )
	ucicur:set( M.UCI_CONFIG_NAME,
		    self.section_name,
		    "name",
		    self.name )
	ucicur:set( M.UCI_CONFIG_NAME,
		    self.section_name,
		    "targetdriver",
		    self.targetdriver )
	ucicur:set( M.UCI_CONFIG_NAME,
		    self.section_name,
		    "lun",
		    tostring( self.lun ) )
	ucicur:set( M.UCI_CONFIG_NAME,
		    self.section_name,
		    "filename",
		    self.filename or "" )
	if self.enabled == true then
		ucicur:set( M.UCI_CONFIG_NAME,
			    self.section_name,
			    "enabled",
			    "1" )
	end
	if self.readonly == true then
		ucicur:set( M.UCI_CONFIG_NAME,
			    self.section_name,
			    "readonly",
			    "1" )
	end
	ucicur:save( M.UCI_CONFIG_NAME )
	ucicur:commit( M.UCI_CONFIG_NAME )
	return self
end

function M.AccessPattern:bind( filename )
	assert( self )
	assert( filename )
	self.filename = filename
	self:save()
end

function M.AccessPattern:unbind()
	assert( self )
	self.filename = ""
	self:save()
end

function M.AccessPattern:is_binded()
	assert( self )
	if self.filename then
		return true
	else
		return false
	end
end

------------------------------------------------------------------------
-- Configuration
------------------------------------------------------------------------
M.Configuration = {}
local Configuration_mt = common.Class( M.Configuration )

M.Configuration.SCSTADMIN_CONFIG_PATH = "/var/etc/scstadmin.conf"

function M.Configuration.dump()
	-- Collect only enabled and binded patterns
	local access_patterns_enabled = {}
	for _, access_pattern in ipairs( M.AccessPattern.list() ) do
		if access_pattern.enabled and access_pattern:is_binded() then
			access_patterns_enabled[ #access_patterns_enabled + 1 ] = access_pattern
		end
	end

	if #access_patterns_enabled == 0 then return "" end

	local configuration = ""

	-- Create HANDLERs
	local blockios = {}
	local blockio_counter = 1
	configuration = configuration .. "HANDLER vdisk_blockio {\n"
	for _, access_pattern in ipairs( access_patterns_enabled  ) do
		blockios[ access_pattern.filename ] = blockio_counter
		configuration = configuration .. "\tDEVICE blockio" .. blockio_counter .. " {\n"
		configuration = configuration .. "\t\tfilename " .. access_pattern.filename .. "\n"
		configuration = configuration .. "\t}\n"
		blockio_counter = blockio_counter + 1
	end
	configuration = configuration .. "}\n"

	-- Create TARGET_DRIVERs
	local access_patterns_target_drivers = common.unique_keys( "targetdriver", access_patterns_enabled )
	for target_driver, access_patterns_indexes in pairs( access_patterns_target_drivers ) do
		if target_driver == "iscsi" then
			configuration = configuration .. "TARGET_DRIVER iscsi {\n"
			configuration = configuration .. "\tTARGET iqn.2006-10.net.vlnb:tgt {\n" -- TODO
			for _, access_patterns_index in ipairs( access_patterns_indexes ) do
				access_pattern = access_patterns_enabled[ access_patterns_index ]
				local read_only = nil
				if access_pattern.readonly then
					read_only = "1"
				else
					read_only = "0"
				end
				configuration = configuration ..
				                "\t\tLUN " ..
				                tostring( access_pattern.lun ) ..
						" blockio" ..
						tostring( blockios[ access_pattern.filename ] ) ..
						" {\n" ..
						"\t\t\tread_only " .. read_only .. "\n" ..
						"\t\t}\n"
			end
			configuration = configuration .. "\t}\n" -- TODO
			configuration = configuration .. "}\n"
		end
	end

	return configuration
end

function M.Configuration.write()
	local configuration = M.Configuration.dump()
	local configuration_fd = io.open( M.Configuration.SCSTADMIN_CONFIG_PATH, "w" )
	configuration_fd:write( configuration )
	configuration_fd:close()
end

return M
