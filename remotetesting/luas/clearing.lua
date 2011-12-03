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

TestClearing = {}
function TestClearing:test_clearing()
	while #scst.AccessPattern.list() > 0 do
		for _, ap in ipairs( scst.AccessPattern.list() ) do
			print( "Deleting AccessPattern: " .. ap.name )
			ap:delete()
		end
	end
	scst.Daemon.apply()
	lvm.restore()
	for _, pv in ipairs( lvm.PhysicalVolume.list() ) do
		for _, vg in ipairs( lvm.VolumeGroup.list( { pv } ) ) do
			print( "Disabling VolumeGroup: " .. vg.name )
			vg:disable()
		end
		print( "Preparing device: " .. pv.device )
		lvm.PhysicalVolume.prepare( pv.device )
	end
	for _, l in pairs( einarc.Logical.list() ) do
		print( "Deleting Logical: " .. l.id )
		l:delete()
	end
end
