--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: ddns.lua 5989 2010-03-29 21:34:45Z jow $
]]--
module("luci.controller.ddns", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("ddns")
	if not nixio.fs.access("/etc/config/ddns") then
		return
	end
	
	local page = entry({"admin", "services", "ddns"}, cbi("ddns/ddns"), luci.i18n.translate("Dynamic DNS"), 60)
	page.i18n = "ddns"
	page.dependent = true
	
	
	local page = entry({"mini", "network", "ddns"}, cbi("ddns/ddns", {autoapply=true}), luci.i18n.translate("Dynamic DNS"), 60)
	page.i18n = "ddns"
	page.dependent = true
end
