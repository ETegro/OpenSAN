--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
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

module( "luci.controller.san", package.seeall )

einarc = require( "astor2.einarc" )

function index()
	require( "luci.i18n" )
	luci.i18n.loadc("astor2_san")

	local e = entry( { "san" }, call( "einarc_lists" ), luci.i18n.translate("SAN"), 10 )
	e.i18n = true
end

local logical_list_result =
	{ ["0:1"] = { model = "WDC WD5000BPVT-0",
		revision = "01.0",
		serial = "000003HYJJK",
		size = 476940.02,
	state = "free" },
	["0:2"] = { model = "Transcend 8GB",
		revision = "8.07",
		serial = "",
		size = 7664.00,
		state = "free" },
	["1:0"] = { model = "Kingston 16GB",
		revision = "9.65",
		serial = "rev5",
		size = 15328.00,
		state = "free" },
	["1:1"] = { model = "Samsung 16GB",
		revision = "8.5",
		serial = "rev1",
		size = 15328.00,
		state = "free" } }

function einarc_lists()
	luci.template.render( "san",
		{ physical_list = einarc.physical.list(),
		  logical_list = logical_list_result } )
end
