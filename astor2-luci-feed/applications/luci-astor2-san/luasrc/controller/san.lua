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

einarc = require( "astor2.einarc" )

function index()
	require( "luci.i18n" ).loadc( "astor2_san")
	local i18n = luci.i18n.translate

	local e = entry( { "san" }, call( "einarc_lists" ), i18n("SAN"), 10 )
	e.i18n = "astor2_san"

	e = entry( { "san", "logical_add" }, call( "logical_add" ), nil, 10 )
	e.leaf = true
end

function einarc_lists()
	local message = luci.http.formvalue( "message" )
	luci.template.render( "san", {
		physical_list = einarc.physical.list(),
		logical_list = einarc.logical.list(),
		task_list = einarc.task.list(),
		message = message } )
end

local RAID_VALIDATORS = {
	["linear"] = function( drives ) return #drives == 1 end,
	["passthrough"] = function( drives ) return #drives == 1 end,
	["0"] = function( drives ) return #drives >= 2 end,
	["1"] = function( drives ) return #drives >= 2 and #drives % 2 == 0 end,
	["5"] = function( drives ) return #drives >= 3 end
	["6"] = function( drives ) return #drives >= 3 and #drives % 2 end
	["10"] = function( drives ) return #drives >= 4 and #drives % 2 == 0 end,
}

function logical_add()
	local drives = luci.http.formvalue( "drives" )
	local raid_level = luci.http.formvalue( "raid_level" )
	local ok = false

	if not drives then
		message = "drives not selected"
	elseif type(drives) == type({}) then
		if RAID_VALIDATORS[ raid_level ]( drives ) then
			message = raid_level .. "-" ..table.concat(drives, ", ")
			ok = true
		else
			message = "error"
		end
	elseif type(drives) == type("") then
		message = drives
	end

	if ok then einarc.logical.add( raid_level, drives ) end

	luci.http.redirect( luci.dispatcher.build_url( "san" ) .. "/" .. luci.http.build_querystring( { message = message } ) )

end

--	else type( drives ) == table then
--		luci.http.write( "Drives: " .. table.concat( drives ) .. " end" )
--[[		luci.http.redirect( luci.dispatcher.build_url( "san" ) .. "/" .. luci.http.build_querystring( { message="Selected: " .. table.concat( drives ) } ) )
	elseif type( drives ) == string then
		luci.http.redirect( luci.dispatcher.build_url( "san" ) .. "/" .. luci.http.build_querystring( { message="please select minimum 2 drives" } ) )--]]
