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

require( "luci.i18n" ).loadc( "astor2_san")

function index()
	local i18n = luci.i18n.translate
	local e = entry( { "san" }, call( "einarc_lists" ), i18n("SAN"), 10 )
	e.i18n = "astor2_san"

	e = entry( { "san", "logical_add" }, call( "logical_add" ), nil, 10 )
	e.leaf = true
end

function einarc_lists()
	local message_error = luci.http.formvalue( "message_error" )
	luci.template.render( "san", {
		physical_list = einarc.physical.list(),
		logical_list = einarc.logical.list(),
		raidlevels = einarc.adapter.get( "raidlevels" ),
		task_list = einarc.task.list(),
		message_error = message_error } )
end

local function is_valid_raid_level( raid_level )
	return common.is_in_array( raid_level, einarc.adapter.get( "raidlevels" ) )
end

local function is_valid_raid_configuration( raid_level, drives )
	local i18n = luci.i18n.translate
	local VALIDATORS = {
		["linear"] = { validator = function( drives ) return #drives == 1 end,
		               message = i18n("Linear level requires exactly single drive") },
		["passthrough"] = { validator = function( drives ) return #drives == 1 end,
		                    message = i18n("Passthrough level requries exactly single drive") },
		["0"] = { validator = function( drives ) return #drives >= 2 end,
		          message = i18n("0 level requires two or more drives") },
		["1"] = { validator = function( drives ) return #drives >= 2 and common.is_odd( #drives ) end,
		          message = i18n("1 level requries odd number two or more drives") },
		["5"] = { validator = function( drives ) return #drives >= 3 end,
		          message = i18n("5 level requires three or more drives") },
		["6"] = { validator = function( drives ) return #drives >= 3 and common.is_odd( #drives ) end,
		          message = i18n("6 level requires odd number of four or more drives") },
		["10"] = { validator = function( drives ) return #drives >= 4 and common.is_odd( #drives ) end,
		           message = i18n("10 level requires odd number or four or more drives") }
	}
	return VALIDATORS[ raid_level ].validator( drives ), VALIDATORS[ raid_level ].message
end

local function index_with_error( message_error )
	local http = luci.http
	http.redirect( luci.dispatcher.build_url( "san" ) .. "/" ..
	               http.build_querystring( { message_error = message_error } ) )
end

function logical_add()
	local drives = luci.http.formvalue( "drives" )
	local raid_level = luci.http.formvalue( "raid_level" )
	local message_error = nil
	local i18n = luci.i18n.translate

	if common.is_string( drives ) then
		drives = { drives }
	end

	if not drives then
		message_error = i18n("Drives not selected")
	else
		if not is_valid_raid_level( raid_level ) then
			message_error = i18n("Incorrect RAID level")
		else
			local is_valid, message = is_valid_raid_level( raid_level )
			if is_valid then
				einarc.logical.add( raid_level, drives )
			else
				message_error = message
			end
		end
	end

	index_with_error( message_error )
end
