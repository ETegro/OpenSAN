--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
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

TestCreate = {}
function TestCreate:test_create()
	local ps = einarc.Physical.list()
	local ps_ids = common.keys( ps )
	einarc.Logical.add( "0", { ps_ids[1], ps_ids[2] } )
	local l = einarc.Logical.list()[0]

	lvm.PhysicalVolume.create( l.device )
	lvm.PhysicalVolume.rescan()
	local pv = lvm.PhysicalVolume.list()[1]

	lvm.VolumeGroup.create( { pv } )
	lvm.PhysicalVolume.rescan()
	lvm.VolumeGroup.rescan()
	pv = lvm.PhysicalVolume.list()[1]
	local vg = lvm.VolumeGroup.list( { pv } )[1]

	--vg:logical_volume( "foobar", l.capacity * 0.05 )
	vg:logical_volume( "foobar", 500 )
	lvm.LogicalVolume.rescan()
	local lv = lvm.LogicalVolume.list( { vg } )[1]

	local ap = scst.AccessPattern:new( {
		name = "foobar",
		targetdriver = "iscsi",
		lun = 1,
		enabled = true,
		readonly = false
	} )
	ap:save()
	ap:bind( lv.device )
	scst.Daemon.apply()
end
