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
local sys = require "luci.sys"

m = SimpleForm("network", translate("Create Interface"))

newnet = m:field(Value, "_netname", translate("Name of the new interface"),
	translate("The allowed characters are: <code>A-Z</code>, <code>a-z</code>, " ..
		"<code>0-9</code> and <code>_</code>")
)

newnet:depends("_attach", "")
newnet.default = arg[1] and "net_" .. arg[1]:gsub("[^%w_]+", "_")
newnet.datatype = "uciname"
newnet.rmempty = false

--[[
netbridge = m:field(Flag, "_bridge", translate("Create a bridge over multiple interfaces"))
]]
net_bond = m:field(Flag, "_bond", translate("Create a bonding from multiple interfaces"))

bond_mode = m:field(ListValue, "_bond-mode", translate("Mode"),
	translate("Default bonding policy is \"balance-rr\"."))
bond_mode:depends("_bond", "1")
bond_mode:value("balance-rr", "balance-rr")
bond_mode:value("active-backup", "active-backup")
bond_mode:value("balance-xor", "balance-xor")
bond_mode:value("broadcast", "broadcast")
bond_mode:value("802.3ad", "802.3ad")
bond_mode:value("balance-tlb", "balance-tlb")
bond_mode:value("balance-alb", "balance-alb")
bond_mode.default = "balance-rr"

bond_miimon = m:field(Value, "_bond-miimon", translate("MII link monitoring frequency"),
	translate("ms") .. " (0 - 3000). " .. translate("Default value is") .. " 50.")
bond_miimon:depends("_bond", "1")
bond_miimon.datatype = "range(0,3000)"
bond_miimon.default = "50"

bond_downdelay = m:field(Value, "_bond-downdelay", translate("Time to wait before disabling slave-interface after link failure"),
	translate("ms") .. " (0 - 3000). " .. translate("Delay value should be a multiple of the MII monitoring value; if not, it will be rounded to the nearest multiple.") .. " " .. translate("Default value is") .. " 0.")
bond_downdelay:depends("_bond", "1")
bond_downdelay.datatype = "range(0,3000)"
bond_downdelay.default = "0"

bond_updelay = m:field(Value, "_bond-updelay", translate("Time to wait before enabling slave-interface after link recover"),
	translate("ms") .. " (0 - 3000). " .. translate("Delay value should be a multiple of the MII monitoring value; if not, it will be rounded to the nearest multiple.") .. " " .. translate("Default value is") .. " 0.")
bond_updelay:depends("_bond", "1")
bond_updelay.datatype = "range(0,3000)"
bond_updelay.default = "0"

sifname = m:field(Value, "_ifname", translate("Cover the following interface"),
	translate("Note: If you choose an interface here which is part of another network, it will be moved into this network."))

sifname.widget = "radio"
sifname.template = "cbi/network_ifacelist"
--[[
sifname.nobridges = true
sifname:depends("_bridge", "")
]]
sifname.nobondings = true
sifname:depends("_bond", "")


mifname = m:field(Value, "_ifnames", translate("Cover the following interfaces"),
	translate("Note: If you choose an interface here which is part of another network, it will be moved into this network."))

mifname.widget = "checkbox"
mifname.template = "cbi/network_ifacelist"
--[[
mifname.nobridges = true
mifname:depends("_bridge", "1")
]]
mifname.nobondings = true
mifname:depends("_bond", "1")

function newnet.write(self, section, value)
	--[[
	local bridge = netbridge:formvalue(section) == "1"
	local ifaces = bridge and mifname:formvalue(section) or sifname:formvalue(section)
	]]
	local bond = {
		use = net_bond:formvalue( section ) == "1" ,
		type = "bonding",
		mode = bond_mode:formvalue( section ),
		miimon = bond_miimon:formvalue( section ),
		downdelay = bond_downdelay:formvalue( section ),
		updelay = bond_updelay:formvalue( section )
	}
	local bond_default = {
		mode = "balance-rr",
		miimon = "50",
		downdelay = "0",
		updelay = "0"
	}

	local ifaces = bond.use and mifname:formvalue(section) or sifname:formvalue(section)

	local nn = nw:add_network(value, { proto = "none" })
	if nn then
		--[[
		if bridge then
			nn:set("type", "bridge")
		end
		]]
		if bond.use then
			for option,value in pairs(bond) do
				if option ~= "use" then
					if value == "" then
						nn:set( option, bond_default[ option ] )
					else
						nn:set( option, value )
					end
				end
			end
			local section_name = newnet:formvalue( section )
			local bondname = nw.generate_bondname( section_name )
			if bondname then
				nn:set( "bondname", bondname )
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
