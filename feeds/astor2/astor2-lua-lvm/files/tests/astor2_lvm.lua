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

require( "luaunit" )
common = require( "astor2.common" )
lvm = require( "astor2.lvm" )

TestLogicalVolumeNameValidation = {}
	function TestLogicalVolumeNameValidation:test_basic()
		assertEquals( lvm.LogicalVolume.name_is_valid( "foobar" ),
		              true )
		assertEquals( lvm.LogicalVolume.name_is_valid( "foo-bar" ),
		              true )
		assertEquals( lvm.LogicalVolume.name_is_valid( "foo.bar" ),
		              true )
		assertEquals( lvm.LogicalVolume.name_is_valid( "foobar." ),
		              true )
		assertEquals( lvm.LogicalVolume.name_is_valid( "foo bar" ),
		              false )
		assertEquals( lvm.LogicalVolume.name_is_valid( "7NAdnNyijGZrqxFF" ),
		              true )
	end
	function TestLogicalVolumeNameValidation:test_special_cases()
		assertEquals( lvm.LogicalVolume.name_is_valid( ".foobar" ),
		              false )
		assertEquals( lvm.LogicalVolume.name_is_valid( "f.foobar" ),
		              true )
		assertEquals( lvm.LogicalVolume.name_is_valid( "foobar_mlogfoo" ),
		              false )
		assertEquals( lvm.LogicalVolume.name_is_valid( "foobar_mimagefoo" ),
		              false )
		assertEquals( lvm.LogicalVolume.name_is_valid( "snapshot" ),
		              false )
		assertEquals( lvm.LogicalVolume.name_is_valid( "snapshot2" ),
		              true )
		assertEquals( lvm.LogicalVolume.name_is_valid( "pvmove" ),
		              false )
	end

LuaUnit:run()
