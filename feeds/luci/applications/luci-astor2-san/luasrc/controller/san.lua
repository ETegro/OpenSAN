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

mime = require( "mime" )
require( "sha1" )

-- Calculate SHA1 regular expression
hashre = ""
for i = 1, 160 / 8 * 2 do hashre = hashre .. "." end

local function find_by_hash( hash, objs )
	local found = nil
	for _, obj in ipairs( objs ) do
		if sha1( tostring( obj ) ) == hash then
			found = obj
		end
	end
	assert( found, "unable to find object by hash" )
	return found
end

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

local function einarc_logical_add( inputs, drives, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local raid_level = inputs["raid_level"]
	if not raid_level then
		return index_with_error( i18n("RAID level is not selected") )
	end

	if common.is_string( drives ) then
		drives = { drives }
	end

	if not drives then
		return index_with_error( i18n("Drives are not selected") )
	end

	local is_valid, message = is_valid_raid_configuration( raid_level, drives )
	if is_valid then
		-- Check that there are no different models of hard drives for adding
		local found_models = {}
		for _, physical in pairs( data.physicals ) do
			if common.is_in_array( physical.id, drives ) then
				found_models[ physical.model ] = 1
			end
		end
		if #common.keys( found_models ) ~= 1 then
			message_error = i18n("Only single model hard drives should be used")
		end

		local return_code, result = pcall( einarc.Logical.add, raid_level, drives )
		if not return_code then
			return index_with_error( i18n("Failed to create logical disk") .. ": " .. result )
		end
	else
		message_error = message
	end

	return index_with_error( message_error )
end

local function find_logical_id_in_data_by_hash( logical_id_hash, data )
	return find_by_hash( logical_id_hash, common.keys( data.logicals ) )
end

local function einarc_logical_delete( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local logical_id_hash = nil
	for k, v in pairs( inputs ) do
		if not logical_id_hash then
			logical_id_hash = string.match( k, "^submit_logical_delete.(" .. hashre .. ")" )
		end
	end
	assert( logical_id_hash, "unable to parse out logical's id" )
	local logical_id = find_logical_id_in_data_by_hash( logical_id_hash, data )

	-- TODO: check that logical drive does not contain any LVM's LogicalVolumes

	-- Retreive corresponding logical drive object
	local logical = nil
	for _, logical_obj in pairs( data.logicals ) do
		if logical_obj.id == logical_id then
			logical = logical_obj
		end
	end
	assert( logical, "unable to find corresponding logical" )

	-- Find out corresponding PhysicalVolume
	-- TODO: use data
	local physical_volume = nil
	for _, physical_volume_obj in ipairs( lvm.PhysicalVolume.list() ) do
		if physical_volume_obj.device == logical.device then
			physical_volume = physical_volume_obj
		end
	end

	if physical_volume then
		-- Let's clean out VolumeGroup on it at first
		-- TODO: use data
		-- TODO: determine if it has VolumeGroup itself
		local volume_group = lvm.VolumeGroup.list( { physical_volume } )[1]
		assert( volume_group, "unable to find corresponding volume group" )
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

	return index_with_error( message_error )
end

local function find_physical_id_in_data_by_hash( physical_id_hash, data )
	return find_by_hash( physical_id_hash, common.keys( data.physicals ) )
end

local function einarc_logical_hotspare_add( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil
	local physical_id_hash = nil

	for k, v in pairs( inputs ) do
		if not physical_id_hash then
			physical_id_hash = string.match( k, "^submit_logical_hotspare_add.(" .. hashre .. ")" )
		end
	end
	assert( physical_id_hash, "unable to parse out physical's id" )
	local physical_id = find_physical_id_in_data_by_hash( physical_id_hash, data )

	local logical_id = inputs[ "logical_id_hotspare-" .. physical_id_hash ]
	logical_id = tonumber( logical_id )
	if not logical_id then
		return index_with_error( i18n("Logical disk is not selected") )
	end

	if tonumber( inputs[ "logical_minimal_size-" .. physical_id_hash .. "-" .. sha1( tostring( logical_id ) ) ] ) <
	   tonumber( inputs[ "physical_size-" .. physical_id_hash ] ) then
		message_error = i18n("Newly added hotspare disk is bigger than needed")
	end

	-- Let's call einarc at last
	local return_code, result = pcall( einarc.Logical.hotspare_add, { id = logical_id }, physical_id )
	if not return_code then
		message_error = i18n("Failed to add hotspare disk") .. ": " .. result
	end

	return index_with_error( message_error )
end

local function einarc_logical_hotspare_delete( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil
	local physical_id_hash = nil
	local logical_id_hash = nil

	for k, v in pairs( inputs ) do
		if not physical_id_hash then
			logical_id_hash, physical_id_hash = string.match( k, "^submit_logical_hotspare_delete.(" .. hashre .. ").(" .. hashre .. ")" )
		end
	end
	assert( logical_id_hash, "unable to parse out logical's id" )
	assert( physical_id_hash, "unable to parse out physical's id" )
	local physical_id = find_physical_id_in_data_by_hash( physical_id_hash, data )
	local logical_id = find_logical_id_in_data_by_hash( logical_id_hash, data )

	-- Let's call einarc at last
	local return_code, result = pcall( einarc.Logical.hotspare_delete, { id = logical_id }, physical_id )
	if not return_code then
		message_error = i18n("Failed to delete hotspare disk") .. ": " .. result
	end
	return index_with_error( message_error )
end

------------------------------------------------------------------------
-- LVM related functions
------------------------------------------------------------------------

local function find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	return find_by_hash( volume_group_name_hash, common.keys( common.unique_keys( "name", data.volume_groups ) ) )
end

local function lvm_logical_volume_add( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil
	local logical_id_hash = nil

	for k, v in pairs( inputs ) do
		if not logical_id_hash then
			logical_id_hash = string.match( k, "^submit_logical_volume_add.(" .. hashre .. ")" )
		end
	end
	assert( logical_id_hash, "unable to parse out logical's id" )
	local logical_id = find_logical_id_in_data_by_hash( logical_id_hash, data )

	local logical_volume_name = inputs[ "new_volume_name-" .. logical_id_hash ]
	if logical_volume_name == "" then
		return index_with_error( i18n("Logical volume name is not set") )
	end
	if not string.match( logical_volume_name, "^" .. lvm.LogicalVolume.NAME_VALID_RE .. "$" ) then
		return index_with_error( i18n("Invalid logical volume name") )
	end
	for _, logical_volume in ipairs( data.logical_volumes ) do
		if logical_volume.name == logical_volume_name then
			return index_with_error( i18n("Such name already exists") )
		end
	end

	local logical_volume_size = inputs[ "new_volume_slider_size-" .. logical_id_hash ]
	logical_volume_size = tonumber( logical_volume_size )
	assert( common.is_positive( logical_volume_size ),
	        "incorrect non-positive logical volume's size" )

	local return_code = nil
	local result = nil

	local function find_physical_volume_by_device( device, physical_volumes )
		if not physical_volumes then
			physical_volumes = lvm.PhysicalVolume.list()
		end
		for _, physical_volume in ipairs( physical_volumes ) do
			if physical_volume.device == device then
				return physical_volume
			end
		end
		return nil
	end

	local volume_group = nil
	local physical_volume_existing = find_physical_volume_by_device( data.logicals[ logical_id ].device,
	                                                                 data.physical_volumes )
	if physical_volume_existing then
		if physical_volume_existing.volume_group and
		   not lvm.PhysicalVolume.is_orphan( physical_volume_existing ) then
			for _, volume_group_inner in ipairs( data.volume_groups ) do
				if volume_group_inner.name == physical_volume_existing.volume_group then
					volume_group = volume_group_inner
				end
			end
		else
			return_code, result = pcall( lvm.VolumeGroup.create, { physical_volume_existing } )
			if return_code then
				lvm.PhysicalVolume.rescan()
				lvm.VolumeGroup.rescan()
			else
				return index_with_error( i18n("Failed to create VolumeGroup on logical disk") .. ": " .. result )
			end
		end
	else
		return_code, result = pcall( lvm.PhysicalVolume.create, data.logicals[ logical_id ].device )
		if not return_code then
			return index_with_error( i18n("Failed to create PhysicalVolume on logical disk") .. ": " .. result )
		end
		lvm.PhysicalVolume.rescan()

		physical_volume_existing = find_physical_volume_by_device( data.logicals[ logical_id ].device )

		return_code, result = pcall( lvm.VolumeGroup.create, { physical_volume_existing } )
		if return_code then
			lvm.PhysicalVolume.rescan()
			lvm.VolumeGroup.rescan()
		else
			return index_with_error( i18n("Failed to create VolumeGroup on logical disk") .. ": " .. result )
		end

		physical_volume_existing = find_physical_volume_by_device( data.logicals[ logical_id ].device )
	end

	if not volume_group then
		volume_group = lvm.VolumeGroup.list( { physical_volume_existing } )[1]
	end
	assert( volume_group,
		"unable to find corresponding volume group" )

	local return_code, result = pcall( lvm.VolumeGroup.logical_volume,
	                                   volume_group,
	                                   logical_volume_name,
	                                   logical_volume_size )
	if not return_code then
		message_error = i18n("Failed to add logical volume") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )
	return find_by_hash( logical_volume_name_hash, common.keys( common.unique_keys( "name", data.logical_volumes ) ) )
end

local function lvm_logical_volume_remove( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil
	local volume_group_name_hash = nil
	local logical_volume_name_hash = nil

	for k, v in pairs( inputs ) do
		if not logical_volume_name_hash then
			-- san.submit_logical_volume_remove-vg1302871899-lvname_new
			volume_group_name_hash, logical_volume_name_hash = string.match( k, "^submit_logical_volume_remove.(" .. hashre .. ").lv(" .. hashre .. ")" )
		end
	end
	assert( volume_group_name_hash, "unable to parse out volume group's name" )
	assert( logical_volume_name_hash, "unable to parse out logical volume's name" )
	local volume_group_name = find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	local logical_volume_name = find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )

	local return_code, result = pcall( lvm.LogicalVolume.remove,
	                                   { volume_group = { name = volume_group_name },
	                                     name = logical_volume_name } )
	if not return_code then
		message_error = i18n("Failed to remove logical volume") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function lvm_logical_volume_resize( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil
	local volume_group_name_hash = nil
	local logical_volume_name_hash = nil

	for k, v in pairs( inputs ) do
		if not logical_volume_name_hash then
			-- san.submit_logical_volume_resize-vg1302871899-lvname_new
			volume_group_name_hash, logical_volume_name_hash = string.match( k, "^submit_logical_volume_resize.(" .. hashre .. ").lv(" .. hashre .. ")" )
		end
	end
	assert( volume_group_name_hash, "unable to parse out volume group's name" )
	assert( logical_volume_name_hash, "unable to parse out logical volume's name" )
	local volume_group_name = find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	local logical_volume_name = find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )

	local logical_volume_size = inputs[ "logical_volume_resize_slider_size-" .. logical_volume_name_hash ]
	logical_volume_size = tonumber( logical_volume_size )
	assert( common.is_positive( logical_volume_size ),
	        "incorrect non-positive logical volume's size" )

	local return_code, result = pcall( lvm.LogicalVolume.resize,
	                                   { volume_group = { name = volume_group_name },
	                                   name = logical_volume_name },
	                                   logical_volume_size )
	if not return_code then
		message_error = i18n("Failed to resize logical volume") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function lvm_logical_volume_snapshot_add( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil
	local volume_group_name_hash = nil
	local logical_volume_name_hash = nil

	for k, v in pairs( inputs ) do
		if not logical_volume_name_hash then
			-- san.submit_logical_volume_snapshot_add-lvd/dev/vg1303136641/name_new
			volume_group_name_hash, logical_volume_name_hash = string.match( k, "^submit_logical_volume_snapshot_add.lvd(" .. hashre .. ").(" .. hashre .. ")" )
		end
	end
	assert( volume_group_name_hash, "unable to parse out volume group's name" )
	assert( logical_volume_name_hash, "unable to parse out logical volume's name" )
	local volume_group_name = find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	local logical_volume_name = find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )

	local snapshot_size = inputs[ "new_snapshot_slider_size-" .. logical_volume_name_hash ]
	snapshot_size = tonumber( snapshot_size )
	assert( common.is_positive( snapshot_size ),
	        "incorrect non-positive snapshot's size" )

	local return_code, result = pcall( lvm.LogicalVolume.snapshot,
	                                   { name = logical_volume_name,
	                                     device = "/dev/" .. volume_group_name .. "/" .. logical_volume_name },
	                                   snapshot_size )
	if not return_code then
		message_error = i18n("Failed to create snapshot") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function lvm_logical_volume_snapshot_resize( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local volume_group_name_hash = nil
	local snapshot_size = nil
	local logical_volume_name_hash = nil

	for k, v in pairs( inputs ) do
		if not logical_volume_name_hash then
			-- san.submit_logical_volume_snapshot_resize-vg1302871899-s1923-lvname_new
			volume_group_name_hash, snapshot_size, logical_volume_name_hash = string.match( k, "^submit_logical_volume_snapshot_resize.(" .. hashre .. ").s(%d+).lv(" .. hashre .. ")" )
		end
	end
	assert( volume_group_name_hash, "unable to parse out volume group's name" )
	assert( logical_volume_name_hash, "unable to parse out logical volume's name" )
	local volume_group_name = find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	local logical_volume_name = find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )

	snapshot_size = tonumber( snapshot_size )
	assert( common.is_positive( snapshot_size ),
	        "incorrect non-positive snapshot's size" )

	local snapshot_size_new = inputs[ "logical_volume_snapshot_resize_slider_size-" .. logical_volume_name_hash ]
	snapshot_size_new = tonumber( snapshot_size_new )
	assert( common.is_positive( snapshot_size_new ) )
	assert( common.is_positive( snapshot_size_new ),
	        "incorrect non-positive snapshot's size" )

	if snapshot_size_new < snapshot_size then
		return index_with_error( i18n("Snapshot size has to be bigger than it's current size") )
	end

	local return_code, result = pcall( lvm.Snapshot.resize,
	                                   { volume_group = { name = volume_group_name },
	                                     size = snapshot_size,
	                                     name = logical_volume_name },
	                                   snapshot_size_new )
	if not return_code then
		message_error = i18n("Failed to resize snapshot") .. ": " .. result
	end
	return index_with_error( message_error )
end

------------------------------------------------------------------------
-- SCST related functions
------------------------------------------------------------------------
local function scst_access_pattern_new( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local access_pattern_name = inputs[ "access_pattern_new-name" ]
	if access_pattern_name == "" then
		return index_with_error( i18n("Access pattern's name is not set") )
	end

	for _, access_pattern in ipairs( scst.AccessPattern.list() ) do
		if access_pattern.name == access_pattern_name then
			return index_with_error( i18n("Access pattern's name already exists") )
		end
	end

	local access_pattern_targetdriver = inputs[ "access_pattern_new-targetdriver" ]
	assert( access_pattern_targetdriver,
	        "unable to parse out targetdrive" )

	local access_pattern_lun = inputs[ "access_pattern_new-lun" ]
	access_pattern_lun = tonumber( access_pattern_lun )
	assert( common.is_number( access_pattern_lun ),
	        "unable to parse out numeric LUN" )

	local access_pattern_enabled = inputs[ "access_pattern_new-enabled" ]
	local access_pattern_readonly = inputs[ "access_pattern_new-readonly" ]

	local access_pattern_attributes = { name = access_pattern_name,
		                            targetdriver = access_pattern_targetdriver,
		                            lun = access_pattern_lun,
		                            enabled = access_pattern_enabled,
		                            readonly = access_pattern_readonly }

	local return_code, result = pcall( scst.AccessPattern.new, {}, access_pattern_attributes )
	if not return_code then
		return index_with_error( i18n("Failed to create access pattern") .. ": " .. result )
	end

	return_code, result = pcall( scst.AccessPattern.save, result )
	if not return_code then
		message_error = i18n("Failed to save config") .. ": " .. result
	end

	return index_with_error( message_error )
end

local function find_access_pattern_section_name_by_hash( access_pattern_section_name_hash )
	return find_by_hash( access_pattern_section_name_hash,
	                     common.keys( common.unique_keys( "section_name", scst.AccessPattern.list() ) ) )
end

local function scst_access_pattern_delete( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local access_pattern_section_name_hash = nil
	for k, v in pairs( inputs ) do
		if not access_pattern_section_name_hash then
			-- san.submit_access_pattern_delete-cfg022eb2
			access_pattern_section_name_hash = string.match( k, "^submit_access_pattern_delete.(" .. hashre .. ")" )
		end
	end
	assert( access_pattern_section_name_hash,
	        "unable to parse out section's name" )
	local access_pattern_section_name = find_access_pattern_section_name_by_hash( access_pattern_section_name_hash )

	local return_code, result = pcall( scst.AccessPattern.delete,
		                           scst.AccessPattern.find_by_section_name( access_pattern_section_name ) )
	if not return_code then
		message_error = i18n("Failed to delete access pattern") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function access_pattern_comparison_of_bind_luns( logical_volume_device_for_bind, access_pattern_section_name_for_bind )
	local access_pattern_name_for_bind = scst.AccessPattern.find_by_section_name( access_pattern_section_name_for_bind )
	for _, access_pattern in ipairs( scst.AccessPattern.list() ) do
		if access_pattern.filename == logical_volume_device_for_bind then
			if access_pattern.lun == access_pattern_name_for_bind.lun then
				return true
			end
		end
	end
	return false
end

local function scst_access_pattern_bind( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local access_pattern_section_name_hash = nil
	for k, v in pairs( inputs ) do
		if not access_pattern_section_name_hash then
			-- san.submit_access_pattern_bind-cfg022eb2
			access_pattern_section_name_hash = string.match( k, "^submit_access_pattern_bind.(" .. hashre .. ")" )
		end
	end
	assert( access_pattern_section_name_hash,
	        "unable to parse out section's name" )
	local access_pattern_section_name = find_access_pattern_section_name_by_hash( access_pattern_section_name_hash )

	local logical_volume_device = inputs[ "logical_volume_select" ]
	if not logical_volume_device then
		return index_with_error( i18n("Logical volume is not selected") )
	end

	if access_pattern_comparison_of_bind_luns( logical_volume_device, access_pattern_section_name ) then
		return index_with_error( i18n("This is LUN is busy, please choose another one") )
	end

	local return_code, result = pcall( scst.AccessPattern.bind,
	                                   scst.AccessPattern.find_by_section_name( access_pattern_section_name ),
	                                   logical_volume_device )
	if not return_code then
		message_error = i18n("Failed to bind access pattern") .. ": " .. result
	end

	return index_with_error( message_error )
end

local function scst_access_pattern_unbind( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local access_pattern_section_name_hash = nil
	for k, v in pairs( inputs ) do
		if not access_pattern_section_name_hash then
			-- san.submit_access_pattern_unbind-cfg022eb2
			access_pattern_section_name_hash = string.match( k, "^submit_access_pattern_unbind.(" .. hashre .. ")" )
		end
	end
	assert( access_pattern_section_name_hash,
	        "unable to parse out section's name" )
	local access_pattern_section_name = find_access_pattern_section_name_by_hash( access_pattern_section_name_hash )

	local return_code, result = pcall( scst.AccessPattern.unbind,
	                                   scst.AccessPattern.find_by_section_name( access_pattern_section_name ) )
	if not return_code then
		message_error = i18n("Failed to unbind access pattern") .. ": " .. result
	end
	return index_with_error( message_error )
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

local function b64decode( data )
	return (mime.unb64( data ))
end

function perform()
	local inputs = decoded_inputs( luci.http.formvaluetable( "san" ) )
	local i18n = luci.i18n.translate
	local get = luci.http.formvalue

	-- Decode preserialized saved data
	local deserializer = luci.util.restore_data
	local data = {
		logicals = deserializer( b64decode( inputs[ "serialized_logicals" ] ) ),
		physicals = deserializer( b64decode( inputs[ "serialized_physicals" ] ) ),
		physical_volumes = deserializer( b64decode( inputs[ "serialized_physical_volumes" ] ) ),
		volume_groups = deserializer( b64decode( inputs[ "serialized_volume_groups" ] ) ),
		logical_volumes = deserializer( b64decode( inputs[ "serialized_logical_volumes" ] ) )
	}

	local SUBMIT_MAP = {
		logical_add = function() einarc_logical_add( inputs, get( "san.physical_id" ), data ) end,
		logical_delete = function() einarc_logical_delete( inputs, data ) end,
		logical_hotspare_add = function() einarc_logical_hotspare_add( inputs, data ) end,
		logical_hotspare_delete = function() einarc_logical_hotspare_delete( inputs, data ) end,
		logical_volume_add = function() lvm_logical_volume_add( inputs, data ) end,
		logical_volume_remove = function() lvm_logical_volume_remove( inputs, data ) end,
		logical_volume_resize = function() lvm_logical_volume_resize( inputs, data ) end,
		logical_volume_snapshot_add = function() lvm_logical_volume_snapshot_add( inputs, data ) end,
		logical_volume_snapshot_resize = function() lvm_logical_volume_snapshot_resize( inputs, data ) end,
		access_pattern_new = function() scst_access_pattern_new( inputs ) end,
		access_pattern_delete = function() scst_access_pattern_delete( inputs ) end,
		access_pattern_bind = function() scst_access_pattern_bind( inputs ) end,
		access_pattern_unbind = function() scst_access_pattern_unbind( inputs ) end
	}

	for _, submit in ipairs( common.keys( inputs ) ) do
		for submit_part, function_to_call in pairs( SUBMIT_MAP ) do
			if string.match( submit, "^submit_" .. submit_part ) then
				function_to_call()
			end
		end
	end

	return index_with_error( i18n("Unknown action specified") )
end
