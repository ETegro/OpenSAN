--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: init.lua 6731 2011-01-14 19:44:03Z soma $
]]--
module("luci.controller.init", package.seeall)

function index()
	if not nixio.fs.access("/etc/rc.common") then
		return
	end

	require("luci.i18n")
	luci.i18n.loadc("initmgr")

	entry(
		{"admin", "services", "init"}, form("init/init"),
		luci.i18n.translate("Initscripts"), 0
	).i18n = "initmgr"

	entry(
		{"admin", "services", "init", "startup" },form("init/startup"),
		luci.i18n.translate("Local Startup"), 10).i18n = "initmgr"
end
