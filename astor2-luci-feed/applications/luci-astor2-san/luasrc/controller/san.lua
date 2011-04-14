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
lvm = require( "astor2.lvm" )
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
		["6"] = { validator = function( drives ) return #drives >= 4 and common.is_odd( #drives ) end,
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

local function einarc_logical_add( inputs, drives )
	local i18n = luci.i18n.translate
	local message_error = nil

	local raid_level = inputs["raid_level"]
	if not raid_level then
		index_with_error( i18n("RAID level is not selected") )
	end

	if common.is_string( drives ) then
		drives = { drives }
	end

	if not drives then
		index_with_error( i18n("Drives are not selected") )
	end

	local is_valid, message = is_valid_raid_configuration( raid_level, drives )
	if is_valid then
		-- Check that there are no different models of hard drives for adding
		local found_models = {}
		for _, physical in pairs( einarc.Physical.list() ) do
			if common.is_in_array( physical.id, drives ) then
				found_models[ physical.model ] = 1
			end
		end
		if #common.keys( found_models ) ~= 1 then
			message_error = i18n("Only single model hard drives can be used")
		else
			-- Let's call einarc at last
			local return_code = nil
			local result = nil
			local logicals_were = einarc.Logical.list()
			return_code, result = pcall( einarc.Logical.add, raid_level, drives )
			if not return_code then
				message_error = i18n("Failed to create logical disk")
			end

			-- And let's create PV and VG on it
			-- At first, find out newly created device
			local device = nil
			for logical_id, logical in pairs( einarc.Logical.list() ) do
				if not logicals_were[ logical_id ] then
					device = logical.device
				end
			end
			assert( device )
			-- Then, create PV on it
			return_code, result = pcall( lvm.PhysicalVolume.create, device )
			if not return_code then
				message_error = i18n("Failed to create PhysicalVolume on logical disk")
			end
			lvm.PhysicalVolume.rescan()
			-- Find out newly created PhysicalVolume
			local physical_volumes = nil
			for _, physical_volume in ipairs( lvm.PhysicalVolume.list() ) do
				if physical_volume.device == device then
					physical_volumes = { physical_volume }
				end
			end
			assert( physical_volumes )
			-- And then, create VG on it
			return_code, result = pcall( lvm.VolumeGroup.create, physical_volumes )
			if not return_code then
				message_error = i18n("Failed to create VolumeGroup on logical disk")
			end
			lvm.PhysicalVolume.rescan()
			lvm.VolumeGroup.rescan()
		end
	else
		message_error = message
	end

	index_with_error( message_error )
end

local function einarc_logical_delete( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local logical_id = nil
	for k, v in pairs( inputs ) do
		if not logical_id then
			logical_id = string.match( k, "^submit_logical_delete.(%d+)$" )
		end
	end
	assert( logical_id )
	logical_id = tonumber( logical_id )

	-- TODO: check that logical drive does not contain any LVM's LogicalVolumes

	-- Retreive corresponding logical drive object
	local logical = nil
	for _, logical_obj in pairs( einarc.Logical.list() ) do
		if logical_obj.id == logical_id then
			logical = logical_obj
		end
	end
	assert( logical )

	-- Find out corresponding PhysicalVolume
	local physical_volume = nil
	for _, physical_volume_obj in ipairs( lvm.PhysicalVolume.list() ) do
		if physical_volume_obj.device == logical.device then
			physical_volume = physical_volume_obj
		end
	end

	if physical_volume then
		-- Let's clean out VolumeGroup on it at first
		local volume_group = lvm.VolumeGroup.list( { physical_volume } )[1]
		assert( volume_group )
		volume_group:remove()

		-- And clean out PhysicalVolume
		physical_volume:remove()
	end

	lvm.VolumeGroup.rescan()
	lvm.PhysicalVolume.rescan()

	local return_code, result = pcall( einarc.Logical.delete, { id = logical_id } )
	if not return_code then
		message_error = i18n("Failed to delete logical disk")
	end

	index_with_error( message_error )
end

local function einarc_logical_hotspare_add( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil
	local physical_id = nil

	for k, v in pairs( inputs ) do
		if not physical_id then
			physical_id = table.concat( { string.match( k, "^submit_logical_hotspare_add.(%d)%%%d%d(%d)$" ) }, ":" )
		end
	end
	assert( physical_id )

	local logical_id = inputs["logical_id_hotspare"]
	if common.is_string( logical_id ) then
		drives = tonumber( logical_id )
	end
	if not logical_id then
		index_with_error( i18n("Logical not selected") )
	end
	-- Let's call einarc at last
	local return_code, result = pcall( einarc.Logical.hotspare_add, { id = logical_id }, physical_id )
	if not return_code then
		message_error = i18n("Failed to add hotspare disk")
	end
	index_with_error( message_error )
end

local function einarc_logical_hotspare_delete( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil
	local physical_id = nil
	local logical_id = nil

	for k, v in pairs( inputs ) do
		if not physical_id then
			local logical_id, physical_id_part1, physical_id_part2 = string.match( k, "^submit_logical_hotspare_delete.[(%d)].(%d)%%%d%d(%d)$" )
			local physical_id = physical_id_part1 .. ":" .. physical_id_part2
		end
	end
	assert( physical_id )
	assert( logical_id )
	if common.is_string( logical_id ) then
		drives = tonumber( logical_id )
	end
	-- Let's call einarc at last
	local return_code, result = pcall( einarc.Logical.hotspare_delete, { id = logical_id }, physical_id )
	if not return_code then
		message_error = i18n("Failed to delete hotspare disk")
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

function perform()
	local inputs = luci.http.formvaluetable( "san" )
	local i18n = luci.i18n.translate
	local get = luci.http.formvalue

	local SUBMIT_MAP = {
		logical_add = function() einarc_logical_add( inputs, get("san.physical_id") ) end,
		logical_delete = function() einarc_logical_delete( inputs ) end,
		logical_hotspare_add = function() einarc_logical_hotspare_add( inputs ) end,
		logical_hotspare_delete = function() einarc_logical_hotspare_delete( inputs ) end
	}

	for _, submit in ipairs( common.keys( inputs ) ) do
		for submit_part, function_to_call in pairs( SUBMIT_MAP ) do
			if string.match( submit, "^submit_" .. submit_part ) then
				function_to_call( inputs )
			end
		end
	end

	index_with_error( i18n("Unknown action specified") )
end
