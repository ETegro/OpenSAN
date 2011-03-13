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

require "logging.console"
M.logger = logging.console()

local SHELL_PATH = "/bin/sh"

function M.system( cmdline )
	assert( cmdline )
	M.logger:debug( "common:system() called with cmdline \"" .. cmdline .. "\"" )
	local stdout_path = os.tmpname()
	local stderr_path = os.tmpname()
	local script_path = os.tmpname()
	assert( stdout_path and stderr_path and script_path )

	-- Script to be executed itself
	local script_fd = io.open( script_path, "w" )
	script_fd:write( cmdline .. "\n" )
	script_fd:close()

	local result = {}

	-- Execute command and retreive return code
	M.logger:debug( "common:system() executing script " .. script_path )
	result.return_code = os.execute( SHELL_PATH .. " "
	                                 .. script_path
	                                 .. " >" .. stdout_path
	                                 .. " 2>" .. stderr_path )
	os.remove( script_path )

	-- Read it's stdout
	result.stdout = {}
	M.logger:debug( "common:system() parsing stdout " .. stdout_path )
	local stdout_fd = io.open( stdout_path, "r" )
	for line in stdout_fd:lines() do
		result.stdout[ #result.stdout + 1 ] = line
	end
	stdout_fd:close()
	os.remove( stdout_path )

	-- Read it's stderr
	result.stderr = {}
	M.logger:debug( "common:system() parsing stderr " .. stderr_path )
	local stderr_fd = io.open( stderr_path, "r" )
	for line in stderr_fd:lines() do
		result.stderr[ #result.stderr + 1 ] = line
	end
	stderr_fd:close()
	os.remove( stderr_path )

	return result
end

return M
