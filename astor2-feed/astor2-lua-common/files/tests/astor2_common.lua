--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
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

LuaUnit:run()
