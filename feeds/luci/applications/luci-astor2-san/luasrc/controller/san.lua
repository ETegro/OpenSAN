--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2012 ETegro Technologies, PLC
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
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
]]--

module( "luci.controller.san", package.seeall )

common = require( "astor2.common" )
einarc = require( "astor2.einarc" )
lvm = require( "astor2.lvm" )
matrix = require( "luci.controller.matrix" )
scst = require( "astor2.scst" )
caching = require( "astor2.caching" )

------------------------------------------------------------------------
-- Hash related functions
------------------------------------------------------------------------
require( "sha2" )

-- Calculate SHA2-256 regular expression
hashre = ""
for i = 1, 256 / 8 * 2 do hashre = hashre .. "." end

local function hash( data )
	return sha2.sha256hex( data )
end

local function find_by_hash( obj_hash, objs )
	local found = nil
	for _, obj in ipairs( objs ) do
		if hash( tostring( obj ) ) == obj_hash then
			found = obj
		end
	end
	assert( found, "unable to find object by hash" )
	return found
end

require( "luci.i18n" ).loadc( "astor2_san")

function index()
	local i18n = luci.i18n.translate
	local e = entry(
		{ "admin", "san" },
		call( "index_overall" ),
		i18n("SAN"),
		10
	)
	e.i18n = "astor2_san"

	e = entry(
		{ "admin", "san", "perform" },
		call( "perform" ),
		nil,
		10
	)
	e.leaf = true
end

local function index_with_error( message_error )
	local http = luci.http
	if message_error then message_error = tostring( message_error ) end
	http.redirect( luci.dispatcher.build_url( "admin", "san" ) .. "/" ..
	               http.build_querystring( { message_error = message_error } ) )
end

------------------------------------------------------------------------
-- Einarc related functions
------------------------------------------------------------------------
local function is_valid_raid_configuration( raid_level, drives )
	local i18n = luci.i18n.translate
	local VALIDATORS = {
		["linear"] = {
			validator = function( drives ) return #drives > 0 end,
			message = i18n("RAID linear level requires at least one drive")
		},
		["0"] = {
			validator = function( drives ) return #drives >= 2 end,
			message = i18n("RAID 0 level requires two or more drives")
		},
		["1"] = {
			validator = function( drives ) return #drives >= 2 end,
			message = i18n("RAID 1 level requries two or more drives")
		},
		["4"] = {
			validator = function( drives ) return #drives >= 3 end,
			message = i18n("RAID 4 level requires three or more drives")
		},
		["5"] = {
			validator = function( drives ) return #drives >= 3 end,
			message = i18n("RAID 5 level requires three or more drives")
		},
		["6"] = {
			validator = function( drives ) return #drives >= 4 end,
			message = i18n("RAID 6 level requires four or more drives")
		},
		["10"] = {
			validator = function( drives ) return #drives >= 4 and common.is_odd( #drives ) end,
			message = i18n("RAID 10 level requires odd number of four or more drives")
		}
	}
	local succeeded, is_valid = pcall( VALIDATORS[ raid_level ].validator, drives )
	if not succeeded then
		return false, i18n("Incorrect RAID level")
	end
	return is_valid, VALIDATORS[ raid_level ].message
end

--[[
+ - - - - - - - - - - - - - - - - - +
' Creation of RAID                  '
'                                   '
'                                   '
'                                   '
'                                   '
'   H                               '
'   H                               '
'   v                               '
' +-------------------------------+ '
' |     Stop all non-RAID VGs     | '
' +-------------------------------+ '
'   |                               '
'   |                               '
'   v                               '
' +-------------------------------+ '
' |          Create RAID          | '
' +-------------------------------+ '
'   |                               '
'   |                               '
'   v                               '
' +-------------------------------+ '
' | prepare( newly created RAID ) | '
' +-------------------------------+ '
'   H                               '
'   H                               '
'   v                               '
'                                   '
'                                   '
'                                   '
'                                   '
+ - - - - - - - - - - - - - - - - - +
]]
local function disable_non_raid_volume_groups( data )
	for _, volume_group in ipairs( lvm.VolumeGroup.list( lvm.PhysicalVolume.list() ) ) do
		local is_not_busy = true
		for _, physical_volume in ipairs( volume_group.physical_volumes ) do
			for _, logical in pairs( data.logicals ) do
				if logical.device == physical_volume.device then
					is_not_busy = false
				end
			end
		end
		if is_not_busy then
			lvm.VolumeGroup.disable( volume_group )
		end
	end
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
	if not is_valid then
		return index_with_error( message )
	end

	lvm.restore()
	disable_non_raid_volume_groups( data )

	local return_code, result = pcall( einarc.Logical.add, raid_level, drives )
	if not return_code then
		return index_with_error( i18n("Failed to create logical disk") .. ": " .. result )
	end

	for _, logical in pairs( einarc.Logical.list() ) do
		if #common.keys( data.logicals ) == 0 then
			lvm.PhysicalVolume.prepare( logical.device )
		end
		local preparation_need = true
		for _, logical_previous in pairs( data.logicals ) do
			if logical_previous.device == logical.device then
				preparation_need = false
			end
		end
		if preparation_need then
			lvm.PhysicalVolume.prepare( logical.device )
		end
	end

	return index_with_error( message_error )
end

local function find_logical_id_in_data_by_hash( logical_id_hash, data )
	return find_by_hash( logical_id_hash, common.keys( data.logicals ) )
end

local function parse_inputs_by_re( inputs, re )
	local re = table.concat( re, "" )
	for k, v in pairs( inputs ) do
		local result = { string.match( k, re ) }
		if #result > 0 then
			if #result == 1 then
				return result[1]
			else
				return result
			end
		end
	end
	return nil
end

--[[
         ┌−−−−−−−−−−−−−−−−−−−−−−−−−┐
         ╎ Deletion of RAID        ╎
         ╎                         ╎
         ╎                         ╎
         ╎                         ╎
         ╎                         ╎
         ╎   ║                     ╎
         ╎   ║                     ╎
         ╎   ║                     ╎
         ╎   ║                      −−−−−−−−┐
         ╎   ∨                              ╎
         ╎ ┌─────────────────────┐          ╎
         ╎ │      PV exist?      │ ───┐     ╎
         ╎ └─────────────────────┘    │     ╎
         ╎   │                        │     ╎
         ╎   │ YES                    │     ╎
         ╎   │                        │     ╎
┌−−−−−−−−    │                        │     ╎
╎            ∨                        │     ╎
╎          ┌─────────────────────┐    │     ╎
╎   ┌───── │      VG exist?      │    │     ╎
╎   │      └─────────────────────┘    │     ╎
╎   │        │                        │ NO  ╎
╎   │        │ YES                    │     ╎
╎   │        ∨                        │     ╎
╎   │      ┌─────────────────────┐    │     ╎
╎   │ NO   │       Stop VG       │    │     ╎
╎   │      └─────────────────────┘    │     ╎
╎   │        │                        │     ╎
╎   │        │                        │     ╎
╎   │        ∨                        │     ╎
╎   │      ┌─────────────────────┐    │     ╎
╎   └────> │   prepare( RAID )   │ <──┘     ╎
╎          └─────────────────────┘          ╎
╎            │                              ╎
└−−−−−−−−    │                              ╎
         ╎   │                              ╎
         ╎   │                              ╎
         ╎   ∨                              ╎
         ╎ ┌─────────────────────┐          ╎
         ╎ │    RAID cached?     │ ───┐     ╎
         ╎ └─────────────────────┘    │     ╎
         ╎   │                        │     ╎
         ╎   │ YES                    │     ╎
         ╎   ∨                        │     ╎
         ╎ ┌─────────────────────┐    │     ╎
         ╎ │ Unbind cache device │    │ NO  ╎
         ╎ └─────────────────────┘    │     ╎
         ╎   │                        │     ╎
         ╎   │                        │     ╎
         ╎   ∨                        │     ╎
         ╎ ┌─────────────────────┐    │     ╎
         ╎ │     Delete RAID     │ <──┘     ╎
         ╎ └─────────────────────┘          ╎
         ╎   ║                              ╎
         ╎   ║                      −−−−−−−−┘
         ╎   ║                     ╎
         ╎   ║                     ╎
         ╎   ∨                     ╎
         ╎                         ╎
         ╎                         ╎
         ╎                         ╎
         ╎                         ╎
         └−−−−−−−−−−−−−−−−−−−−−−−−−┘
]]
local function einarc_logical_delete( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local logical_id_hash = parse_inputs_by_re( inputs, {"^submit_logical_delete.(",hashre,")"} )
	assert( logical_id_hash, "unable to parse out logical's id" )
	local logical_id = find_logical_id_in_data_by_hash( logical_id_hash, data )

	-- Retreive corresponding logical drive object
	local logical = nil
	for _, logical_obj in pairs( data.logicals ) do
		if logical_obj.id == logical_id then
			logical = logical_obj
		end
	end
	assert( logical, "unable to find corresponding logical" )

	for _, volume_group in ipairs( data.volume_groups ) do
		local need_to_stop = false
		for _, physical_volume in ipairs( volume_group.physical_volumes ) do
			if physical_volume.device == logical.device then
				need_to_stop = true
			end
		end
		if need_to_stop then
			lvm.VolumeGroup.disable( volume_group )
		end
	end

	_,_ = pcall( lvm.PhysicalVolume.prepare, logical.device )

	for _,map in ipairs( einarc.Flashcache.list() ) do
		if map.logical_id == logical_id then
			einarc.Flashcache.unbind( einarc.Physical.list()[ map.physical_id ] )
		end
	end

	local return_code, result = pcall( einarc.Logical.delete, einarc.Logical.list()[ logical_id ] )
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

	local physical_id_hash = parse_inputs_by_re( inputs, {"^submit_logical_hotspare_add.(",hashre,")"} )
	assert( physical_id_hash, "unable to parse out physical's id" )
	local physical_id = find_physical_id_in_data_by_hash( physical_id_hash, data )

	local logical_id = inputs[ "logical_id_hotspare-" .. physical_id_hash ]
	logical_id = tonumber( logical_id )
	if not logical_id then
		return index_with_error( i18n("Logical disk is not selected") )
	end

	if tonumber( inputs[ "logical_minimal_size-" .. physical_id_hash .. "-" .. hash( tostring( logical_id ) ) ] ) <
	   tonumber( inputs[ "physical_size-" .. physical_id_hash ] ) then
		message_error = i18n("Newly added dedicated hotspare disk is bigger than needed")
	end

	lvm.restore()
	disable_non_raid_volume_groups( data )

	local return_code, result = pcall(
		einarc.Logical.hotspare_add,
		einarc.Logical.list()[ logical_id ],
		einarc.Physical.list()[ physical_id ]
	)
	if not return_code then
		message_error = i18n("Failed to add dedicated hotspare disk") .. ": " .. result
	end

	return index_with_error( message_error )
end

local function einarc_logical_hotspare_delete( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local tmp = parse_inputs_by_re( inputs, {"^submit_logical_hotspare_delete.(",hashre,").(",hashre,")"} )
	assert( tmp, "unable to parse out logical's and physical's ids" )
	local logical_id_hash = tmp[1]
	local physical_id_hash = tmp[2]
	local physical_id = find_physical_id_in_data_by_hash( physical_id_hash, data )
	local logical_id = find_logical_id_in_data_by_hash( logical_id_hash, data )

	local return_code, result = pcall(
		einarc.Logical.hotspare_delete,
		einarc.Logical.list()[ logical_id ],
		einarc.Physical.list()[ physical_id ]
	)
	if not return_code then
		message_error = i18n("Failed to delete dedicated hotspare disk") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function einarc_logical_physical_detach( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local tmp = parse_inputs_by_re( inputs, {"^submit_logical_physical_detach.(",hashre,").(",hashre,")"} )
	assert( tmp, "unable to parse out logical's and physical's ids" )
	local logical_id_hash = tmp[1]
	local physical_id_hash = tmp[2]
	local physical_id = find_physical_id_in_data_by_hash( physical_id_hash, data )
	local logical_id = find_logical_id_in_data_by_hash( logical_id_hash, data )

	local return_code, result = pcall(
		einarc.Logical.detach,
		einarc.Logical.list()[ logical_id ],
		einarc.Physical.list()[ physical_id ]
	)
	if not return_code then
		message_error = i18n("Failed to detach disk") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function einarc_logical_flashcache_bind( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local physical_id_hash = parse_inputs_by_re( inputs, {"^submit_logical_flashcache_bind.(",hashre,")"} )
	assert( physical_id_hash, "unable to parse out physical's id" )
	local physical_id = find_physical_id_in_data_by_hash( physical_id_hash, data )

	local logical_id = inputs[ "logical_id_flashcache-" .. physical_id_hash ]
	logical_id = tonumber( logical_id )

	if not logical_id then
		return index_with_error( i18n("Logical disk is not selected") )
	end

	local mode = inputs[ "logical_id_flashcache_mode-" .. physical_id_hash ]

	if not mode then
		return index_with_error( i18n("Caching mode is not selected") )
	end

	local return_code, result = pcall(
		einarc.Flashcache.bind,
		einarc.Physical.list()[ physical_id ],
		einarc.Logical.list()[ logical_id ],
		mode
	)
	if not return_code then
		message_error = i18n("Failed to bind SSD cache") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function einarc_logical_flashcache_unbind( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local physical_id_hash = parse_inputs_by_re( inputs, {"^submit_logical_flashcache_unbind.(",hashre,")"} )
	assert( physical_id_hash, "unable to parse out physical's id" )
	local physical_id = find_physical_id_in_data_by_hash( physical_id_hash, data )

	local return_code, result = pcall(
		einarc.Flashcache.unbind,
		einarc.Physical.list()[ physical_id ]
	)
	if not return_code then
		message_error = i18n("Failed to unbind SSD cache") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function einarc_logical_grow( inputs, drives, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local logical_id_hash = parse_inputs_by_re( inputs, {"^submit_logical_grow.(",hashre,")"} )
	assert( logical_id_hash, "unable to parse out logical's ids" )
	local logical_id = find_logical_id_in_data_by_hash( logical_id_hash, data )

	if common.is_string( drives ) then
		drives = { drives }
	end

	if not drives then
		return index_with_error( i18n("Drives are not selected") )
	end

	local logical = einarc.Logical.list()[ logical_id ]
	logical:physical_list()

	local return_code, result = pcall(
		einarc.Logical.grow,
		logical,
		drives
	)
	if not return_code then
		return index_with_error( i18n("Failed to expand logical disk") .. ": " .. result )
	end
	return index_with_error( message_error )
end

------------------------------------------------------------------------
-- LVM related functions
------------------------------------------------------------------------

local function find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	return find_by_hash(
		volume_group_name_hash,
		common.keys( common.unique_keys( "name", data.volume_groups ) )
	)
end

local function physical_volume_bounds_check( physical_volume, logical_size )
	logical_size = lvm.PhysicalVolume.expected_size(
		tonumber( logical_size ) or 0,
		tonumber( physical_volume.extent ) or lvm.VolumeGroup.PE_DEFAULT_SIZE
	)
	if logical_size > ( tonumber( physical_volume.total ) or 0 ) then
		lvm.PhysicalVolume.resize( physical_volume )
	end
end

--[[
                                     ║
                                     ║
                                     ∨
                                   ┌─────────────────┐
                                   │   PV exists?    │ ─┐
                                   └─────────────────┘  │
                                     │                  │
                                     │ YES              │
                                     ∨                  │
                                   ┌─────────────────┐  │
                              ┌─── │   VG exists?    │  │
                              │    └─────────────────┘  │
                              │      │                  │
                              │      │ YES              │
                              │      ∨                  │
     ┌─────────────┐  YES     │    ┌─────────────────┐  │
  ┌─ │ PV bounded? │ <────────┼─── │   LV exists?    │  │ NO
  │  └─────────────┘          │    └─────────────────┘  │
  │    │                      │      │                  │
  │    │ NO                   │      │ NO               │
  │    ∨                      │      ∨                  │
  │  ┌─────────────┐          │    ┌─────────────────┐  │
  │  │ Maximize PV │          │ NO │     Stop VG     │  │
  │  └─────────────┘          │    └─────────────────┘  │
  │    │                      │      │                  │
  │    │                      │      │                  │
  │    │                      │      ∨                  │
  │    │                      │    ┌─────────────────┐  │
  │    │                      └──> │ prepare( RAID ) │ <┘
  │    │                           └─────────────────┘
  │    │                             │
  │    │                             │
  │    │                             ∨
  │    │                           ┌─────────────────┐
  │    │                           │    Create PV    │
  │    │                           └─────────────────┘
  │    │                             │
  │    │                             │
  │    │                             ∨
  │    │                           ┌─────────────────┐
  │    │                           │    Create VG    │
  │    │                           └─────────────────┘
  │    │                             │
  │    │                             │
  │    │                             ∨
  │    │                           ┌─────────────────┐
  │    └─────────────────────────> │    Create LV    │ <┐
  │                                └─────────────────┘  │
  │                                  ║                  │
  │                                  ║                  │
  │                                  ∨                  │
  │                                                     │ YES
  │                                                     │
  │                                                     │
  │                                                     │
  └─────────────────────────────────────────────────────┘
]]
local function lvm_logical_volume_add( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local logical_id_hash = parse_inputs_by_re( inputs, {"^submit_logical_volume_add.(",hashre,")"} )
	assert( logical_id_hash, "unable to parse out logical's id" )
	local logical_id = find_logical_id_in_data_by_hash( logical_id_hash, data )

	local logical_volume_name = inputs[ "new_volume_name-" .. logical_id_hash ]
	if logical_volume_name == "" then
		return index_with_error( i18n("Logical volume name is not set") )
	end
	if not lvm.LogicalVolume.name_is_valid( logical_volume_name ) then
		return index_with_error( i18n("Invalid logical volume name") )
	end

	local logical_volume_size = inputs[ "new_volume_slider_size-" .. logical_id_hash ]
	logical_volume_size = tonumber( logical_volume_size )
	assert( common.is_positive( logical_volume_size ),
	        "incorrect non-positive logical volume's size" )

	local device = data.logicals[ logical_id ].device
	lvm.restore()

	local return_code = nil
	local result = nil

	local volume_group_found = nil
	for _, volume_group in ipairs( data.volume_groups ) do
		for _, physical_volume in ipairs( volume_group.physical_volumes ) do
			if physical_volume.device == device then
				volume_group_found = volume_group
			end
		end
	end

	local create_from_scratch = true
	if volume_group_found then
		for _, logical_volume in ipairs( data.logical_volumes ) do
			if logical_volume.volume_group == volume_group_found.name then
				create_from_scratch = false
			end
		end
		if create_from_scratch then
			lvm.VolumeGroup.disable( volume_group_found )
		end
	end

	local function find_physical_volume_by_device( device )
		return common.search_attr(
			lvm.PhysicalVolume.list(),
			"device",
			device
		)[1]
	end

	if create_from_scratch then
		return_code, result = pcall( lvm.PhysicalVolume.create, device )
		if not return_code then
			return index_with_error( i18n("Failed to create PhysicalVolume on logical disk") .. ": " .. result )
		end
		lvm.PhysicalVolume.rescan()

		local physical_volume = find_physical_volume_by_device( device )

		return_code, result = pcall( lvm.VolumeGroup.create, { physical_volume } )
		if return_code then
			lvm.PhysicalVolume.rescan()
			lvm.VolumeGroup.rescan()
		else
			return index_with_error( i18n("Failed to create VolumeGroup on logical disk") .. ": " .. result )
		end

		physical_volume = find_physical_volume_by_device( device )
		volume_group_found = lvm.VolumeGroup.list( { physical_volume } )[1]
	else
		physical_volume_bounds_check(
			find_physical_volume_by_device( device ),
			data.logicals[ logical_id ].size
		)
	end

	assert( volume_group_found,
	        "unable to find corresponding volume group" )

	for _, logical_volume in ipairs( data.logical_volumes ) do
		if ( logical_volume.name == logical_volume_name and
		     logical_volume.volume_group == volume_group_found.name ) then
			return index_with_error( i18n("Logical disk can not contain equally named logical volumes") )
		end
	end

	local return_code, result = pcall(
		lvm.VolumeGroup.logical_volume,
		volume_group_found,
		logical_volume_name,
		logical_volume_size
	)
	if not return_code then
		message_error = i18n("Failed to add logical volume") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )
	return find_by_hash(
		logical_volume_name_hash,
		common.keys( common.unique_keys( "name", data.logical_volumes ) )
	)
end

--[[
                      + - - - - - - - - - - - - - - +
                      ' Deletion of LogicalVolume   '
                      '                             '
                      '                             '
                      '                             '
                      '                             '
                      '   H                         '
                      '   H                         '
                      '   H                         '
+ - - - - - - - - - -     H                         '
'                         v                         '
' +-----------+  NO     +-------------------------+ '
' | Delete LV | <------ |     Is it last LV?      | '
' +-----------+         +-------------------------+ '
'                         |                         '
+ - - - - - - - - - -     |                         '
                      '   |                         '
                      '   | YES                     '
                      '   v                         '
                      ' +-------------------------+ '
                      ' |         Stop VG         | '
                      ' +-------------------------+ '
                      '   |                         '
                      '   |                         '
                      '   v                         '
                      ' +-------------------------+ '
                      ' |     prepare( RAID )     | '
                      ' +-------------------------+ '
                      '                             '
                      + - - - - - - - - - - - - - - +
]]
local function lvm_logical_volume_remove( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local tmp = parse_inputs_by_re( inputs, {"^submit_logical_volume_remove.(",hashre,").lv(",hashre,")"} )
	assert( tmp, "unable to parse out volume group's and logical volume's names" )
	local volume_group_name_hash = tmp[1]
	local logical_volume_name_hash = tmp[2]
	local volume_group_name = find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	local logical_volume_name = find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )

	local is_last = true
	for _, logical_volume in ipairs( data.logical_volumes ) do
		if logical_volume.volume_group == volume_group_name and
		   logical_volume.name ~= logical_volume_name then
			is_last = false
		end
	end

	local return_code = nil
	local result = nil
	if is_last then
		for _, volume_group in ipairs( data.volume_groups ) do
			if volume_group.name == volume_group_name then
				lvm.VolumeGroup.disable( volume_group )
				for _, physical_volume in ipairs( volume_group.physical_volumes ) do
					lvm.PhysicalVolume.prepare( physical_volume.device )
				end
			end
		end
	else
		return_code, result = pcall(
			lvm.LogicalVolume.remove, {
				volume_group = { name = volume_group_name },
				name = logical_volume_name
			}
		)
		if not return_code then
			return index_with_error( i18n("Failed to remove logical volume") .. ": " .. result )
		end

	end

	return index_with_error( message_error )
end

local function find_lv_by_name_and_vg_name( lv_name, vg_name, logical_volumes )
	local logical_volume_found = nil
	for _, logical_volume in pairs( logical_volumes ) do
		if logical_volume.name == lv_name and
		   logical_volume.volume_group == vg_name then
			logical_volume_found = logical_volume
		end
	end
	assert( logical_volume_found, "unable to find original logical volume" )
	return logical_volume_found
end

local function lvm_logical_volume_resize( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local tmp = parse_inputs_by_re( inputs, {"^submit_logical_volume_resize.(",hashre,").lv(",hashre,")"} )
	assert( tmp, "unable to parse out volume group's and logical volume's names" )
	local volume_group_name_hash = tmp[1]
	local logical_volume_name_hash = tmp[2]
	local volume_group_name = find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	local logical_volume_name = find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )

	local physical_volume = common.search_attr(
		data.physical_volumes,
		"volume_group",
		volume_group_name
	)[1]
	physical_volume_bounds_check(
		physical_volume,
		common.search_attr(
			data.logicals,
			"device",
			physical_volume.device
		)[1].size
	)

	local logical_volume_size = inputs[
		"logical_volume_resize_slider_size-" ..
		volume_group_name_hash .. "-" ..
		logical_volume_name_hash
	]
	logical_volume_size = tonumber( logical_volume_size )
	assert( common.is_positive( logical_volume_size ),
	        "incorrect non-positive logical volume's size" )

	local logical_volume_found = find_lv_by_name_and_vg_name(
		logical_volume_name,
		volume_group_name,
		data.logical_volumes
	)

	local return_code, result = pcall(
		lvm.LogicalVolume.resize, {
			volume_group = { name = volume_group_name },
			name = logical_volume_name,
			size = logical_volume_found.size
		},
		logical_volume_size
	)
	if not return_code then
		return index_with_error( i18n("Failed to resize logical volume") .. ": " .. result )
	end

	return_code, result = pcall( scst.Daemon.apply )
	if not return_code then
		return index_with_error( i18n("Failed to apply iSCSI configuration") .. ": " .. result )
	end

	return index_with_error( message_error )
end

local function lvm_logical_volume_snapshot_add( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local tmp = parse_inputs_by_re( inputs, {"^submit_logical_volume_snapshot_add.lvd(",hashre,").(",hashre,")"} )
	assert( tmp, "unable to parse out volume group's and logical volume's names" )
	local volume_group_name_hash = tmp[1]
	local logical_volume_name_hash = tmp[2]
	local volume_group_name = find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	local logical_volume_name = find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )

	local physical_volume = common.search_attr(
		data.physical_volumes,
		"volume_group",
		volume_group_name
	)[1]
	physical_volume_bounds_check(
		physical_volume,
		common.search_attr(
			data.logicals,
			"device",
			physical_volume.device
		)[1].size
	)

	local snapshot_size = inputs[
		"new_snapshot_slider_size-" ..
		volume_group_name_hash .. "-" ..
		logical_volume_name_hash
	]
	snapshot_size = tonumber( snapshot_size )
	assert( common.is_positive( snapshot_size ),
	        "incorrect non-positive snapshot's size" )

	local return_code, result = pcall(
		lvm.LogicalVolume.snapshot, {
			name = logical_volume_name,
			device = "/dev/" .. volume_group_name .. "/" .. logical_volume_name
		},
		snapshot_size
	)
	if not return_code then
		message_error = i18n("Failed to create snapshot") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function lvm_logical_volume_snapshot_resize( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local tmp = parse_inputs_by_re( inputs, {"^submit_logical_volume_snapshot_resize.(",hashre,").(",hashre,")"} )
	assert( tmp, "unable to parse out volume group's and logical volume's names, original snapshot's size" )
	local volume_group_name_hash = tmp[1]
	local logical_volume_name_hash = tmp[2]
	local volume_group_name = find_volume_group_name_in_data_by_hash( volume_group_name_hash, data )
	local logical_volume_name = find_logical_volume_name_in_data_by_hash( logical_volume_name_hash, data )

	local physical_volume = common.search_attr(
		data.physical_volumes,
		"volume_group",
		volume_group_name
	)[1]
	physical_volume_bounds_check(
		physical_volume,
		common.search_attr(
			data.logicals,
			"device",
			physical_volume.device
		)[1].size
	)

	local snapshot_size_new = inputs[
		"logical_volume_snapshot_resize_slider_size-" ..
		volume_group_name_hash .. "-" ..
		logical_volume_name_hash
	]
	snapshot_size_new = tonumber( snapshot_size_new )
	assert( common.is_positive( snapshot_size_new ),
	        "incorrect non-positive snapshot's size" )

	local snapshot_found = find_lv_by_name_and_vg_name(
		logical_volume_name,
		volume_group_name,
		data.logical_volumes
	)

	if snapshot_size_new < snapshot_found.size then
		return index_with_error( i18n("Snapshot size has to be bigger than it's current size") )
	end

	local return_code, result = pcall(
		lvm.Snapshot.resize, {
			volume_group = { name = volume_group_name },
			size = snapshot_found.size,
			name = logical_volume_name
		},
		snapshot_size_new
	)
	if not return_code then
		return index_with_error( i18n("Failed to resize snapshot") .. ": " .. result )
	end

	return_code, result = pcall( scst.Daemon.apply )
	if not return_code then
		return index_with_error( i18n("Failed to apply iSCSI configuration") .. ": " .. result )
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
	local access_pattern_writethrough = inputs[ "access_pattern_new-writethrough" ]

	local access_pattern_attributes = {
		name = access_pattern_name,
		targetdriver = access_pattern_targetdriver,
		lun = access_pattern_lun,
		enabled = access_pattern_enabled,
		readonly = access_pattern_readonly,
		writethrough = access_pattern_writethrough
	}

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
	return find_by_hash(
		access_pattern_section_name_hash,
		common.keys( common.unique_keys( "section_name", scst.AccessPattern.list() ) )
	)
end

local function scst_access_pattern_delete( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local access_pattern_section_name_hash = parse_inputs_by_re( inputs, {"^submit_access_pattern_delete.(",hashre,")"} )
	assert( access_pattern_section_name_hash,
	        "unable to parse out section's name" )
	local access_pattern_section_name = find_access_pattern_section_name_by_hash( access_pattern_section_name_hash )

	local return_code, result = pcall(
		scst.AccessPattern.delete,
		scst.AccessPattern.find_by_section_name( access_pattern_section_name )
	)
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

	local access_pattern_section_name_hash = parse_inputs_by_re( inputs, {"^submit_access_pattern_bind.(",hashre,")"} )
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

	local access_pattern = scst.AccessPattern.find_by_section_name( access_pattern_section_name )

	if access_pattern.lun ~= 0 then
		local lun0_exists = false
		for _, ap in ipairs( scst.AccessPattern.list() ) do
			if ap.filename == logical_volume_device and ap.lun == 0 then
				lun0_exists = true
			end
		end
		if not lun0_exists then
			return index_with_error( i18n("AccessPattern with LUN0 has to be binded first") )
		end
	end

	local return_code, result = pcall(
		scst.AccessPattern.bind,
		access_pattern,
		logical_volume_device
	)
	if not return_code then
		return index_with_error( i18n("Failed to bind access pattern") .. ": " .. result )
	end

	return_code, result = pcall( scst.Daemon.apply )
	if return_code then
		return_code, result = pcall( caching.apply )
		if not return_code then
			message_error = i18n("Failed to apply caching policies") .. ": " .. result
		end
	else
		message_error = i18n("Failed to apply iSCSI configuration") .. ": " .. result
		scst.AccessPattern.unbind( scst.AccessPattern.find_by_name( access_pattern.name ) )
		scst.Daemon.apply()
	end

	return index_with_error( message_error )
end

local function scst_access_pattern_unbind( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local access_pattern_section_name_hash = parse_inputs_by_re( inputs, {"^submit_access_pattern_unbind.(",hashre,")"} )
	assert( access_pattern_section_name_hash,
	        "unable to parse out section's name" )
	local access_pattern_section_name = find_access_pattern_section_name_by_hash( access_pattern_section_name_hash )

	local return_code, result = pcall(
		scst.AccessPattern.unbind,
		scst.AccessPattern.find_by_section_name( access_pattern_section_name )
	)
	if not return_code then
		return index_with_error( i18n("Failed to unbind access pattern") .. ": " .. result )
	end

	return_code, result = pcall( scst.Daemon.apply )
	if not return_code then
		index_with_error( i18n("Failed to apply iSCSI configuration") .. ": " .. result )
	end

	return_code, result = pcall( caching.apply )
	if not return_code then
		index_with_error( i18n("Failed to apply caching policies") .. ": " .. result )
	end

	return index_with_error( message_error )
end

local function scst_access_pattern_edit( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local access_pattern_section_name_hash = parse_inputs_by_re( inputs, {"^submit_access_pattern_edit.(",hashre,")"} )
	assert( access_pattern_section_name_hash, "unable to parse out section's name" )
	local access_pattern_section_name = find_access_pattern_section_name_by_hash( access_pattern_section_name_hash )
	local access_pattern = scst.AccessPattern.find_by_section_name( access_pattern_section_name )

	local access_pattern_name = inputs[ "access_pattern_edit-name-" .. access_pattern_section_name_hash ]
	if access_pattern_name == "" then
		return index_with_error( i18n("Access pattern's name is not set") )
	end

	if access_pattern_name ~= access_pattern.name and
	   scst.AccessPattern.find_by( "name", access_pattern_name ) then
		return index_with_error( i18n("Access pattern's name already exists") )
	end

	local access_pattern_lun = inputs[ "access_pattern_edit-lun-" .. access_pattern_section_name_hash ]
	access_pattern_lun = tonumber( access_pattern_lun )
	assert( common.is_number( access_pattern_lun ), "unable to parse out numeric LUN" )

	local access_pattern_targetdriver = inputs[ "access_pattern_edit-targetdriver-" .. access_pattern_section_name_hash ]
	local access_pattern_enabled = inputs[ "access_pattern_edit-enabled-" .. access_pattern_section_name_hash ]
	local access_pattern_readonly = inputs[ "access_pattern_edit-readonly-" .. access_pattern_section_name_hash ]
	local access_pattern_writethrough = inputs[ "access_pattern_edit-writethrough-" .. access_pattern_section_name_hash ]
	access_pattern_attributes = {
		section_name = access_pattern.section_name,
		name = access_pattern_name,
		targetdriver = access_pattern_targetdriver,
		lun = access_pattern_lun,
		enabled = access_pattern_enabled,
		readonly = access_pattern_readonly,
		writethrough = access_pattern_writethrough
	}

	local return_code, result = pcall(
		scst.AccessPattern.save,
		access_pattern_attributes
	)
	if not return_code then
		message_error = i18n("Failed to save config") .. ": " .. result
	end
	return index_with_error( message_error )
end

local function find_logical_volume_device_in_data_by_hash( logical_volume_device_hash, data )
	return find_by_hash(
		logical_volume_device_hash,
		common.keys( common.unique_keys( "device", data.logical_volumes ) )
	)
end

local function scst_auth_credential_add( inputs, data )
	local i18n = luci.i18n.translate
	local message_error = nil

	local logical_volume_device_hash = parse_inputs_by_re( inputs, {"^submit_auth_credential_add.(",hashre,")"} )
	assert( logical_volume_device_hash, "unable to parse out logical volume's device" )
	local logical_volume_device = find_logical_volume_device_in_data_by_hash( logical_volume_device_hash, data )

	local auth_credential_username = inputs[ "new_auth_credential_username-" .. logical_volume_device_hash ]
	if auth_credential_username == "" then
		return index_with_error( i18n("Username is not set") )
	end
	if not scst.AuthCredential.username_is_valid( auth_credential_username ) then
		return index_with_error( i18n("Invalid username") )
	end
	for _, auth_credential in ipairs( scst.AuthCredential.list_for( logical_volume_device ) ) do
		if auth_credential.username == auth_credential_username then
			return index_with_error( i18n("Such username already exists in current logical volume") )
		end
	end

	local auth_credential_password = inputs[ "new_auth_credential_password-" .. logical_volume_device_hash ]
	if #auth_credential_password < 12 then
		return index_with_error( i18n("Password must not be less than 12 characters long") )
	end

	local return_code, result = pcall(
		scst.AuthCredential.new, {}, {
			username = auth_credential_username,
			password = auth_credential_password,
			filename = logical_volume_device
	} )
	if not return_code then
		return index_with_error( i18n("Failed to create authentication credential") .. ": " .. result )
	end

	return_code, result = pcall( scst.AuthCredential.save, result )
	if not return_code then
		message_error = i18n("Failed to save config") .. ": " .. result
	end

	return_code, result = pcall( scst.Daemon.apply )
	if not return_code then
		index_with_error( i18n("Failed to apply iSCSI configuration") .. ": " .. result )
		scst.AuthCredential.delete_by_username_and_filename( auth_credential_username, logical_volume_device )
		scst.Daemon.apply()
	end

	return index_with_error( message_error )
end

local function find_auth_credential_section_name_by_hash( auth_credential_section_name_hash )
	return find_by_hash(
		auth_credential_section_name_hash,
		common.keys( common.unique_keys( "section_name", scst.AuthCredential.list() ) )
	)
end

local function scst_auth_credential_delete( inputs )
	local i18n = luci.i18n.translate
	local message_error = nil

	local auth_credential_section_name_hash = parse_inputs_by_re( inputs, {"^submit_auth_credential_delete.(",hashre,")"} )
	assert( auth_credential_section_name_hash,
	        "unable to parse out section's name" )
	local auth_credential_section_name = find_auth_credential_section_name_by_hash( auth_credential_section_name_hash )

	local return_code, result = pcall(
		scst.AuthCredential.delete,
		scst.AuthCredential.find_by_section_name( auth_credential_section_name )
	)
	if not return_code then
		index_with_error( i18n("Failed to delete authentication credential") .. ": " .. result )
	end

	return_code, result = pcall( scst.Daemon.apply )
	if not return_code then
		index_with_error( i18n("Failed to apply iSCSI configuration") .. ": " .. result )
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
		raidlevels = einarc.Adapter.raidlevels,
		message_error = message_error } )
end

local function decoded_inputs( inputs )
	local new_inputs = {}
	for k, v in pairs( inputs ) do
		new_inputs[ luci.http.protocol.urldecode( k ) ] = v
	end
	return new_inputs
end

-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2
local function b64decode( data )
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	data = string.gsub( data, '[^'..b..'=]', '' )

	return ( data:gsub( ".", function( x )
		if( x == "=" ) then return "" end
		local r, f = "", ( b:find( x ) - 1)
		for i = 6, 1, -1 do r = r .. ( f % 2^i - f % 2^( i - 1 ) > 0 and "1" or "0" ) end
		return r;
	end ):gsub( "%d%d%d?%d?%d?%d?%d?%d?", function( x )
		if( #x ~= 8 ) then return "" end
		local c = 0
		for i = 1, 8 do c = c + ( x:sub( i, i ) == "1" and 2^( 8 - i ) or 0 ) end
		return string.char( c )
	end ) )
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
		logical_physical_detach = function() einarc_logical_physical_detach( inputs, data ) end,
		logical_flashcache_bind = function() einarc_logical_flashcache_bind( inputs, data ) end,
		logical_flashcache_unbind = function() einarc_logical_flashcache_unbind( inputs, data ) end,
		logical_grow = function() einarc_logical_grow( inputs, get( "san.grow_physical_id" ), data ) end,
		logical_volume_add = function() lvm_logical_volume_add( inputs, data ) end,
		logical_volume_remove = function() lvm_logical_volume_remove( inputs, data ) end,
		logical_volume_resize = function() lvm_logical_volume_resize( inputs, data ) end,
		logical_volume_snapshot_add = function() lvm_logical_volume_snapshot_add( inputs, data ) end,
		logical_volume_snapshot_resize = function() lvm_logical_volume_snapshot_resize( inputs, data ) end,
		access_pattern_new = function() scst_access_pattern_new( inputs ) end,
		access_pattern_delete = function() scst_access_pattern_delete( inputs ) end,
		access_pattern_bind = function() scst_access_pattern_bind( inputs ) end,
		access_pattern_unbind = function() scst_access_pattern_unbind( inputs ) end,
		access_pattern_edit = function() scst_access_pattern_edit( inputs ) end,
		auth_credential_add = function() scst_auth_credential_add( inputs, data ) end,
		auth_credential_delete = function() scst_auth_credential_delete( inputs ) end
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
