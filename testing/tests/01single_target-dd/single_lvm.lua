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
