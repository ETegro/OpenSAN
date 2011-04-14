--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: qos.lua 5104 2009-07-19 00:24:58Z jow $
]]--
module("luci.controller.qos", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/qos") then
		return
	end
	
	local page = entry({"admin", "network", "qos"}, cbi("qos/qos"), "QoS")
	page.i18n = "qos"
	page.dependent = true
	
	
	local page = entry({"mini", "network", "qos"}, cbi("qos/qosmini", {autoapply=true}), "QoS")
	page.i18n = "qos"
	page.dependent = true
end
