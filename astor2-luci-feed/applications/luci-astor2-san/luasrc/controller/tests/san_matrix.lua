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
lvm = require( "astor2.lvm" )
einarc = require( "astor2.einarc" )
matrix = require( "matrix" )

-- Those tests are taken from boot library
TestGcd = {}
	function TestGcd:test1()
		assertEquals( matrix.gcd(  1, -1), 1 )
	end
	function TestGcd:test2()
		assertEquals( matrix.gcd( -1,  1), 1 )
	end
	function TestGcd:test3()
		assertEquals( matrix.gcd(  1,  1), 1 )
	end
	function TestGcd:test4()
		assertEquals( matrix.gcd( -1, -1), 1 )
	end
	function TestGcd:test5()
		assertEquals( matrix.gcd(  0,  0), 0 )
	end
	function TestGcd:test6()
		assertEquals( matrix.gcd(  7,  0), 7 )
	end
	function TestGcd:test7()
		assertEquals( matrix.gcd(  0,  9), 9 )
	end
	function TestGcd:test8()
		assertEquals( matrix.gcd( -7,  0), 7 )
	end
	function TestGcd:test9()
		assertEquals( matrix.gcd(  0, -9), 9 )
	end
	function TestGcd:test10()
		assertEquals( matrix.gcd( 42, 30), 6 )
	end
	function TestGcd:test11()
		assertEquals( matrix.gcd(  6, -9), 3 )
	end
	function TestGcd:test12()
		assertEquals( matrix.gcd(-10,-10), 10 )
	end
	function TestGcd:test13()
		assertEquals( matrix.gcd(-25,-10), 5 )
	end
	function TestGcd:test14()
		assertEquals( matrix.gcd(  3,  7), 1 )
	end
	function TestGcd:test15()
		assertEquals( matrix.gcd(  8,  9), 1 )
	end
	function TestGcd:test16()
		assertEquals( matrix.gcd(  7, 49), 7 )
	end

-- Those tests are taken from boot library
TestLcm = {}
	function TestLcm:test1()
		assertEquals( matrix.lcm(  1,  -1), 1 )
	end
	function TestLcm:test2()
		assertEquals( matrix.lcm( -1,   1), 1 )
	end
	function TestLcm:test3()
		assertEquals( matrix.lcm(  1,   1), 1 )
	end
	function TestLcm:test4()
		assertEquals( matrix.lcm( -1,  -1), 1 )
	end
	function TestLcm:test5()
		assertEquals( matrix.lcm(  0,   0), 0 )
	end
	function TestLcm:test6()
		assertEquals( matrix.lcm(  6,   0), 0 )
	end
	function TestLcm:test7()
		assertEquals( matrix.lcm(  0,   7), 0 )
	end
	function TestLcm:test8()
		assertEquals( matrix.lcm( -5,   0), 0 )
	end
	function TestLcm:test9()
		assertEquals( matrix.lcm(  0,  -4), 0 )
	end
	function TestLcm:test10()
		assertEquals( matrix.lcm( 18,  30), 90 )
	end
	function TestLcm:test11()
		assertEquals( matrix.lcm( -6,   9), 18 )
	end
	function TestLcm:test12()
		assertEquals( matrix.lcm(-10, -10), 10 )
	end
	function TestLcm:test13()
		assertEquals( matrix.lcm( 25, -10), 50 )
	end
	function TestLcm:test14()
		assertEquals( matrix.lcm(  3,   7), 21 )
	end
	function TestLcm:test15()
		assertEquals( matrix.lcm(  8,   9), 72 )
	end
	function TestLcm:test16()
		assertEquals( matrix.lcm(  7,  49), 49 )
	end

TestMatrix = {}
	function TestMatrix:setUp()
		self.physicals = {
			["3:1"] = {
				model = "model1",
				revision = "qwerty",
				serial = "010001111",
				size = 666,
				state = "3"
			},
			["3:2"] = {
				model = "model1",
				revision = "qwerty",
				serial = "010001112",
				size = 666,
				state = "3"
			},
			["13:1"] = {
				model = "model2",
				revision = "asdfgh",
				serial = "010001121",
				size = 333,
				state = "13"
			},
			["13:2"] = {
				model = "model2",
				revision = "asdfgh",
				serial = "010001122",
				size = 333,
				state = "13"
			},
			["13:3"] = {
				model = "model2",
				revision = "asdfgh",
				serial = "010001123",
				size = 333,
				state = "13"
			},
			["13:4"] = {
				model = "model2",
				revision = "asdfgh",
				serial = "010001124",
				size = 333,
				state = "failed"
			},
			["13:5"] = {
				model = "model2",
				revision = "asdfgh",
				serial = "010001125",
				size = 333,
				state = "hotspare"
			},
			["9:2"] = {
				model = "model3",
				revision = "zxcvbn",
				serial = "010001131",
				size = 123,
				state = "free"
			},
			["9:4"] = {
				model = "model3",
				revision = "zxcvbn",
				serial = "010001132",
				size = 246,
				state = "free"
			}
		}
		self.logicals = {
			[3] = {
				level = "1",
				physicals = {
					["3:1"] = "3",
					["3:2"] = "3"
				},
				capacity = 666.0,
				device = "/dev/md3",
				state = "normal"
			},
			[13] = {
				level = "5",
				physicals = {
					["13:1"] = "13",
					["13:2"] = "13",
					["13:3"] = "13",
					["13:4"] = "failed",
					["13:5"] = "hotspare"
				},
				capacity = 666.0,
				device = "/dev/md13",
				state = "degraded"
			}
		}
		self.logicals_with_lvm = {
			[9] = {
				level = "1",
				physicals = {
					["3:1"] = "3",
					["3:2"] = "3"
				},
				capacity = 666.0,
				device = "/dev/md3",
				state = "normal",
				logical_volumes = {
					["foo"] = lvm.LogicalVolume:new( {
						name = "foo",
						device = "foobar1",
						volume_group = {}, -- It is dummy
						size = 12
					} ),
					["bar"] = lvm.LogicalVolume:new( {
						name = "bar",
						device = "foobar2",
						volume_group = {}, -- It is dummy
						size = 23
					} ),
					["baz"] = lvm.LogicalVolume:new( {
						name = "baz",
						device = "foobar3",
						volume_group = {}, -- It is dummy
						size = 34
					} )
				}
			}
		}
		self.tasks = {
			[0] = {
				what = "rebuilding",
				where = "13",
				progress = 66.6
			}
		}
	end
	function TestMatrix:test_matrix_double()
		assert( common.compare_tables(
			matrix.overall( {
				physicals = self.physicals, -- Actually should be astor2.einarc.etc
				logicals = self.logicals,   -- Actually should be astor2.einarc.etc
				tasks = self.tasks          -- Actually should be astor2.einarc.etc
			} ), {
				{
					physical = {
						rowspan = 1,
						highlight = { "left", "top" },
						id = "3:1",
						model = "model1",
						revision = "qwerty",
						serial = "010001111",
						size = 666,
						state = "3"
					},
					logical = {
						rowspan = 2,
						highlight = { "top", "right", "bottom" },
						id = 3,
						level = "1",
						physicals = {
							["3:1"] = "3",
							["3:2"] = "3"
						},
						capacity = 666.0,
						device = "/dev/md3",
						state = "normal"
					}
				},
				{
					physical = {
						rowspan = 1,
						highlight = { "bottom", "left" },
						id = "3:2",
						model = "model1",
						revision = "qwerty",
						serial = "010001112",
						size = 666,
						state = "3"
					}
				},
				{
					physical = {
						rowspan = 1,
						highlight = { "left", "top" },
						id = "13:1",
						model = "model2",
						revision = "asdfgh",
						serial = "010001121",
						size = 333,
						state = "13"
					},
					logical = {
						rowspan = 5,
						highlight = { "top", "right", "bottom" },
						id = 13,
						level = "5",
						physicals = {
							["13:1"] = "13",
							["13:2"] = "13",
							["13:3"] = "13",
							["13:4"] = "failed",
							["13:5"] = "hotspare"
						},
						capacity = 666.0,
						device = "/dev/md13",
						state = "degraded",
						progress = 66.6
					}
				},
				{
					physical = {
						rowspan = 1,
						highlight = { "left" },
						id = "13:2",
						model = "model2",
						revision = "asdfgh",
						serial = "010001122",
						size = 333,
						state = "13"
					},
				},
				{
					physical = {
						rowspan = 1,
						highlight = { "left" },
						id = "13:3",
						model = "model2",
						revision = "asdfgh",
						serial = "010001123",
						size = 333,
						state = "13"
					},
				},
				{
					physical = {
						rowspan = 1,
						highlight = { "left" },
						id = "13:4",
						model = "model2",
						revision = "asdfgh",
						serial = "010001124",
						size = 333,
						state = "failed"
					},
				},
				{
					physical = {
						rowspan = 1,
						highlight = { "bottom", "left" },
						id = "13:5",
						model = "model2",
						revision = "asdfgh",
						serial = "010001125",
						size = 333,
						state = "hotspare"
					}
				}
			}
		) )
	end
	function TestMatrix:test_matrix_triple()
		assert( common.compare_tables(
			matrix.overall( {
				physicals = self.physicals,
				logicals = self.logicals_with_lvm
			} ), {
				-- 1
				{
					physical = {
						rowspan = 3,
						highlight = { "left", "top" },
						id = "3:1",
						model = "model1",
						revision = "qwerty",
						serial = "010001111",
						size = 666,
						state = "3"
					},
					logical = {
						rowspan = 6,
						highlight = { "top", "bottom" },
						id = 3,
						level = "1",
						physicals = {
							["3:1"] = "3",
							["3:2"] = "3"
						},
						capacity = 666.0,
						device = "/dev/md3",
						state = "normal"
					},
					logical_volume = {
						rowspan = 2,
						highlight = { "top", "right" },
						name = "foo",
						volume_group = {},
						size = 12
					}
				},
				-- 2
				{
				},
				-- 3
				{
					logical_volume = {
						rowspan = 2,
						highlight = { "right" },
						name = "bar",
						volume_group = {},
						size = 23
					}
				},
				-- 4
				{
					physical = {
						rowspan = 3,
						highlight = { "bottom", "left" },
						id = "3:2",
						model = "model1",
						revision = "qwerty",
						serial = "010001112",
						size = 666,
						state = "3"
					}
				},
				-- 5
				{
					logical_volume = {
						rowspan = 2,
						highlight = { "bottom", "left" },
						name = "baz",
						volume_group = {},
						size = 34
					}

				},
				-- 6
				{
				}
			}
		) )
	end

LuaUnit:run()
