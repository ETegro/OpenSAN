--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: upnpmini.lua 5605 2009-12-04 23:16:06Z jow $
]]--
m = Map("upnpd", translate("Universal Plug & Play"), translate("UPNP allows clients in the local network to automatically configure the router."))

s = m:section(NamedSection, "config", "upnpd", "")
s.addremove = false

e = s:option(Flag, "enabled", translate("enable"))
e.rmempty = false

s:option(Value, "download", translate("Downlink"), "kByte/s").rmempty = true
s:option(Value, "upload", translate("Uplink"), "kByte/s").rmempty = true

return m
