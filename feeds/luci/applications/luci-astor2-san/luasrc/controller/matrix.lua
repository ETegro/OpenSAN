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

local M = {}

common = require( "astor2.common" )
einarc = require( "astor2.einarc" )
lvm = require( "astor2.lvm" )
scst = require( "astor2.scst" )

mime = require( "mime" )

function M.gcd( x, y )
	if y == 0 then return math.abs( x ) end
	return M.gcd( y, x % y )
end

function M.lcm( x, y )
	if x == 0 and y == 0 then return 0 end
	return math.abs( x * y ) / M.gcd( x, y )
end

function M.overall( data )
	local physicals = data.physicals or {}
	local logicals = data.logicals or {}
	local physicals_free = common.deepcopy( physicals )
	local matrix = {}
	local current_line = 1

	-- Sort logicals
	local logical_ids = common.keys( logicals )
	table.sort( logical_ids )

	for _,logical_id in ipairs( logical_ids ) do
		local logical = logicals[ logical_id ]
		local physicals_quantity = #common.keys( logical.physicals )
		local logical_volumes_quantity = #common.keys( logical.logical_volumes or {} )
		local lines_quantity = physicals_quantity
		if logical_volumes_quantity ~= 0 then
			lines_quantity = M.lcm(
				physicals_quantity,
				logical_volumes_quantity
			)
		end
		local future_line = current_line + lines_quantity

		-- Fillup an empty lines
		for i = current_line, future_line - 1 do
			matrix[ i ] = {}
		end

		-- Fillup logical
		matrix[ current_line ].logical = logical
		matrix[ current_line ].logical.rowspan = lines_quantity

		-- Fillup physicals
		for physical_id, physical in pairs( logical.physicals ) do
			if physicals[ physical_id ].state == tostring( logical_id ) then
				physicals[ physical_id ].state = "allocated"
			end
			logical.physicals[ physical_id ] = physicals[ physical_id ]
			physicals_free[ physical_id ] = nil
		end
		local physical_rowspan = lines_quantity / physicals_quantity
		for i, physical in ipairs( einarc.Physical.sort( logical.physicals ) ) do
			local offset = current_line + ( i - 1 ) * physical_rowspan
			matrix[ offset ].physical = physical
			matrix[ offset ].physical.rowspan = physical_rowspan
		end

		-- Fillup logical volumes
		local logical_volume_names = common.keys( logical.logical_volumes or {} )
		table.sort( logical_volume_names )
		local logical_volume_rowspan = lines_quantity / logical_volumes_quantity
		for i, logical_volume_name in ipairs( logical_volume_names ) do
			local offset = current_line + ( i - 1 ) * logical_volume_rowspan
			matrix[ offset ].logical_volume = logical.logical_volumes[ logical_volume_name ]
			matrix[ offset ].logical_volume.rowspan = logical_volume_rowspan
		end

		current_line = future_line
	end

	for _, physical in pairs( einarc.Physical.sort( physicals_free ) ) do
		matrix[ current_line ] = { physical = physical }
		matrix[ current_line ].physical.rowspan = 1
		current_line = current_line + 1
	end

	return matrix
end

function M.mib2tib( size )
	return string.sub( string.format( "%0.3f", size / 2^20 ), 1, -2 )
end

local function check_highlights_attribute( obj )
	local highlights = {
		left = false,
		top = false,
		right = false,
		bottom = false
	}
	if not obj.highlight then
		obj.highlight = common.deepcopy( highlights )
	end
	return obj
end

function M.filter_borders_highlight( matrix )
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.physical then
			lines[ current_line ].physical = check_highlights_attribute( lines[ current_line ].physical )
		end

		if line.logical then
			lines[ current_line ].logical = check_highlights_attribute( lines[ current_line ].logical )

			lines[ current_line ].physical.highlight.top = true
			lines[ current_line ].physical.highlight.left = true
			lines[ current_line ].logical.highlight.top = true

			local logical_volumes_quantity = #common.keys( line.logical.logical_volumes or {} )
			local logical_volume_rowspan = 0
			if logical_volumes_quantity ~= 0 then
				logical_volume_rowspan = line.logical_volume.rowspan
			end
			local physical_rowspan = line.physical.rowspan
			if logical_volumes_quantity == 0 then
				lines[ current_line ].logical.highlight.right = true
			else
				lines[ current_line ].logical_volume = check_highlights_attribute( lines[ current_line ].logical_volume )
				lines[ current_line ].logical_volume.highlight.top = true
				lines[ current_line ].logical_volume.highlight.right = true
			end

			local future_line = current_line + line.logical.rowspan
			for i = current_line, future_line - 1, physical_rowspan do
				lines[ i ].physical = check_highlights_attribute( lines[ i ].physical )
				lines[ i ].physical.highlight.left = true
			end
			if logical_volumes_quantity ~= 0 then
				for i = current_line, future_line - 1, logical_volume_rowspan do
					lines[ i ].logical_volume = check_highlights_attribute( lines[ i ].logical_volume )
					lines[ i ].logical_volume.highlight.right = true
				end
			end
			lines[ future_line - physical_rowspan ].physical.highlight.bottom = true
			lines[ current_line ].logical.highlight.bottom = true
			if logical_volumes_quantity ~= 0 then
				lines[ future_line - logical_volume_rowspan ].logical_volume.highlight.bottom = true
			end
		end
	end
	return matrix
end

function M.filter_alternation_border_colors( matrix, colors_array )
	if not colors_array then
		colors_array = { "black", "blue", "green", "orange", "red", "yellow" }
	end
	local color_number = 1
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		local color = colors_array[ color_number ]
		if line.logical then
			if color_number == #colors_array then
				color_number = 1
			else
				color_number = color_number + 1
			end
			lines[ current_line ].logical.highlight.color = color
			for _, physical in pairs( line.logical.physicals ) do
				physical.highlight.color = color
			end
			if line.logical.logical_volumes then
				for _, logical_volumes in pairs( line.logical.logical_volumes ) do
					logical_volumes.highlight.color = color
				end
			end
		end
	end
	return matrix
end

function M.filter_volume_group_percentage( matrix )
	local lines = matrix.lines
	for _, line in ipairs( lines ) do
		if line.logical_volume then
			local percentage = math.ceil( 100 * line.logical_volume.volume_group.allocated /
			                                    line.logical_volume.volume_group.total )
			-- Check for zero devision returning infinity
			if percentage == math.huge then percentage = 0 end
			line.logical_volume.volume_group.percentage = percentage
		end
	end
	return matrix
end

local function filter_mib2tib( matrix )
	local lines = matrix.lines
	for _, line in ipairs( lines ) do
		if line.physical then
			line.physical.size_mib = line.physical.size
			line.physical.size = M.mib2tib( line.physical.size )
		end
		if line.logical then
			line.logical.capacity_mib = line.logical.capacity
			line.logical.capacity = M.mib2tib( line.logical.capacity )
			line.logical.volume_group.allocated_mib = line.logical.volume_group.allocated
			line.logical.volume_group.allocated = M.mib2tib( line.logical.volume_group.allocated )
			line.logical.volume_group.total_mib = line.logical.volume_group.total
			line.logical.volume_group.total = M.mib2tib( line.logical.volume_group.total )
		end
		if line.logical_volume then
			line.logical_volume.size_mib = line.logical_volume.size
			line.logical_volume.size = M.mib2tib( line.logical_volume.size )
		end
	end
	return matrix
end

local function filter_add_logical_id_to_physical( matrix )
	local lines = matrix.lines
	for _, line in ipairs( lines ) do
		if line.logical then
			for _, physical in pairs( line.logical.physicals ) do
				physical.logical_id = line.logical.id
			end
		end
	end
	return matrix
end

function M.filter_add_access_patterns( matrix, access_patterns )
	access_patterns = access_patterns or scst.AccessPattern.list()
	local access_patterns_named_hash = common.unique_keys( "name", access_patterns )
	local access_patterns_names = common.keys( access_patterns_named_hash  )
	table.sort( access_patterns_names )

	local lines = matrix.lines
	-- Fillup matrix with AccessPatterns
	for current_line, access_pattern_name in ipairs( access_patterns_names ) do
		access_pattern = access_patterns[ access_patterns_named_hash[ access_pattern_name ][1] ]
		if not lines[ current_line ] then
			lines[ current_line ] = {}
		end
		lines[ current_line ][ "access_pattern" ] = access_pattern
	end

	-- Calculate AccessPatterns-related TD's colspan
	local logical_scope = 0
	for current_line, line in ipairs( lines ) do
		if line.logical then
			local logical_volumes_names = common.keys( line.logical.logical_volumes or {} )
			if #logical_volumes_names > 0 then
				for i = current_line, current_line -1 + line.logical.logical_volumes[ logical_volumes_names[1] ].rowspan * #logical_volumes_names do
					if lines[ i ].access_pattern then
						lines[ i ].access_pattern.colspan = 1
					end
				end
			end
			for i = current_line, current_line + line.logical.rowspan -1 do
				if lines[ i ].access_pattern and not lines[ i ].access_pattern.colspan then
					lines[ i ].access_pattern.colspan = 2
				end
			end
			logical_scope = line.logical.rowspan
		end
		if line.access_pattern and logical_scope == 0 then
			-- We are outside logical's scope
			if line.physical then
				lines[ current_line ].access_pattern.colspan = 3
			else
				lines[ current_line ].access_pattern.colspan = 4
			end
		end
		if logical_scope > 0 then
			logical_scope = logical_scope - 1
		end
	end
	return matrix
end

function M.filter_calculate_hotspares( matrix )
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.physical and line.physical.state == "free" then
			local hotspare_availability = {}
			local hotspare_minimal_sizes = {}
			for _, line_inner in ipairs( lines ) do
				if line_inner.logical and
				not common.is_in_array( line_inner.logical.level,
				                        einarc.RAIDLEVELS_HOTSPARE_NONCOMPATIBLE ) then
					local minimal_size = math.huge
					for _, physical in pairs( line_inner.logical.physicals ) do
						if physical.size < minimal_size then
							minimal_size = physical.size
						end
					end
					if line.physical.size >= minimal_size then
						hotspare_availability[ #hotspare_availability + 1 ] = line_inner.logical.id
						hotspare_minimal_sizes[ line_inner.logical.id ] = minimal_size
					end
				end
			end
			if #hotspare_availability == 0 then
				lines[ current_line ].physical.hotspare_availability = nil
			else
				table.sort( hotspare_availability )
				lines[ current_line ].physical.hotspare_availability = hotspare_availability
				lines[ current_line ].physical.hotspare_minimal_sizes = hotspare_minimal_sizes
			end
		end
	end
	return matrix
end

function filter_serialize( matrix )
	local serializer = luci.util.serialize_data
	matrix.serialized_physicals = serializer( matrix.physicals )
	matrix.serialized_logicals = serializer( matrix.logicals )
	matrix.serialized_physical_volumes = serializer( matrix.physical_volumes )
	matrix.serialized_volume_groups = serializer( matrix.volume_groups )
	matrix.serialized_logical_volumes = serializer( matrix.logical_volumes )
	return matrix
end

local function b64encode( data )
	return (mime.b64( data ))
end

function filter_base64encode( matrix )
	matrix.serialized_physicals = b64encode( matrix.serialized_physicals )
	matrix.serialized_logicals = b64encode( matrix.serialized_logicals )
	matrix.serialized_physical_volumes = b64encode( matrix.serialized_physical_volumes )
	matrix.serialized_volume_groups = b64encode( matrix.serialized_volume_groups )
	matrix.serialized_logical_volumes = b64encode( matrix.serialized_logical_volumes )
	return matrix
end

local function logical_volume_group( logical, volume_groups )
	for _, volume_group in ipairs( volume_groups ) do
		if volume_group.physical_volumes[1].device == logical.device then
			return volume_group
		end
	end
end

local function snapshots_to_outer( logical_volumes )
	for _, logical_volume in pairs( logical_volumes ) do
		if logical_volume.snapshots then
			for _, snapshot in ipairs( logical_volume.snapshots ) do
				logical_volumes[ snapshot.name ] = snapshot
			end
		end
	end
	return logical_volumes
end

local function logical_logical_volumes( logical, logical_volumes )
	local logical_volumes_needed = {}
	for _, logical_volume in ipairs( logical_volumes ) do
		if logical_volume.volume_group.physical_volumes[1].device == logical.device then
			logical_volumes_needed[ logical_volume.name ] = logical_volume
		end
	end
	return snapshots_to_outer( logical_volumes_needed )
end

function M.caller()
	local logicals = einarc.Logical.list()
	local physicals = einarc.Physical.list()
	local logicals_for_serialization = {}
	local physical_volumes = lvm.PhysicalVolume.list()
	local volume_groups = lvm.VolumeGroup.list( physical_volumes )
	local logical_volumes = lvm.LogicalVolume.list( volume_groups )

	for logical_id, logical in pairs( logicals ) do
		logicals[ logical_id ]:physical_list()
		logicals[ logical_id ]:progress_get()
		logicals_for_serialization[ logical_id ] = common.deepcopy( logicals[ logical_id ] )
		logicals[ logical_id ].logical_volumes = logical_logical_volumes( logical, logical_volumes )
		logicals[ logical_id ].volume_group = logical_volume_group( logical, volume_groups )
	end

	-- Some workarounds to prevent recursion during serialization
	local logical_volumes_for_serialization = common.deepcopy( logical_volumes )
	logical_volumes_for_serialization = snapshots_to_outer( logical_volumes_for_serialization )
	for _, logical_volume in pairs( logical_volumes_for_serialization ) do
		logical_volume.volume_group = logical_volume.volume_group.name
		logical_volume.logical_volume = nil
		if logical_volume.snapshots then
			logical_volume.snapshots = {}
		end
	end

	local matrix = {
		lines = M.overall( {
			physicals = physicals,
			logicals = logicals } ),
		logicals = logicals_for_serialization,
		physicals = physicals,
		physical_volumes = physical_volumes,
		volume_groups = volume_groups,
		logical_volumes = logical_volumes_for_serialization
	}
	local FILTERS = {
		M.filter_borders_highlight,
		M.filter_alternation_border_colors,
		M.filter_volume_group_percentage,
		filter_add_logical_id_to_physical,
		M.filter_add_access_patterns,
		M.filter_calculate_hotspares,
		filter_mib2tib,
		filter_serialize,
		filter_base64encode
		-- filter_highlight_snapshots
		-- filter_overall_fields_counter (for hiding)
	}
	for _,filter in ipairs( FILTERS ) do
		matrix = filter( matrix )
	end
	return matrix
end

return M
