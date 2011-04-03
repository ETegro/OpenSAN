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
	e = entry( { "san", "san_functions" },
	           call( "san_functions" ),
	           nil,
	           10 )
	e.leaf = true
end

------------------------------------------------------------------------
-- Different common functions
------------------------------------------------------------------------
function index_overall()
	local message_error = luci.http.formvalue( "message_error" )
	luci.template.render( "san", {
		overall_matrix = matrix.caller(),
		raidlevels = einarc.Adapter:get( "raidlevels" ),
		message_error = message_error } )
end

local function index_with_error( message_error )
	local http = luci.http
	http.redirect( luci.dispatcher.build_url( "san" ) .. "/" ..
	               http.build_querystring( { message_error = message_error } ) )
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

san_functions = function()
	local input_value = luci.http.formvalue( "submit_einarc" )
	local i18n = luci.i18n.translate
	local message_error = nil

	if not input_value then
		message_error = i18n("No input value")
	else
		if input_value == "Logical Delete" then
			local logical_id = luci.http.formvalue( "logical_id" )
			logical_id = tonumber( logical_id )
			if not logical_id then
				message_error = i18n("Logical disk not selected")
			else
				local return_code, result = pcall( einarc.logical.delete, logical_id )
				if not return_code then
					message_error = i18n("Failed to delete logical disk")
				end
			end

		elseif input_value == "Create RAID" then
			local drives = luci.http.formvalue( "checkbox_drive" )
			local raid_level = luci.http.formvalue( "raid_level" )
			if common.is_string( drives ) then
				drives = { drives }
			end
			if not drives then
				message_error = i18n("Drives not selected")
			else
				local is_valid, message = is_valid_raid_configuration( raid_level, drives )
				if is_valid then
					local return_code, result = pcall( einarc.logical.add, raid_level, drives )
					if not return_code then
						message_error = i18n("Failed to create logical disk")
					end
				else
					message_error = message
				end
			end

		end
	end

	index_with_error( message_error )

end
