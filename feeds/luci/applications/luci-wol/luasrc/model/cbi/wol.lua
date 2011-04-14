--[[
LuCI - Lua Configuration Interface

Copyright 2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local uci = require "luci.model.uci".cursor()
local utl = require "luci.util"
local sys = require "luci.sys"
local fs  = require "nixio.fs"

m = SimpleForm("wol", translate("Wake on LAN"),
	translate("Wake on LAN is a mechanism to remotely boot computers in the local network."))

m.submit = translate("Wake up host")
m.reset  = false


local has_ewk = fs.access("/usr/bin/etherwake")
local has_wol = fs.access("/usr/bin/wol")


s = m:section(SimpleSection)

local arp = { }
local e, ip, mac, name

if has_ewk and has_wol then
	bin = s:option(ListValue, "binary", translate("WoL program"),
		translate("Sometimes only one of both tools work. If one of fails, try the other one"))

	bin:value("/usr/bin/etherwake", "Etherwake")
	bin:value("/usr/bin/wol", "WoL")
end

if has_ewk then
	iface = s:option(ListValue, "iface", translate("Network interface to use"),
		translate("Specifies the interface the WoL packet is sent on"))

	if has_wol then
		iface:depends("binary", "/usr/bin/etherwake")
	end

	iface:value("", translate("Broadcast on all interfaces"))

	for _, e in ipairs(sys.net.devices()) do
		if e ~= "lo" then iface:value(e) end
	end
end


for _, e in ipairs(sys.net.arptable()) do
	arp[e["HW address"]:upper()] = { e["IP address"] }
end

for e in io.lines("/etc/ethers") do
	mac, ip = e:match("^([a-f0-9]%S+) (%S+)")
	if mac and ip then arp[mac:upper()] = { ip } end
end

for e in io.lines("/var/dhcp.leases") do
	mac, ip, name = e:match("^%d+ (%S+) (%S+) (%S+)")
	if mac and ip then arp[mac:upper()] = { ip, name ~= "*" and name } end
end

uci:foreach("dhcp", "host",
	function(s)
		if s.mac and s.ip then
			arp[s.mac:upper()] = { s.ip, s.name }
		end
	end)

host = s:option(Value, "mac", translate("Host to wake up"),
	translate("Choose the host to wake up or enter a custom MAC address to use"))

for mac, ip in utl.kspairs(arp) do
	host:value(mac, "%s (%s)" %{ mac, ip[2] or ip[1] })
end


function host.write(self, s, val)
	local host = luci.http.formvalue("cbid.wol.1.mac")
	if host and #host > 0 and host:match("^[a-fA-F0-9:]+$") then
		local cmd
		local util = luci.http.formvalue("cbid.wol.1.binary") or (
			has_ewk and "/usr/bin/etherwake" or "/usr/bin/wol"
		)

		if util == "/usr/bin/etherwake" then
			local iface = luci.http.formvalue("cbid.wol.1.iface")
			cmd = "%s -D%s %q" %{
				util, (iface ~= "" and " -i %q" % iface or ""), host
			}
		else
			cmd = "%s -v %q" %{ util, host }
		end

		local msg = "<p><strong>%s</strong><br /><br /><code>%s<br /><br />" %{
			translate("Starting WoL utility:"), cmd
		}

		local p = io.popen(cmd .. " 2>&1")
		if p then
			while true do
				local l = p:read("*l")
				if l then
					if #l > 100 then l = l:sub(1, 100) .. "..." end
					msg = msg .. l .. "<br />"
				else
					break
				end
			end
			p:close()
		end

		msg = msg .. "</code></p>"

		m.message = msg
	end
end


return m
