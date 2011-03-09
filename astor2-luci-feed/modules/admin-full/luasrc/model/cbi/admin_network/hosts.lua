--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: hosts.lua 6924 2011-02-22 09:52:49Z jow $
]]--

require("luci.sys")
require("luci.util")
m = Map("dhcp", translate("Hostnames"))

s = m:section(TypedSection, "domain", translate("Host entries"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"

hn = s:option(Value, "name", translate("Hostname"))
hn.datatype = "hostname"
hn.rmempty  = true

ip = s:option(Value, "ip", translate("IP address"))
ip.datatype = "ipaddr"
ip.rmempty  = true

for i, dataset in ipairs(luci.sys.net.arptable()) do
	ip:value(
		dataset["IP address"],
		"%s (%s)" %{ dataset["IP address"], dataset["HW address"] }
	)
end

return m
