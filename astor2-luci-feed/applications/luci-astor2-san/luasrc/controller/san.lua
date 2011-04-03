--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
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
]]--

module( "luci.controller.san", package.seeall )

common = require( "astor2.common" )
einarc = require( "astor2.einarc" )
matrix = require( "luci.controller.matrix" )

require( "luci.i18n" ).loadc( "astor2_san")

function index()
	local i18n = luci.i18n.translate
	local e = entry( { "san" },
	                 call( "index_overall" ),
	                 i18n("SAN"),
	                 10 )
	e.i18n = "astor2_san"

	-- Einarc related
	e = entry( { "san", "perform" },
	           call( "perform" ),
	           nil,
	           10 )
	e.leaf = true
end

------------------------------------------------------------------------
-- Einarc related functions
------------------------------------------------------------------------
local function is_valid_raid_configuration( raid_level, drives )
	local i18n = luci.i18n.translate
	local VALIDATORS = {
		["linear"] = { validator = function( drives ) return #drives > 0 end,
		               message = i18n("Linear level requires at least one drive") },
		["passthrough"] = { validator = function( drives ) return #drives == 1 end,
		                    message = i18n("Passthrough level requries exactly single drive") },
		["0"] = { validator = function( drives ) return #drives >= 2 end,
		          message = i18n("0 level requires two or more drives") },
		["1"] = { validator = function( drives ) return #drives >= 2 and common.is_odd( #drives ) end,
		          message = i18n("1 level requries odd number of two or more drives") },
		["5"] = { validator = function( drives ) return #drives >= 3 end,
		          message = i18n("5 level requires three or more drives") },
		["6"] = { validator = function( drives ) return #drives >= 3 and common.is_odd( #drives ) end,
		          message = i18n("6 level requires odd number of four or more drives") },
		["10"] = { validator = function( drives ) return #drives >= 4 and common.is_odd( #drives ) end,
		           message = i18n("10 level requires odd number or four or more drives") }
	}
	local succeeded, is_valid = pcall( VALIDATORS[ raid_level ].validator, drives )
	if not succeeded then
		return false, i18n("Incorrect RAID level")
	end
	return is_valid, VALIDATORS[ raid_level ].message
end

local function einarc_logical_add( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local drives = nil
	local level = nil
	for k, v in pairs( inputs ) do
		if k == "physical_id" then
			drives = v
		end
		if k == "logical_level" then
			level = v
		end
	end

	if common.is_string( drives ) then
		drives = { drives }
	end

	if not drives then
		index_with_error( i18n("Drives not selected") )
	end

	local is_valid, message = is_valid_raid_configuration( raid_level, drives )
	if is_valid then
		local return_code, result = pcall( einarc.logical.add, raid_level, drives )
		if not return_code then
			message_error = i18n("Failed to create logical disk")
		end
	else
		message_error = message
	end

	index_with_error( message_error )
end

local function einarc_logical_remove( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local logical_id = nil
	for k, v in pairs( inputs ) do
		if not logical_id then
			logical_id = string.match( k, "^submit_logical_remove-(%d+)$" )
		end
	end
	assert( logical_id )
	logical_id = tonumber( logical_id )

	local return_code, result = pcall( einarc.logical.delete, logical_id )
	if not return_code then
		message_error = i18n("Failed to delete logical disk")
	end

	index_with_error( message_error )
end

------------------------------------------------------------------------
-- Different common functions
------------------------------------------------------------------------
function index_overall()
	local message_error = luci.http.formvalue( "message_error" )
	luci.template.render( "san", {
		matrix_overall = matrix.caller(),
		raidlevels = einarc.Adapter:get( "raidlevels" ),
		message_error = message_error } )
end

local function index_with_error( message_error )
	local http = luci.http
	http.redirect( luci.dispatcher.build_url( "san" ) .. "/" ..
	               http.build_querystring( { message_error = message_error } ) )
end

function perform()
	local inputs = luci.http.formvaluetable()
	local submits = luci.http.formvaluetable( "submit_" )
	local i18n = luci.i18n.translate

	local SUBMIT_MAP = {
		logical_add = [einarc_logical_add],
		logical_remove = [einarc_logical_remove],
	}

	for _, submit in common.keys( submits ) do
		for submit_part, function_to_call in pairs( SUBMIT_MAP ) do
			if string.match( submit, "^submit_" .. submit_part ) then
				function_to_call( inputs )
			end
		end
	end

	index_with_error( i18n("Unknown action specified") )
end
