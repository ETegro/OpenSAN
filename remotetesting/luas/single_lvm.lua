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

TestCreate = {}

PS_IDS = nil
function TestCreate:test_get_physicals()
	local ps = einarc.Physical.list()
	PS_IDS = common.keys( ps )
	assert( #PS_IDS > 0 )
end

LOGICAL = nil
function TestCreate:test_create_logical()
	einarc.Logical.add( "0", PS_IDS )
	local logicals = einarc.Logical.list()
	assertEquals( #common.keys( logicals ), 1 )
	assert( logicals[0] )
	LOGICAL = logicals[0]
end

PHYSICAL_VOLUMES = nil
function TestCreate:test_create_physical_volume()
	lvm.PhysicalVolume.create( LOGICAL.device )
	lvm.PhysicalVolume.rescan()
	PHYSICAL_VOLUMES = lvm.PhysicalVolume.list()
	assertEquals( #PHYSICAL_VOLUMES, 1 )
end

VOLUME_GROUP = nil
function TestCreate:test_create_volume_group()
	lvm.VolumeGroup.create( PHYSICAL_VOLUMES )
	lvm.PhysicalVolume.rescan()
	lvm.VolumeGroup.rescan()
	PHYSICAL_VOLUMES = lvm.PhysicalVolume.list()
	VOLUME_GROUP = lvm.VolumeGroup.list( PHYSICAL_VOLUMES )[1]
	assert( VOLUME_GROUP )
	assertEquals( PHYSICAL_VOLUMES[1].volume_group,
	              VOLUME_GROUP.name )
end

LOGICAL_VOLUME = nil
function TestCreate:test_create_logical_volume()
	VOLUME_GROUP:logical_volume( random_name(),
	                             1 * VOLUME_GROUP.extent )
	lvm.LogicalVolume.rescan()
	LOGICAL_VOLUME = lvm.LogicalVolume.list( { VOLUME_GROUP } )[1]
	assert( LOGICAL_VOLUME )
end

function TestCreate:test_create_iqn()
	local ap = scst.AccessPattern:new( {
		name = random_name(),
		targetdriver = "iscsi",
		lun = 1,
		enabled = true,
		readonly = false
	} )
	ap = ap:save()
	ap:bind( LOGICAL_VOLUME.device )
	scst.Daemon.apply()
end

LuaUnit:run(
	"TestCreate:test_get_physicals",
	"TestCreate:test_create_logical",
	"TestCreate:test_create_physical_volume",
	"TestCreate:test_create_volume_group",
	"TestCreate:test_create_logical_volume",
	"TestCreate:test_create_iqn"
)
