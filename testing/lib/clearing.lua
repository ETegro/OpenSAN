TestClearing = {}
function TestClearing:test_clearing()
	while #scst.AccessPattern.list() > 0 do
		for _, ap in ipairs( scst.AccessPattern.list() ) do
			if ap:is_binded() then
				ap:unbind()
			end
			ap:delete()
		end
	end
	lvm.restore()
	for _, pv in ipairs( lvm.PhysicalVolume.list() ) do
		for _, vg in ipairs( lvm.VolumeGroup.list( { pv } ) ) do
			vg:disable()
		end
		lvm.PhysicalVolume.prepare( pv.device )
	end
	for _, l in pairs( einarc.Logical.list() ) do
		l:delete()
	end
end
