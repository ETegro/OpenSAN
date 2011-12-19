--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2012 ETegro Technologies, PLC
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
  
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

NUMBER_OF_LOGICAL_VOLUMES = 2 --for Logical
NUMBER_OF_SNAPSHOTS = 2 --for LogicalVolume
NUMBER_OF_ACCESS_PATTERNS = 3 --for LogicalVolume
NUMBER_OF_ACCESS_PATTERNS_FOR_SNAPSHOT = NUMBER_OF_ACCESS_PATTERNS - 1 --for Snapshot
CREATE_ACCESS_PATTERNS_FOR = "all" --create AccessPatterns for "odd", "even" and "all" LogicalVolumes

PS_IDS = nil
function TestCreate:test_get_physicals()
	local physicals = einarc.Physical.list()
	PS_IDS = common.keys( physicals )
	assert( #PS_IDS > 0 )
end

LOGICALS = nil
function TestCreate:test_create_logicals()
	for _, physical_id in pairs( PS_IDS ) do
		einarc.Logical.add( "passthrough", { physical_id } )
		print( physical_id )
	end
	LOGICALS = einarc.Logical.list()
	assert( LOGICALS )
	assertEquals( #common.keys( LOGICALS ), #PS_IDS )
end

PHYSICAL_VOLUMES = nil
function TestCreate:test_create_physical_volumes()
	for _, logical in pairs( LOGICALS ) do
		lvm.PhysicalVolume.create( logical.device )
		print( logical.device )
	end
	lvm.PhysicalVolume.rescan()
	PHYSICAL_VOLUMES = lvm.PhysicalVolume.list()
	assert( PHYSICAL_VOLUMES )
	assertEquals( #common.keys( PHYSICAL_VOLUMES ), #common.keys( LOGICALS ) )
end

VOLUME_GROUPS = nil
function TestCreate:test_create_volume_groups()
	for _, physical_volume in pairs( PHYSICAL_VOLUMES ) do
		lvm.VolumeGroup.create( { physical_volume } )
		print( physical_volume.device )
	end
	lvm.PhysicalVolume.rescan()
	lvm.VolumeGroup.rescan()
	PHYSICAL_VOLUMES = lvm.PhysicalVolume.list()
	assert( PHYSICAL_VOLUMES )
	VOLUME_GROUPS = lvm.VolumeGroup.list( PHYSICAL_VOLUMES )
	assert( VOLUME_GROUPS )
	assertEquals( #common.keys( VOLUME_GROUPS ), #common.keys( PHYSICAL_VOLUMES ) )
end

LOGICAL_VOLUMES = nil
function TestCreate:test_create_logical_volumes()
	for _, volume_group in pairs( VOLUME_GROUPS ) do
		local max_logical_volumes = volume_group.total / volume_group.extent
		assert( NUMBER_OF_LOGICAL_VOLUMES <= max_logical_volumes )
		local logical_volume_size = 1 * volume_group.extent
		for v = 1, NUMBER_OF_LOGICAL_VOLUMES do
			local logical_volume_name = random_name()
			volume_group:logical_volume( logical_volume_name,
			                             logical_volume_size )
			print( volume_group.name )
		end
	end
	lvm.LogicalVolume.rescan()
	LOGICAL_VOLUMES = lvm.LogicalVolume.list( VOLUME_GROUPS )
	assert( LOGICAL_VOLUMES )
	assertEquals( #common.keys( LOGICAL_VOLUMES ),
	              #common.keys( VOLUME_GROUPS ) * NUMBER_OF_LOGICAL_VOLUMES )
end

function TestCreate:test_create_snapshots()
	for _, logical_volume in pairs( LOGICAL_VOLUMES ) do
		for s = 1, NUMBER_OF_SNAPSHOTS do
			logical_volume:snapshot( logical_volume.size )
			print( "snapshot for " .. logical_volume.name )
		end
		lvm.LogicalVolume.rescan()
		LOGICAL_VOLUMES = lvm.LogicalVolume.list( VOLUME_GROUPS )
	end
	--Filling snapshots in logical_volumes
	for _, logical_volume in pairs( LOGICAL_VOLUMES ) do
		if logical_volume.snapshots and #logical_volume.snapshots > 0 then
			for _, snapshot in pairs( logical_volume.snapshots ) do
				LOGICAL_VOLUMES[ #LOGICAL_VOLUMES + 1 ] = snapshot
			end
		end
	end
	--lvm.LogicalVolume.rescan()
	--LOGICAL_VOLUMES = lvm.LogicalVolume.list( VOLUME_GROUPS )
	assertEquals( #common.keys( LOGICAL_VOLUMES ),
	              #common.keys( VOLUME_GROUPS ) * ( NUMBER_OF_SNAPSHOTS + 1 ) * NUMBER_OF_LOGICAL_VOLUMES )
end

function TestCreate:test_create_iqns()
	for _, volume_group in pairs( VOLUME_GROUPS ) do
		local logical_volumes_names = {}
		for _, logical_volume in pairs( LOGICAL_VOLUMES ) do
			if logical_volume.volume_group.name == volume_group.name then
				logical_volumes_names[ #logical_volumes_names + 1 ] = logical_volume.name
			end
		end
		assertEquals( #logical_volumes_names,
		              ( NUMBER_OF_SNAPSHOTS + 1 ) * NUMBER_OF_LOGICAL_VOLUMES )
		table.sort( logical_volumes_names )
		for v,_ in ipairs( logical_volumes_names ) do
			if CREATE_ACCESS_PATTERNS_FOR == "all" then
				for _, logical_volume in pairs( LOGICAL_VOLUMES ) do
					if logical_volume.name == logical_volumes_names[ v ] then
						local number_of_access_pattern = NUMBER_OF_ACCESS_PATTERNS
						if logical_volume:is_snapshot() then
							number_of_access_pattern = NUMBER_OF_ACCESS_PATTERNS_FOR_SNAPSHOT
						end
						for i = 1, number_of_access_pattern do
							local access_pattern = scst.AccessPattern:new( {
								name = random_name(),
								targetdriver = "iscsi",
								lun = i - 1,
								enabled = true,
								readonly = false
							} )
							access_pattern = access_pattern:save()
							access_pattern:bind( logical_volume.device )
							scst.Daemon.apply()
						end
					end
				end
			end
			if CREATE_ACCESS_PATTERNS_FOR == "even" then
				if not common.is_odd( v ) then
					for _, logical_volume in pairs( LOGICAL_VOLUMES ) do
						if logical_volume.name == logical_volumes_names[ v ] then
							local number_of_access_pattern = NUMBER_OF_ACCESS_PATTERNS
							if logical_volume:is_snapshot() then
								number_of_access_pattern = NUMBER_OF_ACCESS_PATTERNS_FOR_SNAPSHOT
							end
							for i = 1, number_of_access_pattern do
								local access_pattern = scst.AccessPattern:new( {
									name = random_name(),
									targetdriver = "iscsi",
									lun = i - 1,
									enabled = true,
									readonly = false
								} )
								access_pattern = access_pattern:save()
								access_pattern:bind( logical_volume.device )
								scst.Daemon.apply()
							end
						end
					end
				end
			end
			if CREATE_ACCESS_PATTERNS_FOR == "odd" then
				if common.is_odd( v ) then
					for _, logical_volume in pairs( LOGICAL_VOLUMES ) do
						if logical_volume.name == logical_volumes_names[ v ] then
							local number_of_access_pattern = NUMBER_OF_ACCESS_PATTERNS
							if logical_volume:is_snapshot() then
								number_of_access_pattern = NUMBER_OF_ACCESS_PATTERNS_FOR_SNAPSHOT
							end
							for i = 1, number_of_access_pattern do
								local access_pattern = scst.AccessPattern:new( {
									name = random_name(),
									targetdriver = "iscsi",
									lun = i - 1,
									enabled = true,
									readonly = false
								} )
								access_pattern = access_pattern:save()
								access_pattern:bind( logical_volume.device )
								scst.Daemon.apply()
							end
						end
					end
				end
			end
		end
		local access_pattern = scst.AccessPattern.list()
		assert( access_pattern )
		--assertEquals( #common.keys( access_pattern ), #common.keys( LOGICAL_VOLUMES ) )
	end
end

LuaUnit:run(
	"TestCreate:test_get_physicals",
	"TestCreate:test_create_logicals",
	"TestCreate:test_create_physical_volumes",
	"TestCreate:test_create_volume_groups",
	"TestCreate:test_create_logical_volumes",
	"TestCreate:test_create_snapshots",
	"TestCreate:test_create_iqns"
)
