--[[
LuCI - Lua Configuration Interface

Copyright 2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: route.lua 6808 2011-01-29 03:27:37Z jow $
]]--

local sid = arg[1]
local utl = require "luci.util"

m = Map("radvd", translatef("Radvd - Route"),
	translate("Radvd is a router advertisement daemon for IPv6. " ..
		"It listens to router solicitations and sends router advertisements " ..
		"as described in RFC 4861."))

m.redirect = luci.dispatcher.build_url("admin/network/radvd")

if m.uci:get("radvd", sid) ~= "route" then
	luci.http.redirect(m.redirect)
	return
end


s = m:section(NamedSection, sid, "interface", translate("Route Configuration"))
s.addremove = false


--
-- General
--

o = s:option(Flag, "ignore", translate("Enable"))
o.rmempty = false

function o.cfgvalue(...)
	local v = Flag.cfgvalue(...)
	return v == "1" and "0" or "1"
end

function o.write(self, section, value)
	Flag.write(self, section, value == "1" and "0" or "1")
end


o = s:option(Value, "interface", translate("Interface"),
	translate("Specifies the logical interface name this section belongs to"))

o.template = "cbi/network_netlist"
o.nocreate = true
o.optional = false

function o.formvalue(...)
	return Value.formvalue(...) or "-"
end

function o.validate(self, value)
	if value == "-" then
		return nil, translate("Interface required")
	end
	return value
end

function o.write(self, section, value)
	m.uci:set("radvd", section, "ignore", 0)
	m.uci:set("radvd", section, "interface", value)
end


o = s:option(DynamicList, "prefix", translate("Prefixes"),
	translate("Advertised IPv6 prefixes"))

o.rmempty     = false
o.datatype    = "ip6addr"
o.placeholder = translate("default")
function o.cfgvalue(self, section)
	local l = { }
	local v = m.uci:get_list("radvd", section, "prefix")
	for v in utl.imatch(v) do
		l[#l+1] = v
	end
	return l
end


o = s:option(Value, "AdvRouteLifetime", translate("Lifetime"),
	translate("Specifies the lifetime associated with the route in seconds. Use 0 to specify an infinite lifetime"))

o.datatype = "uinteger"
o.placeholder = 1800

function o.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	if v == "infinity" then
		return 0
	else
		return v
	end
end

function o.write(self, section, value)
	if value == "0" then
		Value.write(self, section, "infinity")
	else
		Value.write(self, section, value)
	end
end


o = s:option(ListValue, "AdvRoutePreference", translate("Preference"),
	translate("Specifies the preference associated with the default router"))

o.default = "medium"
o:value("low",    translate("low"))
o:value("medium", translate("medium"))
o:value("high",   translate("high"))


return m