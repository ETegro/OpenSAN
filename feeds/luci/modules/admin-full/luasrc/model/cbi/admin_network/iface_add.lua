--[[
LuCI - Lua Configuration Interface

Copyright 2009-2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: iface_add.lua 6439 2010-11-15 22:11:18Z jow $

]]--

local nw  = require "luci.model.network".init()
local fw  = require "luci.model.firewall".init()
local utl = require "luci.util"
local uci = require "luci.model.uci".cursor()

m = SimpleForm("network", translate("Create Interface"))

newnet = m:field(Value, "_netname", translate("Name of the new interface"),
	translate("The allowed characters are: <code>A-Z</code>, <code>a-z</code>, " ..
		"<code>0-9</code> and <code>_</code>"
	))

newnet:depends("_attach", "")
newnet.default = arg[1] and "net_" .. arg[1]:gsub("[^%w_]+", "_")
newnet.datatype = "uciname"

--[[
netbridge = m:field(Flag, "_bridge", translate("Create a bridge over multiple interfaces"))
]]
netbond = m:field(Flag, "_bond", translate("Create a bonding from multiple interfaces"))

bondmode = m:field(ListValue, "_bondmode", translate("The bonding mode"))
bondmode:depends("_bond", "1")
bondmode.default = "1"
bondmode:value("0", "balance-rr")
bondmode:value("1", "active-backup")
bondmode:value("2", "balance-xor")
bondmode:value("3", "broadcast")
bondmode:value("4", "802.3ad")
bondmode:value("5", "balance-tlb")
bondmode:value("6", "balance-alb")

sifname = m:field(Value, "_ifname", translate("Cover the following interface"),
	translate("Note: If you choose an interface here which is part of another network, it will be moved into this network."))

sifname.widget = "radio"
sifname.template = "cbi/network_ifacelist"
--[[
sifname.nobridges = true
sifname:depends("_bridge", "")
]]
sifname.nobonds = true
sifname:depends("_bond", "")


mifname = m:field(Value, "_ifnames", translate("Cover the following interfaces"),
	translate("Note: If you choose an interface here which is part of another network, it will be moved into this network."))

mifname.widget = "checkbox"
mifname.template = "cbi/network_ifacelist"
--[[
mifname.nobridges = true
mifname:depends("_bridge", "1")
]]
mifname.nobonds = true
mifname:depends("_bond", "1")

function newnet.write(self, section, value)
	--[[
	local bridge = netbridge:formvalue(section) == "1"
	local ifaces = bridge and mifname:formvalue(section) or sifname:formvalue(section)
	]]
	local bond = netbond:formvalue(section) == "1"
	local bondmode = bondmode:formvalue(section)

	local ifaces = bond and mifname:formvalue(section) or sifname:formvalue(section)

	local nn = nw:add_network(value, { proto = "none" })
	if nn then
		--[[
		if bridge then
			nn:set("type", "bridge")
		end
		]]

	local nn = nw:add_network(value, { proto = "none" })
		if bond then
			nn:set( "type", "bonding" )
			if bondmode == "0" then
				nn:set( "mode", "balance-rr" )
			end
			if bondmode == "1" then
				nn:set( "mode", "active-backup" )
			end
			if bondmode == "2" then
				nn:set( "mode", "balance-xor" )
			end
			if bondmode == "3" then
				nn:set( "mode", "broadcast" )
			end
			if bondmode == "4" then
				nn:set( "mode", "802.3ad" )
			end
			if bondmode == "5" then
				nn:set( "mode", "balance-tlb" )
			end
			if bondmode == "6" then
				nn:set( "mode", "balance-alb" )
			end
		end

		local iface
		for iface in utl.imatch(ifaces) do
			nn:add_interface(iface)
			--[[
			if not bridge then
				break
			end
			]]
			if not bond then
				break
			end
		end

		nw:save("network")
		nw:save("wireless")

		luci.http.redirect(luci.dispatcher.build_url("admin/network/network", nn:name()))
	end
end

return m
