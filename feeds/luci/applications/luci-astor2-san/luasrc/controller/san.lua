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
scst = require( "astor2.scst" )

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
			message_error = i18n("Only single model hard drives should be used")
		end

		-- Let's call einarc at last
		local return_code = nil
		local result = nil
		local logicals_were = einarc.Logical.list()
		return_code, result = pcall( einarc.Logical.add, raid_level, drives )
		if return_code then
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
			if return_code then
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
				if return_code then
					lvm.PhysicalVolume.rescan()
					lvm.VolumeGroup.rescan()
				else
					message_error = i18n("Failed to create VolumeGroup on logical disk") .. ": " .. result
				end
			else
				message_error = i18n("Failed to create PhysicalVolume on logical disk") .. ": " .. result
			end
		else
			message_error = i18n("Failed to create logical disk") .. ": " .. result
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
		message_error = i18n("Failed to delete logical disk") .. ": " .. result
	end

	index_with_error( message_error )
end

local function einarc_logical_hotspare_add( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil
	local physical_id = nil

	for k, v in pairs( inputs ) do
		if not physical_id then
			physical_id = string.match( k, "^submit_logical_hotspare_add.([%d:]+)$" )
		end
	end

	assert( physical_id )
	local logical_id = inputs[ "logical_id_hotspare-" .. physical_id ]

	logical_id = tonumber( logical_id )
	if not logical_id then
		index_with_error( i18n("Logical not selected") )
	end

	-- Let's call einarc at last
	local return_code, result = pcall( einarc.Logical.hotspare_add, { id = logical_id }, physical_id )
	if not return_code then
		message_error = i18n("Failed to add hotspare disk") .. ": " .. result
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
			logical_id, physical_id = string.match( k, "^submit_logical_hotspare_delete.(%d+).([%d:]+)$" )
		end
	end
	assert( logical_id )
	assert( physical_id )
	logical_id = tonumber( logical_id )

	-- Let's call einarc at last
	local return_code, result = pcall( einarc.Logical.hotspare_delete, { id = logical_id }, physical_id )
	if not return_code then
		message_error = i18n("Failed to delete hotspare disk") .. ": " .. result
	end
	index_with_error( message_error )
end

------------------------------------------------------------------------
-- LVM related functions
------------------------------------------------------------------------
local function lvm_logical_volume_add( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil
	local volume_group_name = nil
	local logical_id = nil

	for k, v in pairs( inputs ) do
		if not volume_group_name then
			-- san.submit_logical_volume_add-450-vg1302871899
			logical_id, volume_group_name = string.match( k, "^submit_logical_volume_add.(%d+).(vg%d+)$" )
		end
	end
	assert( logical_id )
	assert( volume_group_name )

	local logical_volume_name = inputs[ "new_volume_name-" .. logical_id ]
	if logical_volume_name == "" then
		index_with_error( i18n("Volume name is not set") )
	end
	if not string.match( logical_volume_name, lvm.LogicalVolume.name_valid_re ) then
		index_with_error( i18n("Invalid volume name") )
	end

	local logical_volume_size = inputs[ "new_volume_slider_size-" .. logical_id ]
	logical_volume_size = tonumber( logical_volume_size )
	assert( common.is_positive( logical_volume_size ) )

	local return_code, result = pcall( lvm.VolumeGroup.logical_volume,
		                           { name = volume_group_name },
		                           logical_volume_name,
		                           logical_volume_size )
	if not return_code then
		message_error = i18n("Failed to add logical volume") .. ": " .. result
	end
	index_with_error( message_error )
end

local function lvm_logical_volume_remove( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil
	local volume_group_name = nil
	local logical_volume_name = nil

	for k, v in pairs( inputs ) do
		if not logical_volume_name then
			-- san.submit_logical_volume_remove-vg1302871899-lvname_new
			volume_group_name, logical_volume_name = string.match( k, "^submit_logical_volume_remove.(vg%d+).lv([A-Za-z0-9\-_#%%:]+)$" )
		end
	end
	assert( volume_group_name )
	assert( logical_volume_name )

	local return_code, result = pcall( lvm.LogicalVolume.remove,
		                           { volume_group = { name = volume_group_name },
		                             name = logical_volume_name } )
	if not return_code then
		message_error = i18n("Failed to remove logical volume") .. ": " .. result
	end
	index_with_error( message_error )
end

local function lvm_logical_volume_resize( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil
	local volume_group_name = nil
	local logical_volume_name = nil

	for k, v in pairs( inputs ) do
		if not logical_volume_name then
			-- san.submit_logical_volume_resize-vg1302871899-lvname_new
			volume_group_name, logical_volume_name = string.match( k, "^submit_logical_volume_resize.(vg%d+).lv([A-Za-z0-9\-_#%%:]+)$" )
		end
	end
	assert( volume_group_name )
	assert( logical_volume_name )

	local logical_volume_size = inputs[ "logical_volume_resize_slider_size-" .. logical_volume_name ]
	logical_volume_size = tonumber( logical_volume_size )
	assert( common.is_positive( logical_volume_size ) )

	local return_code, result = pcall( lvm.LogicalVolume.resize,
		                           { volume_group = { name = volume_group_name },
		                             name = logical_volume_name },
		                           logical_volume_size )
	if not return_code then
		message_error = i18n("Failed to resize logical volume") .. ": " .. result
	end
	index_with_error( message_error )
end

local function lvm_logical_volume_snapshot_add( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil
	local volume_group_name = nil
	local logical_volume_name = nil

	for k, v in pairs( inputs ) do
		if not logical_volume_name then
			-- san.submit_logical_volume_snapshot_add-lvd/dev/vg1303136641/name_new
			volume_group_name, logical_volume_name = string.match( k, "^submit_logical_volume_snapshot_add.lvd.dev.(vg%d+).(.+)$" )
		end
	end
	assert( volume_group_name )
	assert( logical_volume_name )
	assert( string.match( logical_volume_name, lvm.LogicalVolume.name_valid_re ) )

	local snapshot_size = inputs[ "new_snapshot_slider_size-" .. logical_volume_name ]
	snapshot_size = tonumber( snapshot_size )
	assert( common.is_positive( snapshot_size ) )

	local return_code, result = pcall( lvm.LogicalVolume.snapshot,
		                           { name = logical_volume_name,
		                             device = "/dev/" .. volume_group_name .. "/" .. logical_volume_name },
		                           snapshot_size )
	if not return_code then
		message_error = i18n("Failed to create snapshot") .. ": " .. result
	end
	index_with_error( message_error )
end

local function lvm_logical_volume_snapshot_resize( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local volume_group_name = nil
	local snapshot_size = nil
	local logical_volume_name = nil

	for k, v in pairs( inputs ) do
		if not logical_volume_name then
			-- san.submit_logical_volume_snapshot_resize-vg1302871899-s1923-lvname_new
			volume_group_name, snapshot_size, logical_volume_name = string.match( k, "^submit_logical_volume_snapshot_resize.(vg%d+).s(%d+).lv([A-Za-z0-9\-_#%%:]+)$" )
		end
	end
	assert( volume_group_name )
	assert( logical_volume_name )
	assert( snapshot_size )

	snapshot_size = tonumber( snapshot_size )

	local snapshot_size_new = inputs[ "logical_volume_snapshot_resize_slider_size-" .. logical_volume_name ]
	snapshot_size_new = tonumber( snapshot_size_new )
	assert( common.is_positive( snapshot_size_new ) )

	if  snapshot_size_new < snapshot_size then
		message_error = i18n("Snapshot size should be bigger than it's current size")
	else
		local return_code, result = pcall( lvm.Snapshot.resize,
						   { volume_group = { name = volume_group_name },
						     size = snapshot_size,
						     name = logical_volume_name },
						   snapshot_size_new )
		if not return_code then
			message_error = i18n("Failed to resize snapshot") .. ": " .. result
		end
	end
	index_with_error( message_error )
end

------------------------------------------------------------------------
-- SCST related functions
------------------------------------------------------------------------
local function scst_access_pattern_new( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local access_pattern_name = inputs[ "access_pattern_create-name" ]
	if access_pattern_name == "" then
		index_with_error( i18n("AccessPattern name is not set") )
	end

	local access_pattern_targetdriver = inputs[ "access_pattern_create-targetdriver" ]
	assert( access_pattern_targetdriver )

	local access_pattern_lun = inputs[ "access_pattern_create-lun" ]
	access_pattern_lun = tonumber( access_pattern_lun )
	assert( common.is_number( access_pattern_lun ) )

	local access_pattern_enabled = inputs[ "access_pattern_create-enabled" ]
	if tonumber( access_pattern_enabled ) == 1 then
		access_pattern_enabled = true
	else
		access_pattern_enabled = false
	end

	local access_pattern_readonly = inputs[ "access_pattern_create-readonly" ]
	if tonumber( access_pattern_readonly ) == 1 then
		access_pattern_readonly = true
	else
		access_pattern_readonly = false
	end

	local access_pattern_filename = inputs[ "access_pattern_create-filename" ]

	local access_pattern_attributes = { name = access_pattern_name,
		                            targetdriver = access_pattern_targetdriver,
		                            lun = access_pattern_lun,
		                            enabled = access_pattern_enabled,
		                            readonly = access_pattern_readonly }

	local return_code, result = pcall( scst.AccessPattern.new, {}, access_pattern_attributes )
	if return_code then
		return_code, result = pcall( scst.AccessPattern.save, result )
		if not return_code then
			message_error = i18n("Failed to save config") .. ": " .. result
		end
	else
		message_error = i18n("Failed to create AccessPattern") .. ": " .. result
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

local function decoded_inputs( inputs )
	local new_inputs = {}
	for k, v in pairs( inputs ) do
		new_inputs[ luci.http.protocol.urldecode( k ) ] = v
	end
	return new_inputs
end

function perform()
	local inputs = decoded_inputs( luci.http.formvaluetable( "san" ) )
	local i18n = luci.i18n.translate
	local get = luci.http.formvalue

	local SUBMIT_MAP = {
		logical_add = function() einarc_logical_add( inputs, get( "san.physical_id" ) ) end,
		logical_delete = function() einarc_logical_delete( inputs ) end,
		logical_hotspare_add = function() einarc_logical_hotspare_add( inputs ) end,
		logical_hotspare_delete = function() einarc_logical_hotspare_delete( inputs ) end,
		logical_volume_add = function() lvm_logical_volume_add( inputs ) end,
		logical_volume_remove = function() lvm_logical_volume_remove( inputs ) end,
		logical_volume_resize = function() lvm_logical_volume_resize( inputs ) end,
		logical_volume_snapshot_add = function() lvm_logical_volume_snapshot_add( inputs ) end,
		logical_volume_snapshot_resize = function() lvm_logical_volume_snapshot_resize( inputs ) end,
		access_pattern_create = function() scst_access_pattern_new( inputs ) end
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
