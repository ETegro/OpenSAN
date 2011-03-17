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
]]--

module( "luci.controller.san", package.seeall )

--einarc = require( "astor2.einarc" )

function index()
	require( "luci.i18n" ).loadc( "astor2_san")
	local i18n = luci.i18n.translate

	local e = entry( { "san" }, call( "einarc_lists" ), i18n("SAN"), 10 )
	e.i18n = "astor2_san"

	entry( { "san", "logical_add" }, call( "logical_add" ), nil, 10 ).leaf=true
end

local logical_list_result =
	{ [7] = {
		level = "linear",
		drives = { "0:1", "0:2" },
		capacity = 320,
		device = "/dev/md0",
		state = "normal" },
	[2] = {
		level = "1",
		drives = { "1:0", "1:1" },
		capacity = 160,
		device = "/dev/md1",
		state = "normal" } }

local task_list_result = 
	{ [0] = {
		what = "something",
		where = "2",
		progress = 11.1 },
	[5] = {
		what = "something",
		where = "7",
		progress = 22.2 } }

function einarc_lists()
	local message = luci.http.formvalue("message")
	luci.template.render( "san", {
		physical_list = {
			["0:1"] = {
				model = "some",
				revision = "rev",
				serial = "some",
				size = 666,
				state = "free" },
			["0:2"] = {
				model = "some",
				revision = "rev2",
				serial = "som3e",
				size = 555,
				state = "free" } },
		logical_list = logical_list_result,
		task_list = task_list_result,
		message = message } )
end

function logical_add()
	local drives = luci.http.formvalue( "drives" )
	local raid_level = luci.http.formvalue( "raid_level" )

	if not drives then
		message = "drives not selected"
	elseif type(drives) == type({}) then
		local validators = {
			["0"] = function( drives ) return #drives >= 2 end,
			["1"] = function( drives ) return #drives >= 2 and #drives % 2 == 0 end,
			["5"] = function( drives ) return #drives >= 3 end
		}
		if not validators[ raid_level ]( drives ) then
			message = "error"
		else
			message = raid_level .. "-" ..table.concat(drives, ", ")
		end
		
	elseif type(drives) == type("") then
		message = drives
	end

	luci.http.redirect( luci.dispatcher.build_url( "san" ) .. "/" .. luci.http.build_querystring( { message = message } ) )

end

--	else type( drives ) == table then
--		luci.http.write( "Drives: " .. table.concat( drives ) .. " end" )
--[[		luci.http.redirect( luci.dispatcher.build_url( "san" ) .. "/" .. luci.http.build_querystring( { message="Selected: " .. table.concat( drives ) } ) )
	elseif type( drives ) == string then
		luci.http.redirect( luci.dispatcher.build_url( "san" ) .. "/" .. luci.http.build_querystring( { message="please select minimum 2 drives" } ) )--]]
