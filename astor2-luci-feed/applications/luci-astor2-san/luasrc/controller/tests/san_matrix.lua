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
					lvm.LogicalVolume:new( {
						name = "foo",
						device = "foobar1",
						volume_group = {}, -- It is dummy
						size = 12
					} ),
					lvm.LogicalVolume:new( {
						name = "bar",
						device = "foobar2",
						volume_group = {}, -- It is dummy
						size = 23
					} ),
					lvm.LogicalVolume:new( {
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
