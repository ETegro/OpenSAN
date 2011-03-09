--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: miniportfw.lua 6021 2010-04-05 01:16:25Z jow $
]]--
require("luci.sys")
m = Map("firewall", translate("Port forwarding"),
	translate("Port forwarding allows to provide network services in " ..
		"the internal network to an external network."))


s = m:section(TypedSection, "redirect", "")
s:depends("src", "wan")
s.defaults.src = "wan"

s.template  = "cbi/tblsection"
s.addremove = true
s.anonymous = true

name = s:option(Value, "_name", translate("Name"), translate("(optional)"))
name.size = 10

proto = s:option(ListValue, "proto", translate("Protocol"))
proto:value("tcp", "TCP")
proto:value("udp", "UDP")
proto:value("tcpudp", "TCP+UDP")

dport = s:option(Value, "src_dport", translate("External port"))
dport.size = 5

to = s:option(Value, "dest_ip", translate("Internal IP address"))
for i, dataset in ipairs(luci.sys.net.arptable()) do
	to:value(dataset["IP address"])
end

toport = s:option(Value, "dest_port", translate("Internal port"),
	translate("(optional)"))
toport.size = 5

return m
