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
	local e = entry( { "admin", "san", "monitoring", "render", "front" },
	                 call( "render_front" ), nil, 11 )
	e.leaf = true
	local e = entry( { "admin", "san", "monitoring", "render", "rear" },
	                 call( "render_front" ), nil, 11 )
	e.leaf = true
	local e = entry( { "admin", "san", "monitoring", "render", "motherboard" },
	                 call( "render_front" ), nil, 11 )
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

local function bwc_data_get( what )
	local data = {}
	for ipmi_id, template_id in pairs( ASTOR2_MONITORING_CONFIGURATION[ what ] ) do
		local bwc = io.popen("luci-bwc-ipmi \"" .. ipmi_id .. "\" last 2>/dev/null")
		local result = common.split_by( bwc:read("*l"), " " )
		bwc:close()
		data[ template_id ] = result[2]
	end
	return data
end

function render_front()
	return render_svg( "front", bwc_data_get( "front" ) )
end

function render_rear()
	return render_svg( "rear", bwc_data_get( "rear" ) )
end

function render_motherboard()
	return render_svg( "motherboard", bwc_data_get( "motherboard" ) )
end
