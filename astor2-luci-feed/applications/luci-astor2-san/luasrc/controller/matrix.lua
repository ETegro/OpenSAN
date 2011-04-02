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
lvm = require( "astor2.lvm" )
einarc = require( "astor2.einarc" )

function M.gcd( x, y )
	if y == 0 then return math.abs( x ) end
	return M.gcd( y, x % y )
end

function M.lcm( x, y )
	return math.abs( x * y ) / M.gcd( x, y )
end

function M.overall( data )
	local physicals = data.physicals or {}
	local logicals = data.logicals or {}
	local matrix = {}

	for logical_id, logical in pairs( logicals ) do
		local tr = {}
		-- Find maximal value of lines
		local physicals_quantity = #logical.physicals
		local logical_volumes_quantity = #common.keys( logical.logical_volumes )

		local physicals_sorted = M.Physical:sort( logical.physicals )
	end

	return matrix
end

local function device_lvms( device )
	local physical_volumes = {}
	for _, physical_volume in ipairs( lvm.PhysicalVolume:list() ) do
		if physical_volume.device == device then
			physical_volumes[ #physical_volumes + 1 ] = physical
		end
	end
	return lvm.LogicalVolume:list( common.values( lvm.VolumeGroup:list( physical_volumes ) ) )
end

function caller()
	local logicals = einarc.Logical:list_full()
	for logical_id, logical in pairs( logicals ) do
		logicals[ logical_id ]:physical_list()
		logicals[ logical_id ]:progress_get()
		logicals[ logical_id ].logical_volumes = device_lvms( logical.device )
	end
	return overall( {
		physicals = einarc.Physical:list(),
		logicals = logicals
	} )
end

return M
