--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2012 ETegro Technologies, PLC
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
]]

local M = {}

local common = require( "astor2.common" )
local einarc = require( "astor2.einarc" )
local lvm = require( "astor2.lvm" )
local scst = require( "astor2.scst" )

function M.apply( logicals, physical_volumes, volume_groups, logical_volumes )
	if not physical_volumes and not volume_groups and not logical_volumes and not logicals then
		logicals = einarc.Logical.list()
		lvm.restore()
		physical_volumes = physical_volumes or lvm.PhysicalVolume.list()
		volume_groups = volume_groups or lvm.VolumeGroup.list( physical_volumes )
		logical_volumes = logical_volumes or lvm.LogicalVolume.list( volume_groups )
	end

	for logical_id, logical in pairs( logicals ) do
		local writethrough_found = false
		for _, logical_volume in ipairs( logical_volumes ) do
			for _, physical_volume in ipairs( logical_volume.volume_group.physical_volumes ) do
				if physical_volume.device == logical.device then
					local ap = scst.AccessPattern.find_by( "filename", logical_volume.device )
					if ap and ap.writethrough then
						writethrough_found = true
					end
				end
			end
		end
		if writethrough_found then
			logical:writecache_disable()
		else
			logical:writecache_enable()
		end
	end
end

return M
