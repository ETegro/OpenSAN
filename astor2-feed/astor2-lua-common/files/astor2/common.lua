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

local SHELL_PATH = "/bin/sh"

--- Call external command
-- Lua's built-in methods are capable either only about getting
-- return code from some external program, or only about getting it's
-- stdout. This function can get all of them at once.
-- @param cmdline "mdadm --examine /dev/sda"
-- @return { return_code = 0, stderr = { "line1", "line2" }, stdout = { "line1", "line2" } }
function M.system( cmdline )
	assert( cmdline )
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
	result.return_code = os.execute( SHELL_PATH .. " "
	                                 .. script_path
	                                 .. " >" .. stdout_path
	                                 .. " 2>" .. stderr_path )
	os.remove( script_path )

	-- Read it's stdout
	result.stdout = {}
	local stdout_fd = io.open( stdout_path, "r" )
	for line in stdout_fd:lines() do
		result.stdout[ #result.stdout + 1 ] = line
	end
	stdout_fd:close()
	os.remove( stdout_path )

	-- Read it's stderr
	result.stderr = {}
	local stderr_fd = io.open( stderr_path, "r" )
	for line in stderr_fd:lines() do
		result.stderr[ #result.stderr + 1 ] = line
	end
	stderr_fd:close()
	os.remove( stderr_path )

	return result
end

function M.system_succeed( cmdline )
	local result = M.system( cmdline )
	if result.return_code ~= 0 then error( "system() does not succeed" ) end
	return result.stdout
end

--- Check if value is in array
-- @param what Value to be checked
-- @param array Array to search in
-- @return True if exists, false otherwise
function M.is_in_array( what, array )
	assert( M.is_table( array ) )
	local is_in_it = false
	for _, v in ipairs( array ) do
		if what == v then
			is_in_it = true
		end
	end
	return is_in_it
end

--- Check if object is a string
-- @param obj An object to check
-- @return true or false
function M.is_string( obj )
	return type( obj ) == type( "" )
end

--- Check if object is a table
-- @param obj An object to check
-- @return true or false
function M.is_table( obj )
	return type( obj ) == type( {} )
end

--- Check if object is not empty array
-- @param obj An object to check
-- @return true or false
function M.is_array( obj )
	return M.is_table( obj ) and #obj ~= 0
end

--- Check if object is a number
-- @param obj An object to check
-- @return true or false
function M.is_number( obj )
	return type( obj ) == type( 1 )
end

--- Check if number is odd
-- @param n Number to check
-- @return true or false
function M.is_odd( n )
	assert( M.is_number( n ) )
	return n % 2 == 0
end

--- Get keys from hash
-- @param hash { "key1" = { ... }, "key2" = { ... } }
-- @return { "key1", "key2" }
function M.keys( hash )
	local keys = {}
	for key,_ in pairs( hash ) do
		keys[ #keys + 1 ] = key
	end
	return keys
end
--
--- Get values from hash
-- @param hash { "key1" = { ...1 }, "key2" = { ...2 } }
-- @return { { ...1 }, { ...2 } }
function M.values( hash )
	local values = {}
	for _, value in pairs( hash ) do
		values[ #values + 1 ] = value
	end
	return values
end

--- Return unique-keyed hash
-- @param key "state"
-- @param hash { "0:1" = { state = "free", model = "some" }, "0:2" = { state = "failed", model = "some2" } }
-- @return { free = { "0:1" }, failed = { "0:2" } }
function M.unique_keys( key, hash )
	assert( key )
	assert( M.is_table( hash ) )
	local uniques = {}
	for obj_id, obj_data in pairs( hash ) do
		if not uniques[ obj_data[ key ] ] then
			uniques[ obj_data[ key ] ] = {}
		end
		uniques[ obj_data[ key ] ][ #uniques[ obj_data[ key ] ] + 1 ] = obj_id
	end
	return uniques
end

--- Deep copy table
-- Taken from http://lua-users.org/wiki/CopyTable
-- @param object Table to copy
-- @return Copied table object
function M.deepcopy( object )
	local lookup_table = {}
	local function _copy( object )
		if type( object ) ~= "table" then
			return object
		elseif lookup_table[ object ] then
			return lookup_table[ object ]
		end
		local new_table = {}
		lookup_table[ object ] = new_table
		for index, value in pairs( object ) do
			new_table[ _copy( index ) ] = _copy( value )
		end
		return setmetatable( new_table, getmetatable( object ) )
	end
	return _copy( object )
end

--- Compare two tables together
-- @param table1 First table to compare
-- @param table2 Second table to compare
-- @return true/false
function M.compare_tables( table1, table2 )
	assert( M.is_table( table1 ) and M.is_table( table2 ) )
	if table1 == table2 then return true end

	-- Check tables keys equality
	local keys1 = M.keys( table1 )
	local keys2 = M.keys( table2 )
	table.sort( keys1 )
	table.sort( keys2 )
	if #keys1 ~= #keys2 then return false end
	for i, v in ipairs( keys1 ) do
		if v ~= keys2[ i ] then return false end
	end

	for k, v in pairs( table1 ) do
		if M.is_table( v ) then
			if not M.is_table( table2[ k ] ) then
				return false
			end
			if not M.compare_tables( v, table2[ k ] ) then
				return false
			end
		else
			if v ~= table2[ k ] then return false end
		end
	end
	return true
end

--- Pretty printing of table
-- @param table Table to print
function M.ppt( table )
	assert( M.is_table( table ) )
	for k, v in pairs( table ) do
		print( k, v )
	end
end

--- Split string by some separator
-- Taken from http://lua-users.org/wiki/SplitJoin
-- @param str String to separate
-- @param separator Words separator
-- @return An array of words
function M.split_by( str, separator )
	assert( str and M.is_string( str ) )
	assert( separator and M.is_string( separator ) )
	local words = {}
	local pattern = string.format( "([^%s]+)", separator )
	string.gsub( str,
	             pattern,
	             function( word ) words[ #words + 1 ] = word end )
        return words
end

------------------------------------------------------------------------
-- OOP
------------------------------------------------------------------------

--- Class constructor
-- Taken from http://lua-users.org/wiki/LuaClassesWithMetatable
function M.Class( members )
	members = members or {}
	local mt = {
		__index = members,
		__metatable = members
	}
	local function new( _, init )
		return setmetatable( init or {}, mt )
	end
	members.new = members.new or new
	return mt
end

return M
