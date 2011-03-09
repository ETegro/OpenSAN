--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: samba.lua 5448 2009-10-31 15:54:11Z jow $
]]--
module("luci.controller.samba", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/samba") then
		return
	end
	require("luci.i18n")
	luci.i18n.loadc("samba")
	
	local page = entry({"admin", "services", "samba"}, cbi("samba"), luci.i18n.translate("Network Shares"))
	page.i18n = "samba"
	page.dependent = true
end