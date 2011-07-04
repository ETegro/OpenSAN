--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
                          Vladimir Petukhov <vladimir.petukhov@etegro.com>
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
]]--

module( "luci.controller.san_monitoring", package.seeall )

common = require( "astor2.common" )
require "luci.controller.san_monitoring_configuration"

require( "luci.i18n" ).loadc( "astor2_san")

function index()
	local i18n = luci.i18n.translate
	local e = entry( { "admin", "san", "monitoring" },
	                 call( "monitoring_overall" ),
	                 i18n("Monitoring"),
	                 11 )
	e.i18n = "astor2_san"
	local e = entry( { "admin", "san", "monitoring", "render" },
	                 call( "render" ), nil, 11 )
	e.leaf = true
end

local function index_with_error( message_error )
	local http = luci.http
	if message_error then message_error = tostring( message_error ) end
	http.redirect( luci.dispatcher.build_url( "admin", "san", "monitoring" ) .. "/" ..
	               http.build_querystring( { message_error = message_error } ) )
end

function monitoring_overall()
	local message_error = luci.http.formvalue( "message_error" )
	luci.template.render( "san_monitoring", { message_error = message_error } )
end

local function render_svg( svg_filename, data )
	luci.http.prepare_content( "image/svg+xml" )
	luci.template.render( "san_monitoring/" .. svg_filename .. ".svg", { data = data } )
end

--[[
+------+-------+-------------+---------+------------+--------+
| 1    | 2     | 3           | 4       | 5          | 6      |
|------+-------+-------------+---------+------------+--------|
| time | value | low non-crt | low crt | up non-crt | up-crt |
+------+-------+-------------+---------+------------+--------+
--]]
local function determine_color( result )
	local numberized = {}
	for _, v in ipairs( result ) do
		numberized[ #numberized + 1 ] = tonumber( v )
	end
	result = numberized

	if result[2] > result[3] and
	   result[2] < result[5] then
		return "green"
	end
	if result[2] > result[4] and
	   result[2] < result[3] then
		return "orange"
	end
	if result[2] > result[5] and
	   result[2] < result[6] then
		return "orange"
	end
	return "red"
end

local function bwc_data_get( what )
	local data = {}
	for ipmi_id, template_id in pairs( luci.controller.san_monitoring_configuration.configuration[ what ] ) do
		local bwc = io.popen("luci-bwc-ipmi \"" .. ipmi_id .. "\" last 2>/dev/null")
		local result = common.split_by( bwc:read("*l"), " " )
		bwc:close()
		data[ template_id ] = {
			value = result[2],
			color = determine_color( result )
		}
	end
	return data
end

function render()
	local what = luci.http.formvalue( "what" )
	return render_svg( what, bwc_data_get( what ) )
end
