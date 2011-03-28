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
	local e = entry( { "san" },
	                 call( "index_overall" ),
			 i18n("SAN"),
			 10 )
	e.i18n = "astor2_san"

	-- Einarc related
	e = entry( { "san", "einarc_logical_add" },
	           call( "einarc_logical_add" ),
		   nil,
		   10 )
	e.leaf = true
end

local function physical_logical_matrix()
	local matrix = {}
	local current_logical_pointer = 1
	for logical_id, _ in pairs( einarc.logical.list() ) do
		local logical_size = 0
		local physicals_to_sort = {}
		for physical_id, state in pairs( einarc.logical.physical_list( logical_id ) ) do
			physicals_to_sort[ physical_id ] = { state = state }
		end
		for _, physical_data in ipairs( einarc.physical.sorted_list( physicals_to_sort ) ) do
			matrix[ #matrix + 1 ] = { physical_id = physical_data.id }
			logical_size = logical_size + 1
		end
		matrix[ current_logical_pointer ].logical_size = logical_size
		matrix[ current_logical_pointer ].logical_id = logical_id
		current_logical_pointer = current_logical_pointer + 1
	end
	for physical_id, _ in pairs( einarc.physical.list() ) do
		local found = false
		for _, pair in ipairs( matrix ) do
			if physical_id == pair.physical_id then
				found = true
			end
		end
		if not found then
			matrix[ #matrix + 1 ] = { physical_id = physical_id }
		end
	end
	return matrix
end

local function logical_fillup_progress( logicals )
	for task_id, task_data in pairs( einarc.task.list() ) do
		for logical_id, logical_data in pairs( logicals ) do
			if task_data.where == tostring( logical_id ) then
				logicals[ logical_id ].progress = task_data.progress
			end
		end
	end
	return logicals
end

function index_overall()
	local message_error = luci.http.formvalue( "message_error" )
	luci.template.render( "san", {
		physical_logical_matrix = physical_logical_matrix(),
		physicals = einarc.physical.list(),
		logicals = logical_fillup_progress( einarc.logical.list() ),
		raidlevels = einarc.adapter.get( "raidlevels" ),
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

einarc_logical_add = function()
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

	index_with_error( message_error )
end
