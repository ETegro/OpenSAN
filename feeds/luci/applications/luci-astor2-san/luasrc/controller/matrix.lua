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

local M = {}

common = require( "astor2.common" )
einarc = require( "astor2.einarc" )
lvm = require( "astor2.lvm" )
scst = require( "astor2.scst" )

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
	local access_patterns = data.access_patterns or {}
	local sessions = data.sessions or {}
	local physicals_free = common.deepcopy( physicals )
	local matrix = {}
	local current_line = 1

	-- Sort logicals
	local logical_ids = common.keys( logicals )
	table.sort( logical_ids )

	-- Sessions filling
	for section_name,access_pattern_i in pairs( common.unique_keys( "section_name", access_patterns ) ) do
		local ap_sessions = sessions[ section_name ] or {}
		local session_names = common.keys( ap_sessions )
		local access_pattern = access_patterns[ access_pattern_i[1] ]
		if #session_names > 0 then
			table.sort( session_names )
			access_pattern.sessions_avail = {}
			for _,session_name in ipairs( session_names ) do
				access_pattern.sessions_avail[ #access_pattern.sessions_avail + 1 ] = ap_sessions[ session_name ]
			end
		end
	end

	for _,logical_id in ipairs( logical_ids ) do
		local logical = logicals[ logical_id ]

		-- Fill up cached physicals
		if logical.cached_by then
			logical.physicals[ logical.cached_by ] = physicals[ logical.cached_by ]
		end

		local physicals_quantity = #common.keys( logical.physicals )
		local logical_volumes_quantity = #common.keys( logical.logical_volumes or {} )
		local lines_quantity = physicals_quantity

		-- Bind access patterns to logical volumes and find maximal
		-- patterns quantity in single logical volume
		local access_patterns_quantity_max = 1
		local sessions_quantity_max = 1
		for logical_volume_device, logical_volume in pairs( logical.logical_volumes or {} ) do
			local quantity = 0
			for _, access_pattern in ipairs( access_patterns ) do
				if access_pattern.filename == logical_volume_device then
					if not logical_volume.access_patterns then
						logical_volume.access_patterns = {}
					end
					logical_volume.access_patterns[ access_pattern.name ] = access_pattern
					quantity = quantity + 1
					if access_pattern.sessions_avail and #access_pattern.sessions_avail > 0 then
						sessions_quantity_max = M.lcm(
							#access_pattern.sessions_avail,
							sessions_quantity_max
						)
					end
				end
			end
			if quantity ~= 0 then
				-- Maximum number of possible divisible without reminder number
				-- of APs in LV is LCM between each of them
				access_patterns_quantity_max = M.lcm(
					quantity,
					access_patterns_quantity_max
				)
			end
		end

		-- Overall lines quantity will be LCM( PVs, APs*LVs*Ss )
		if logical_volumes_quantity ~= 0 then
			lines_quantity = M.lcm(
				physicals_quantity,
				logical_volumes_quantity * access_patterns_quantity_max * sessions_quantity_max
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
			if physicals[ physical_id ] then
				if physicals[ physical_id ].state == tostring( logical_id ) then
					physicals[ physical_id ].state = "allocated"
				end
				physicals_free[ physical_id ] = nil
			else
				-- We have got failed disk
				physicals[ physical_id ] = einarc.Physical:new( {
					id = physical_id,
					model = "unknown",
					revision = "unknown",
					serial = "unknown",
					size = 1,
					state = "failed"
				} )
				physicals[ physical_id ].size = 0
			end
			logical.physicals[ physical_id ] = physicals[ physical_id ]
		end
		local physical_rowspan = lines_quantity / physicals_quantity
		for i, physical in ipairs( einarc.Physical.sort( logical.physicals ) ) do
			local offset = current_line + ( i - 1 ) * physical_rowspan
			matrix[ offset ].physical = physical
			matrix[ offset ].physical.rowspan = physical_rowspan
		end

		-- Fillup logical volumes
		local logical_volume_devices = common.keys( logical.logical_volumes or {} )
		table.sort(
			logical_volume_devices,
			function( a, b )
				local snapshot_regexp = "(.+).%d%d%d%d.%d%d.%d%d.%d%d.%d%d.%d%d"
				local a_snapshot = string.match( a, snapshot_regexp )
				local b_snapshot = string.match( b, snapshot_regexp )

				if a_snapshot == b then return false end
				if a == b_snapshot then return true end
				if a_snapshot and not b_snapshot then return a_snapshot < b end
				if not a_snapshot and b_snapshot then return a < b_snapshot end

				return a < b
			end
		)

		local logical_volume_rowspan = lines_quantity / logical_volumes_quantity
		for i, logical_volume_device in ipairs( logical_volume_devices ) do
			local offset = current_line + ( i - 1 ) * logical_volume_rowspan
			local logical_volume = logical.logical_volumes[ logical_volume_device ]
			matrix[ offset ].logical_volume = logical_volume
			matrix[ offset ].logical_volume.rowspan = logical_volume_rowspan

			if logical_volume.access_patterns then
				local access_pattern_names = common.keys( logical_volume.access_patterns )
				local access_pattern_rowspan = logical_volume_rowspan / #access_pattern_names
				table.sort( access_pattern_names )

				for ap_i = 1, #access_pattern_names do
					local ap_offset = offset + ( ap_i - 1 ) * access_pattern_rowspan
					if not matrix[ ap_offset ] then
						matrix[ ap_offset ] = {}
					end
					matrix[ ap_offset ].access_pattern = logical_volume.access_patterns[ access_pattern_names[ ap_i ] ]
					matrix[ ap_offset ].access_pattern.rowspan = access_pattern_rowspan

					if matrix[ ap_offset ].access_pattern.sessions_avail then
						ap_sessions = matrix[ ap_offset ].access_pattern.sessions_avail
						local session_rowspan = access_pattern_rowspan / #ap_sessions
						for s_i = 1, #ap_sessions do
							local s_offset = ap_offset + ( s_i - 1 ) * session_rowspan
							if not matrix[ s_offset ] then
								matrix[ s_offset ] = {}
							end
							matrix[ s_offset ].session = ap_sessions[ s_i ]
							matrix[ s_offset ].session.rowspan = session_rowspan
						end
					end
				end
			end
		end

		current_line = future_line
	end
	local final_line = current_line

	for _, physical in pairs( einarc.Physical.sort( physicals_free ) ) do
		matrix[ current_line ] = { physical = physical }
		matrix[ current_line ].physical.rowspan = 1
		current_line = current_line + 1
	end

	current_line = final_line
	local access_pattern_names = common.unique_keys( "name", access_patterns )
	local access_pattern_names_sort = common.keys( access_pattern_names )
	table.sort( access_pattern_names_sort )
	for _, access_pattern_name in ipairs( access_pattern_names_sort ) do
		local access_pattern = access_patterns[ access_pattern_names[ access_pattern_name ][1] ]
		if not access_pattern.filename then
			if not matrix[ current_line ] then
				matrix[ current_line ] = {}
			end
			matrix[ current_line ].access_pattern = access_pattern
			if matrix[ current_line ].physical then
				matrix[ current_line ].access_pattern.colspan = 2
				matrix[ current_line ].access_pattern.rowspan = 1
			else
				matrix[ current_line ].access_pattern.colspan = 3
				matrix[ current_line ].access_pattern.rowspan = 1
			end
			current_line = current_line + 1
		end
	end

	return matrix
end

------------------------------------------------------------------------
-- Sizes humanization
------------------------------------------------------------------------
function M.size_round( size )
	return string.format( "%0.0f", tonumber( size ) )
end

function M.mib2tib( size )
	return string.sub( string.format( "%0.3f", tonumber( size ) / 2^20 ), 1, -2 )
end

function M.mib_humanize( size )
	local rules = {
		[ function( size ) return size < 1024 end ] =
			function( size )
				return { value = M.size_round( size ), unit = "MiB" }
			end,
		[ function( size ) return (size < 1024^2) and (size >= 1024) end ] =
			function( size )
				return { value = M.size_round( size / 1024.0 ), unit = "GiB" }
			end,
		[ function( size ) return size >= 1024^2 end ] =
			function( size )
				return { value = M.mib2tib( size ), unit = "TiB" }
			end
	}
	for check, resulter in pairs( rules ) do
		if check( size ) then
			return resulter( size )
		end
	end
	return { value = tostring( size ), unit = "MiB" }
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
					local logical_volume = lines[ i ].logical_volume
					logical_volume = check_highlights_attribute( logical_volume )
					if logical_volume.access_patterns then
						local access_patterns_names = common.keys( logical_volume.access_patterns )
						local access_pattern_rowspan = logical_volume_rowspan / #access_patterns_names
						for ap_i, access_pattern_name in ipairs( access_patterns_names ) do
							local ap_line = i + ( ap_i - 1 ) * access_pattern_rowspan
							local access_pattern = lines[ ap_line ].access_pattern
							check_highlights_attribute( access_pattern )
							access_pattern.highlight.right = true
							if access_pattern.sessions_avail then
								access_pattern.highlight.right = false

								local s_line_last = ap_line + (#access_pattern.sessions_avail - 1) * lines[ ap_line ].session.rowspan
								for s_line=ap_line, s_line_last, lines[ ap_line ].session.rowspan do
									local session = lines[ s_line ].session
									check_highlights_attribute( session )
									session.highlight.right = true
									if s_line == ap_line then
										session.highlight.top = true
									end
									if s_line == s_line_last then
										session.highlight.bottom = true
									end
								end
							end
							if ap_i == 1 then
								access_pattern.highlight.top = true
							end
							if ap_i == #access_patterns_names then
								access_pattern.highlight.bottom = true
							end
						end
						lines[ i ].logical_volume.highlight.right = false
					else
						lines[ i ].logical_volume.highlight.right = true
					end
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
		colors_array = { "green", "blue" }
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
				for _, logical_volume in pairs( line.logical.logical_volumes ) do
					logical_volume.highlight.color = color
					if logical_volume.access_patterns then
						for _, access_pattern in pairs( logical_volume.access_patterns ) do
							access_pattern.highlight.color = color
							if access_pattern.sessions_avail then
								for _, session in ipairs( access_pattern.sessions_avail ) do
									session.highlight.color = color
								end
							end
						end
					end
				end
			end
		end
	end
	return matrix
end

function M.filter_highlight_snapshots( matrix, colors_array )
	if not colors_array then
		colors_array = { "normal_color", "light_color" }
	end
	local color_number = 1
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		local color = colors_array[ color_number ]
		if line.logical_volume and
		   not line.logical_volume.is_snapshot() then
			if color_number == #colors_array then
				color_number = 1
			else
				color_number = color_number + 1
			end
			lines[ current_line ].logical_volume.highlight.background_color = color
			if #line.logical_volume.snapshots ~= 0 then
				for _, snapshot in ipairs( line.logical_volume.snapshots ) do
					snapshot.highlight.background_color = color
				end
			end
		end
	end
	return matrix
end

function M.filter_highlight_accesss_patterns( matrix )
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.logical_volume and
		   not line.logical_volume.is_snapshot() then
			if line.logical_volume.access_patterns then
				for _, access_pattern in pairs( line.logical_volume.access_patterns ) do
					access_pattern.highlight.background_color = line.logical_volume.highlight.background_color
				end
			end
			if #line.logical_volume.snapshots ~= 0 then
				for _, snapshot in ipairs( line.logical_volume.snapshots ) do
					if snapshot.access_patterns then
						for _, access_pattern in pairs( snapshot.access_patterns ) do
							access_pattern.highlight.background_color = snapshot.highlight.background_color
						end
					end
				end
			end
		end
	end
	return matrix
end

function M.filter_highlight_sessions( matrix, colors_array )
	if not colors_array then
		colors_array = { "normal_color", "light_color" }
	end
	local color_number = 1
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		local color = colors_array[ color_number ]
		if line.session then
			if color_number == #colors_array then
				color_number = 1
			else
				color_number = color_number + 1
			end
			lines[ current_line ].session.highlight.background_color = color
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

local function filter_mib_humanize( matrix )
	local lines = matrix.lines
	for _, line in ipairs( lines ) do
		if line.physical then
			line.physical.size_mib = line.physical.size
			line.physical.size = M.mib_humanize( line.physical.size )
		end
		if line.logical then
			line.logical.capacity_mib = line.logical.capacity
			line.logical.capacity = M.mib_humanize( line.logical.capacity )
			if line.logical.volume_group then
				line.logical.volume_group.allocated_mib = line.logical.volume_group.allocated
				line.logical.volume_group.allocated = M.mib_humanize( line.logical.volume_group.allocated )
			else
				line.logical.volume_group = {}
				line.logical.volume_group.extent = lvm.VolumeGroup.PE_DEFAULT_SIZE
				line.logical.volume_group.allocated_mib = 0
				line.logical.volume_group.allocated = M.mib_humanize( 0 )
			end
			line.logical.volume_group.total_mib = lvm.PhysicalVolume.expected_size( line.logical.capacity_mib, lvm.VolumeGroup.PE_DEFAULT_SIZE )
			line.logical.volume_group.total = M.mib_humanize( line.logical.capacity_mib )
		end
		if line.logical_volume then
			line.logical_volume.size_mib = line.logical_volume.size
			line.logical_volume.size = M.mib_humanize( line.logical_volume.size )
		end
	end
	return matrix
end

local function filter_size_round( matrix )
	local lines = matrix.lines
	for _, line in ipairs( lines ) do
		if line.physical then
			line.physical.size_mib = M.size_round( line.physical.size_mib )
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

local function filter_fillup_auth_credentials( matrix )
	local lines = matrix.lines
	for _, line in ipairs( lines ) do
		if line.logical_volume then
			line.logical_volume.auth_credentials = scst.AuthCredential.list_for( line.logical_volume.device )
			local usernames = {}
			for _, auth_credential in ipairs( line.logical_volume.auth_credentials ) do
				usernames[ #usernames + 1 ] = auth_credential.username
			end
			table.sort( usernames )
			local auth_credentials_sorted = {}
			for _, username in ipairs( usernames ) do
				for _, auth_credential in ipairs( line.logical_volume.auth_credentials ) do
					if auth_credential.username == username then
						auth_credentials_sorted[ #auth_credentials_sorted + 1 ] = auth_credential
					end
				end
			end
			if #auth_credentials_sorted == 0 then
				line.logical_volume.auth_credentials = nil
			else
				line.logical_volume.auth_credentials = auth_credentials_sorted
			end
		end
	end
	return matrix
end

function M.filter_deletability_logical( matrix )
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.logical then
			if #common.keys( line.logical.logical_volumes or {} ) == 0 then
				line.logical.deletable = true
			else
				line.logical.deletable = false
			end
		end
	end
	return matrix
end

function M.filter_deletability_logical_volume( matrix )
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.logical_volume then
			if( line.logical_volume.access_patterns ) then
				line.logical_volume.deletable = false
			else
				line.logical_volume.deletable = true
			end
		end
	end
	return matrix
end

function M.filter_resizability_logical_volume( matrix )
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.logical_volume and line.logical_volume.snapshots then
			if( #line.logical_volume.snapshots == 0 ) then
				line.logical_volume.resizable = true
			else
				line.logical_volume.resizable = false
			end
		end
	end
	return matrix
end

function M.filter_unbindability_access_pattern( matrix )
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.access_pattern then
			line.access_pattern.unbindable = true
			if line.access_pattern.lun == 0 then
				for _, inner_line in ipairs( lines ) do
					if inner_line.access_pattern and inner_line.access_pattern.lun ~= 0 and inner_line.access_pattern.filename == line.access_pattern.filename then
						line.access_pattern.unbindable = false
					end
				end
			end
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
					common.is_in_array(
						line_inner.logical.level,
						einarc.Adapter.raidlevels_hotspare_compatible
					) then
					local minimal_size = math.huge
					for _, physical in pairs( line_inner.logical.physicals ) do
						if physical.size < minimal_size then
							minimal_size = physical.size
						end
					end
					if line.physical.size >= minimal_size then
						hotspare_availability[ #hotspare_availability + 1 ] = line_inner.logical.id
						hotspare_minimal_sizes[ line_inner.logical.id ] = tonumber( M.size_round( minimal_size ) )
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

function M.filter_calculate_flashcache( matrix )
	matrix.flashcache = {}
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.logical then
			local cacheable = true
			local message
			if line.logical.state ~= "normal" then
				cacheable = false
				message = 'Array must be in "normal" state'
			end
			if line.logical.logical_volumes then
				for _,logical_volume in pairs( line.logical.logical_volumes ) do
					if logical_volume.access_patterns then
						cacheable = false
						message = 'Unbind all Access patterns'
					end
				end
			end
			if line.logical.cached_by then
				cacheable = false
				message = 'Already cached'
			end
			matrix.flashcache[ line.logical.id ] = { cacheable = cacheable }
			if cacheable == false then
				matrix.flashcache[ line.logical.id ].message = message
			end
		end
	end
	matrix.flashcache_modes = common.keys( einarc.Flashcache.MODES )
	return matrix
end

function M.filter_unbindability_physical_flashcache( matrix )
	local lines = matrix.lines
	for _, main_line in ipairs( lines ) do
		if main_line.logical and main_line.logical.cached_by then
			local unbindable = true
			for _, line in ipairs( lines ) do
				if ( line.logical and line.logical.cached_by ) then
					if line.logical.logical_volumes then
						for _, logical_volume in pairs( line.logical.logical_volumes ) do
							if logical_volume.access_patterns then
								for _, access_pattern in pairs( logical_volume.access_patterns ) do
									if access_pattern then
										unbindable = false
									end
								end
							end
						end
					end
				end
			end
			for _, line in ipairs( lines ) do
				if line.physical and line.physical.id == main_line.logical.cached_by then
					line.physical.unbindable = unbindable
				end
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

-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2
local function b64encode( data )
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	return ( ( data:gsub( ".", function(x)
		local r, b = "", x:byte()
		for i = 8, 1, -1 do r = r .. ( b % 2^i - b % 2^( i - 1 ) > 0 and "1" or "0" ) end
		return r;
	end ) .. "0000" ):gsub( "%d%d%d?%d?%d?%d?", function(x)
		if( #x < 6 ) then return "" end
		local c = 0
		for i = 1, 6 do c = c + ( x:sub( i, i ) == "1" and 2^( 6 - i ) or 0 ) end
		return b:sub( c + 1, c + 1 )
	end ) .. ({ "", '==', "=" })[ #data % 3 + 1 ] )
end

function filter_base64encode( matrix )
	matrix.serialized_physicals = b64encode( matrix.serialized_physicals )
	matrix.serialized_logicals = b64encode( matrix.serialized_logicals )
	matrix.serialized_physical_volumes = b64encode( matrix.serialized_physical_volumes )
	matrix.serialized_volume_groups = b64encode( matrix.serialized_volume_groups )
	matrix.serialized_logical_volumes = b64encode( matrix.serialized_logical_volumes )
	return matrix
end

local function unknown_access_patterns_filename_unbind( access_patterns, logical_volumes )
	for _, access_pattern in ipairs( access_patterns ) do
		if access_pattern.filename then
			local logical_volume_found = false
			for _,logical_volume in ipairs( logical_volumes ) do
				if logical_volume.device == access_pattern.filename then
					logical_volume_found = true
				end
				if logical_volume.snapshots then
					for _,snapshot in ipairs( logical_volume.snapshots ) do
						if snapshot.device == access_pattern.filename then
							logical_volume_found = true
						end
					end
				end
			end
			if not logical_volume_found then
				access_pattern:unbind()
			end
		end
	end
end

local function logical_volume_group( logical, volume_groups )
	for _, volume_group in ipairs( volume_groups ) do
		if volume_group.physical_volumes[1].device == logical.device then
			return volume_group
		end
	end
end

local function snapshots_to_outer( logical_volumes )
	local processed = {}
	for logical_volume_device, logical_volume in pairs( logical_volumes ) do
		processed[ logical_volume_device ] = logical_volume
		if logical_volume.snapshots then
			for _, snapshot in ipairs( logical_volume.snapshots ) do
				processed[ snapshot.device ] = snapshot
			end
		end
	end
	return processed
end

local function logical_logical_volumes( logical, logical_volumes )
	local logical_volumes_needed = {}
	for _, logical_volume in ipairs( logical_volumes ) do
		if logical_volume.volume_group.physical_volumes[1].device == logical.device then
			logical_volumes_needed[ logical_volume.device ] = logical_volume
		end
	end
	return snapshots_to_outer( logical_volumes_needed )
end

local function logical_states_sanity_check( logicals, physicals )
	local logicals_failed = {}
	for logical_id, logical in pairs( logicals ) do
		local unexistent_drives = 0
		for _, physical_in_logical in ipairs( logical.drives ) do
			if physicals[ physical_in_logical ] == nil then
				unexistent_drives = unexistent_drives + 1
			end
		end
		if unexistent_drives == #logical.drives then
			logicals_failed[ #logicals_failed + 1 ] = logical_id
		end
	end
	for _, logical_id in ipairs( logicals_failed ) do
		logicals[ logical_id ].state = "failed"
	end
	return logicals
end

local function logical_powersaving_disable( logicals )
	for _,logical in pairs( logicals ) do
		logical:powersaving_disable()
	end
end

function M.caller()
	local logicals = einarc.Logical.list()
	local physicals = einarc.Physical.list()
	local logicals_for_serialization = {}

	logical_powersaving_disable( logicals )
	logicals = logical_states_sanity_check( logicals, physicals )

	local physical_volumes = lvm.PhysicalVolume.list()
	local volume_groups = lvm.VolumeGroup.list( physical_volumes )
	local logical_volumes = lvm.LogicalVolume.list( volume_groups )
	local access_patterns = scst.AccessPattern.list()
	local sessions = scst.Session.list()

	unknown_access_patterns_filename_unbind( access_patterns, logical_volumes )
	access_patterns = scst.AccessPattern.list()
	scst.Daemon.apply()

	for logical_id, logical in pairs( logicals ) do
		logicals[ logical_id ]:physical_list()
		logicals[ logical_id ]:progress_get()
		logicals[ logical_id ].writecache = logicals[ logical_id ]:is_writecache()
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
			logicals = logicals,
			access_patterns = access_patterns,
			sessions = sessions
		} ),
		logicals = logicals_for_serialization,
		physicals = physicals,
		physical_volumes = physical_volumes,
		volume_groups = volume_groups,
		logical_volumes = logical_volumes_for_serialization,
		access_patterns = access_patterns,
		sessions = sessions
	}
	local FILTERS = {
		M.filter_borders_highlight,
		M.filter_alternation_border_colors,
		M.filter_highlight_snapshots,
		M.filter_highlight_accesss_patterns,
		M.filter_highlight_sessions,
		M.filter_volume_group_percentage,
		filter_add_logical_id_to_physical,
		M.filter_calculate_hotspares,
		M.filter_calculate_flashcache,
		M.filter_deletability_logical,
		M.filter_deletability_logical_volume,
		M.filter_resizability_logical_volume,
		M.filter_unbindability_access_pattern,
		M.filter_unbindability_physical_flashcache,
		filter_mib_humanize,
		filter_size_round,
		filter_fillup_auth_credentials,
		filter_serialize,
		filter_base64encode
	}
	for _,filter in ipairs( FILTERS ) do
		matrix = filter( matrix )
	end
	return matrix
end

function M.filter_physical_enclosures( matrix )
	local lines = matrix.lines
	for current_line, line in ipairs( lines ) do
		if line.physical then
			local physical = einarc.Physical:new( {
				id = line.physical.id,
				model = line.physical.model,
				revision = line.physical.revision,
				serial = line.physical.serial or "",
				frawnode = line.physical.frawnode,
				size = 1, -- dummy for failed disks
				state = line.physical.state
			} )
			line.physical.enclosure_id = physical:enclosure()
		end
	end
	return matrix
end

function M.caller_minimalistic( filters )
	local logicals = einarc.Logical.list()
	local physicals = einarc.Physical.list()

	logical_powersaving_disable( logicals )
	logicals = logical_states_sanity_check( logicals, physicals )

	for logical_id, logical in pairs( logicals ) do
		logicals[ logical_id ]:physical_list()
	end

	local matrix = {
		lines = M.overall( {
			physicals = physicals,
			logicals = logicals } ),
		physicals = physicals
	}
	for _,filter in ipairs( filters ) do
		matrix = filter( matrix )
	end
	return matrix
end

return M
