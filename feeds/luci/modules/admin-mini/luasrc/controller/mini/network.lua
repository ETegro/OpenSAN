--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: network.lua 5485 2009-11-01 14:24:04Z jow $
]]--

module("luci.controller.mini.network", package.seeall)

function index()
	luci.i18n.loadc("base")
	local i18n = luci.i18n.translate

	entry({"mini", "network"}, alias("mini", "network", "index"), i18n("Network"), 20).index = true
	entry({"mini", "network", "index"}, cbi("mini/network", {autoapply=true}), i18n("General"), 1)
	entry({"mini", "network", "wifi"}, cbi("mini/wifi", {autoapply=true}), i18n("Wifi"), 10)
	entry({"mini", "network", "dhcp"}, cbi("mini/dhcp", {autoapply=true}), "DHCP", 20)
end
