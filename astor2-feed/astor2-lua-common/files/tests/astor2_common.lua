--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
                          Sergey Matveev <stargrave@stargrave.org>
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
  
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
]]

require( "luaunit" )
common = require( "astor2.common" )

TestIsInArray = {}
	function TestIsInArray:setUp()
		self.a = { "foo", "bar", "baz", 666, 13, 27 }
	end
	function TestIsInArray:test_number()
		assertError( common.is_in_array, self.a, 13 )
		assert( common.is_in_array( 13, self.a ) )
		assert( not common.is_in_array( 20, self.a ) )
	end
	function TestIsInArray:test_string()
		assert( common.is_in_array( "foo", self.a ) )
		assert( not common.is_in_array( "foobar", self.a ) )
	end

TestIsObj = {}
	function TestIsObj:test_number()
		assert( common.is_number( 13 ) )
		assert( not common.is_number( "foo" ) )
		assert( not common.is_number( {"foo"} ) )
	end
	function TestIsObj:test_string()
		assert( common.is_string( "foo" ) )
		assert( not common.is_string( 13 ) )
		assert( not common.is_string( {"foo"} ) )
	end
	function TestIsObj:test_table()
		assert( not common.is_table( "foo" ) )
		assert( not common.is_table( 13 ) )
		assert( common.is_table( {"foo"} ) )
	end
	function TestIsObj:test_odd()
		assertError( common.is_odd, "13" )
		assert( common.is_odd( 4 ) )
		assert( not common.is_odd( 5 ) )
	end
	function TestIsObj:test_array()
		assert( common.is_array( { 1,2,3,4,5 } ) )
		assert( not common.is_array( { foo = "bar" } ) )
	end

TestGetKeys = {}
        function TestGetKeys:setUp()
		self.physical_list = {
			[ "0:4" ] = { size = 100, state = "free" },
			[ "2:2" ] = { size = 200, state = "0" },
			[ "1:3" ] = { size = 300, state = "free" },
			[ "0:1" ] = { size = 400, state = "0" },
			[ "10:5" ] = { size = 500, state = "hotspare" },
			[ "10:11" ] = { size = 600, state = "free" },
			[ "10:1" ] = { size = 700, state = "failed" } }

	end
	function TestGetKeys:test_keys()
		local keys_number = 0
		for _,_ in pairs( self.physical_list ) do
			keys_number = keys_number + 1
		end
		local ids_keys = common.keys( self.physical_list )
		assertEquals( #ids_keys, keys_number )
		for _,id in ipairs( ids_keys ) do
			assert( self.physical_list[id] ~= nil )
		end
	end

LuaUnit:run()
