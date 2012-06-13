--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2012 ETegro Technologies, PLC
                          Sergey Matveev <stargrave@stargrave.org>
  
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

require( "uci" )
require( "lfs" )
local common = require( "astor2.common" )

M.UCI_CONFIG_NAME = "scst"

------------------------------------------------------------------------
-- AuthCredential
------------------------------------------------------------------------
M.AuthCredential = {}
local AuthCredential_mt = common.Class( M.AuthCredential )

M.AuthCredential.UCI_TYPE_NAME = "astor2-auth-credential"
M.AuthCredential.PASSWORD_LENGTH = 12

function M.AuthCredential.username_is_valid( username )
	if string.match( username, "^[a-zA-Z0-9_.-]+$" ) then
		return true
	end
end

function M.AuthCredential:new( attrs )
	assert( common.is_string( attrs.username ),
	        "empty username" )
	assert( M.AuthCredential.username_is_valid( attrs.username ),
	        "invalid username" )
	assert( common.is_string( attrs.password ),
	        "empty password" )
	assert( #attrs.password >= M.AuthCredential.PASSWORD_LENGTH,
	        "incorrect password length" )
	assert( common.is_string( attrs.filename ),
	        "empty filename" )
	return setmetatable( attrs, AuthCredential_mt )
end

function M.AuthCredential.list()
	local ucicur = uci.cursor()
	local auth_credentials = {}
	ucicur:foreach(
		M.UCI_CONFIG_NAME,
		M.AuthCredential.UCI_TYPE_NAME,
		function( section )
			auth_credentials[ #auth_credentials + 1 ] = M.AuthCredential:new( {
				section_name = section[ ".name" ],
				username = section.username,
				password = section.password,
				filename = section.filename
			} )
		end
	)
	return auth_credentials
end

function M.AuthCredential.list_for( filename )
	local auth_credentials = {}
	for _, auth_credential in ipairs( M.AuthCredential.list() ) do
		if auth_credential.filename == filename then
			auth_credentials[ #auth_credentials + 1 ] = auth_credential
		end
	end
	return auth_credentials
end

function M.AuthCredential.delete_by_username_and_filename( username, filename )
	local ucicur = uci.cursor()
	ucicur:foreach(
		M.UCI_CONFIG_NAME,
		M.AuthCredential.UCI_TYPE_NAME,
		function( section )
			if section.username == username and section.filename == filename then
				ucicur:delete(
					M.UCI_CONFIG_NAME,
					section[".name"]
				)
			end
		end
	)
	ucicur:save( M.UCI_CONFIG_NAME )
	ucicur:commit( M.UCI_CONFIG_NAME )
end

function M.AuthCredential.find_by( attribute, value )
	for _, auth_credential in ipairs( M.AuthCredential.list() ) do
		if auth_credential[ attribute ] == value then
			return auth_credential
		end
	end
	return nil
end

function M.AuthCredential.find_by_section_name( section_name )
	return M.AuthCredential.find_by( "section_name", section_name )
end

function M.AuthCredential:save()
	assert( self, "unable to get self object" )
	if self.section_name then
		M.AccessPattern.delete_by_username_and_filename( self.username, self.filename )
	end
	local auth_credential_new = M.AuthCredential:new( {
		username = self.username,
		password = self.password,
		filename = self.filename,
	} )

	local ucicur = uci.cursor()
	local section_name = ucicur:add(
		M.UCI_CONFIG_NAME,
		M.AuthCredential.UCI_TYPE_NAME
	)
	auth_credential_new.section_name = section_name
	ucicur:set(
		M.UCI_CONFIG_NAME,
		section_name,
		"username",
		auth_credential_new.username
	)
	ucicur:set(
		M.UCI_CONFIG_NAME,
		section_name,
		"password",
		auth_credential_new.password
	)
	ucicur:set(
		M.UCI_CONFIG_NAME,
		section_name,
		"filename",
		auth_credential_new.filename
	)
	ucicur:save( M.UCI_CONFIG_NAME )
	ucicur:commit( M.UCI_CONFIG_NAME )
	return access_pattern_new
end

function M.AuthCredential:delete()
	assert( self, "unable to get self object" )
	M.AuthCredential.delete_by_username_and_filename( self.username, self.filename )
end

------------------------------------------------------------------------
-- Session
------------------------------------------------------------------------
M.Session = {}
local Session_mt = common.Class( M.Session )

M.Session.SYSFS_TARGETS_PATH = "/sys/kernel/scst_tgt/targets/"
M.Session.ATTRIBUTES_REQUIRED = {
	"initiator_name",
	"sid"
}

function M.Session:new( attrs )
	assert( attrs.name,
	        "empty name" )
	assert( attrs.initiator_name,
	        "empty initiator_name" )
	assert( attrs.sid,
	        "empty sid" )
	assert( attrs.targetdriver,
	        "empty targetdriver" )
	assert( attrs.target_iqn,
	        "empty target_iqn" )
	return setmetatable( attrs, Session_mt )
end

function M.Session:detach()
	assert( self, "unable to get self object" )
	common.system(
		M.Daemon.SCSTADMIN_PATH ..
		" -force" ..
		" -noprompt" ..
		" -rem_target " .. self.target_iqn ..
		" -driver " .. self.targetdriver
	)
end

function M.Session.list()
	local sessions = {}
	for _, access_pattern in ipairs( M.AccessPattern.list() ) do
		sessions[ access_pattern.section_name ] = access_pattern:sessions()
	end
	return sessions
end

------------------------------------------------------------------------
-- AccessPattern
------------------------------------------------------------------------
M.AccessPattern = {}
local AccessPattern_mt = common.Class( M.AccessPattern )

M.AccessPattern.ALLOWED_TARGETDRIVERS = { "iscsi" }
M.AccessPattern.UCI_TYPE_NAME = "astor2-access-pattern"
M.AccessPattern.LUN_MAX = 16

function M.AccessPattern:new( attrs )
	assert( attrs.name,
	        "empty name" )
	assert( common.is_in_array( attrs.targetdriver,
	        M.AccessPattern.ALLOWED_TARGETDRIVERS ),
	        "unallowed targetdriver" )
	assert( common.is_number( attrs.lun ),
	        "no LUN" )
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
	if attrs.writethrough == "1" or attrs.writethrough == true then
		attrs.writethrough = true
	else
		attrs.writethrough = false
	end
	return setmetatable( attrs, AccessPattern_mt )
end

function M.AccessPattern.list()
	local ucicur = uci.cursor()
	local access_patterns = {}
	ucicur:foreach(
		M.UCI_CONFIG_NAME,
		M.AccessPattern.UCI_TYPE_NAME,
		function( section )
			access_patterns[ #access_patterns + 1 ] = M.AccessPattern:new( {
				section_name = section[ ".name" ],
				name = section.name,
				targetdriver = section.targetdriver,
				lun = tonumber( section.lun ),
				filename = section.filename,
				enabled = section.enabled,
				readonly = section.readonly,
				writethrough = section.writethrough
			} )
		end
	)
	return access_patterns
end

function M.AccessPattern.find_by( attribute, value )
	for _, access_pattern in ipairs( M.AccessPattern.list() ) do
		if access_pattern[ attribute ] == value then
			return access_pattern
		end
	end
	return nil
end

function M.AccessPattern.find_by_section_name( section_name )
	return M.AccessPattern.find_by( "section_name", section_name )
end

function M.AccessPattern.find_by_name( name )
	return M.AccessPattern.find_by( "name", name )
end

function M.AccessPattern.delete_by_name( name )
	local ucicur = uci.cursor()
	ucicur:foreach(
		M.UCI_CONFIG_NAME,
		M.AccessPattern.UCI_TYPE_NAME,
		function( section )
			if section.name == name then
				ucicur:delete(
					M.UCI_CONFIG_NAME,
					section[".name"]
				)
			end
		end
	)
	ucicur:save( M.UCI_CONFIG_NAME )
	ucicur:commit( M.UCI_CONFIG_NAME )
end

function M.AccessPattern:save()
	assert( self, "unable to get self object" )
	if self.section_name then
		M.AccessPattern.delete_by_name( self.name )
	end
	local access_pattern_new = M.AccessPattern:new( {
		name = self.name,
		targetdriver = self.targetdriver,
		lun = self.lun,
		filename = self.filename,
		enabled = self.enabled,
		readonly = self.readonly,
		writethrough = self.writethrough
	} )

	local ucicur = uci.cursor()
	local section_name = ucicur:add(
		M.UCI_CONFIG_NAME,
		M.AccessPattern.UCI_TYPE_NAME
	)
	access_pattern_new.section_name = section_name
	ucicur:set(
		M.UCI_CONFIG_NAME,
		section_name,
		"name",
		access_pattern_new.name
	)
	ucicur:set(
		M.UCI_CONFIG_NAME,
		section_name,
		"targetdriver",
		access_pattern_new.targetdriver
	)
	ucicur:set(
		M.UCI_CONFIG_NAME,
		section_name,
		"lun",
		tostring( access_pattern_new.lun )
	)
	ucicur:set(
		M.UCI_CONFIG_NAME,
		section_name,
		"filename",
		access_pattern_new.filename or ""
	)
	if access_pattern_new.enabled == true then
		ucicur:set(
			M.UCI_CONFIG_NAME,
			section_name,
			"enabled",
			"1"
		)
	end
	if access_pattern_new.readonly == true then
		ucicur:set(
			M.UCI_CONFIG_NAME,
			section_name,
			"readonly",
			"1"
		)
	end
	if access_pattern_new.writethrough == true then
		ucicur:set(
			M.UCI_CONFIG_NAME,
			section_name,
			"writethrough",
			"1"
		)
	end
	ucicur:save( M.UCI_CONFIG_NAME )
	ucicur:commit( M.UCI_CONFIG_NAME )
	return access_pattern_new
end

function M.AccessPattern:delete()
	assert( self, "unable to get self object" )
	M.AccessPattern.delete_by_name( self.name )
end

function M.AccessPattern:bind( filename )
	assert( self, "unable to get self object" )
	assert( filename )
	self.filename = filename
	self:save()
end

function M.AccessPattern:is_binded()
	assert( self, "unable to get self object" )
	if self.filename and common.file_exists( self.filename ) ~= false then
		return true
	else
		return false
	end
end

local function strip_unallowed_characters( iqn )
	return string.gsub( iqn, "[^-a-zA-Z0-9:.]", "." )
end

function M.AccessPattern:iqn()
	assert( self, "unable to get self object" )
	-- Retreive our hostname
	local ucicur = uci.cursor()
	local hostname = nil
	ucicur:foreach(
		"system",
		"system",
		function(s) hostname = s.hostname end )
	assert( hostname, "unable to retreive hostname" )

	-- Retreive LogicalVolume's name
	local volume_group_name, logical_volume_name = string.match( self.filename, "^/dev/(.+)/(.+)$" )
	assert( logical_volume_name, "unable to retreive logical volume name" )

	-- This may be useful later
	--[[
	-- Reverse domain name
	local hostname_parts = common.split_by( hostname, "." )
	local hostname_parts_reversed = {}
	for i=#hostname_parts,1,-1 do
		hostname_parts_reversed[ #hostname_parts - i + 1 ] = hostname_parts[ i ]
	end

	return "iqn." ..
	       os.date( "%Y-%m" ) ..
	       table.concat( hostname_parts_reversed, "." ) ..
	       ":" .. logical_volume_name
	]]
	return strip_unallowed_characters(
		"iqn.2011-03.org.opensan:" ..
		hostname .. ":" ..
		volume_group_name .. "." ..
		logical_volume_name
	)
end

function M.AccessPattern:sessions()
	assert( self, "unable to get self object" )
	if not self:is_binded() then return {} end
	local sessions = {}
	local targetdriver = self.targetdriver
	local target_iqn = self:iqn()
	local sysfs_path = M.Session.SYSFS_TARGETS_PATH ..
	                   targetdriver .. "/" ..
	                   target_iqn .. "/sessions"
	if not ( common.file_exists( sysfs_path ) == true ) then return {} end
	for dir_name in lfs.dir( sysfs_path ) do
		local session = {
			target_iqn = target_iqn,
			targetdriver = targetdriver
		}
		if dir_name:sub( 1, 4 ) == "iqn." then
			session.name = dir_name
			session.path = sysfs_path .. "/" .. session.name
			for attribute in lfs.dir( session.path ) do
				if common.is_in_array( attribute, M.Session.ATTRIBUTES_REQUIRED ) or
				   attribute:match( "^[A-Z]" ) then
					local attribute_path = session.path .. "/".. attribute
					--[[
					if lfs.attributes( attribute_path ).mode == "directory" then
						local ipv4 = string.match( attribute, "^%d+.%d+.%d+.%d+$" )
						if ipv4 then
							session[ "ipv4" ] = ipv4
						end
					end
					]]
					if ( lfs.attributes( attribute_path ).mode == "file" ) and
					   ( common.file_exists( attribute_path ) == true ) then
						session[ attribute ] = io.input( attribute_path ):read()
					end
				end
			end
			sessions[ session.name ] = M.Session:new( session )
		end
	end
	return sessions
end

function M.AccessPattern:unbind()
	assert( self, "unable to get self object" )
	for _, session in pairs( self:sessions() ) do
		session:detach()
	end
	self.filename = ""
	self:save()
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
	local devices = {}

	-- Create HANDLERs
	local fileios = {}
	local fileio_counter = 1
	configuration = configuration .. "HANDLER vdisk_fileio {\n"
	for _, access_pattern in ipairs( access_patterns_enabled  ) do
		fileios[ access_pattern.filename ] = fileio_counter
		local device = "fileio" .. fileio_counter
		configuration = configuration .. "\tDEVICE " .. device .. " {\n"
		configuration = configuration .. "\t\tfilename " .. access_pattern.filename .. "\n"
		if access_pattern.writethrough then
			configuration = configuration .. "\t\twrite_through 1\n"
		end
		configuration = configuration .. "\t}\n"
		fileio_counter = fileio_counter + 1
		devices[ #devices + 1 ] = device
	end
	configuration = configuration .. "}\n"

	-- Cycle through transports
	for target_driver,_ in pairs( common.unique_keys( "targetdriver", access_patterns_enabled ) ) do
		if target_driver == "iscsi" then
			configuration = configuration .. "TARGET_DRIVER iscsi {\n"
			-- Preprocess separate targets with corresponding LUNs
			local targets = {}
			for _, access_pattern in ipairs( access_patterns_enabled ) do
				if access_pattern.targetdriver == target_driver then
					local target = access_pattern:iqn()
					if not targets[ target ] then
						targets[ target ] = {}
					end
					targets[ target ][ tostring( access_pattern.lun ) ] = access_pattern
				end
			end
			for target, luns in pairs( targets ) do
				configuration = configuration .. "\tTARGET " ..
					target .. " {\n" ..
					"\t\tHeaderDigest None,CRC32C\n" ..
					"\t\tDataDigest None,CRC32C\n"
				-- Configure authentication credentials
				for _, auth_credential in ipairs( M.AuthCredential.list_for( luns["0"].filename ) ) do
					configuration = configuration ..
					                "\t\tIncomingUser \"" ..
					                auth_credential.username .. " " ..
					                auth_credential.password .. "\"\n"
				end
				for lun, access_pattern in pairs( luns ) do
					local read_only = nil
					if access_pattern.readonly then
						read_only = "1"
					else
						read_only = "0"
					end
					configuration = configuration ..
					                "\t\tLUN " .. lun ..
					                " fileio" ..
					                tostring( fileios[ access_pattern.filename ] ) ..
					                " {\n" ..
					                "\t\t\tread_only " .. read_only .. "\n" ..
					                "\t\t}\n"
				end
				configuration = configuration .. "\t\tenabled 1\n\t}\n"
			end
			configuration = configuration .. "\tenabled 1\n}\n"
		end
	end
	return configuration, devices
end

function M.Configuration.write( configuration, where )
	local configuration_fd = io.open( where, "w" )
	configuration_fd:write( configuration )
	configuration_fd:close()
end

------------------------------------------------------------------------
-- Daemon
------------------------------------------------------------------------
M.Daemon = {}
local Daemon_mt = common.Class( M.Daemon )

M.Daemon.SCSTADMIN_PATH = "/usr/sbin/scstadmin"
local LOG_PATH = "/var/log/scst.daemon.log"

local function log_append( str )
	local log_fd = io.open( LOG_PATH, "a" )
	log_fd:write( tostring( os.date() ) .. ": " .. str .. "\n" )
	log_fd:close()
end

function M.Daemon.check( configuration )
	local configuration_path = os.tmpname()
	M.Configuration.write(
		configuration,
		configuration_path
	)
	local result = common.system(
		M.Daemon.SCSTADMIN_PATH ..
		" -check_config " ..
		configuration_path
	)
	log_append(
		table.concat( result.stdout, "\n" ) ..
		table.concat( result.stderr, "\n" )
	)
	if result.return_code ~= 0 then
		os.remove( configuration_path )
		error( "scst:Daemon:check() failed: " .. table.concat( result.stdout, "\n" ) )
	end
	local succeeded = false
	for _, line in ipairs( result.stdout ) do
		if string.match( line, "0 warnings" ) then
			succeeded = true
		end
	end
	if not succeeded then
		os.remove( configuration_path )
		error( "scst:Daemon:check() failed: " .. table.concat( result.stdout, "\n" ) )
	end
	os.remove( configuration_path )
end

function M.Daemon.apply()
	local configuration, devices = M.Configuration.dump()
	if #configuration == 0 then return end
	M.Daemon.check( configuration )
	M.Configuration.write(
		configuration,
		M.Configuration.SCSTADMIN_CONFIG_PATH
	)
	local result = common.system_succeed(
		M.Daemon.SCSTADMIN_PATH ..
		" -force" ..
		" -noprompt" ..
		" -config " ..
		M.Configuration.SCSTADMIN_CONFIG_PATH
	)
	log_append( table.concat( result, "\n" ) )
	for _, device in ipairs( devices ) do
		common.system(
			M.Daemon.SCSTADMIN_PATH ..
			" -resync_dev " .. device
		)
	end
end


return M
