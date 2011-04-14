--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>
Copyright 2011 Patrick Grimm <patrick@pberg.freifunk.net>
Copyright 2011 Manuel Munz <freifunk at somakoma dot de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
]]--


local uci = require "luci.model.uci".cursor()
local uci_state = require "luci.model.uci".cursor_state()
local tools = require "luci.tools.ffwizard"
local util = require "luci.util"
local sys = require "luci.sys"
local ip = require "luci.ip"
local fs  = require "nixio.fs"

local has_pptp  = fs.access("/usr/sbin/pptp")
local has_pppoe = fs.glob("/usr/lib/pppd/*/rp-pppoe.so")()
local has_l2gvpn  = fs.access("/usr/sbin/node")
local has_radvd  = fs.access("/etc/config/radvd")
local has_rom  = fs.access("/rom/etc")
local has_autoipv6  = fs.access("/usr/bin/auto-ipv6")
local has_qos  = fs.access("/etc/init.d/qos")
local has_ipv6 = fs.access("/proc/sys/net/ipv6")
local has_hb = fs.access("/sbin/heartbeat")
local community = "profile_" .. (uci:get("freifunk", "community", "name") or "na")
local lat = uci:get_first("system", "system", "latitude")
local lon = uci:get_first("system", "system", "longitude")
local suffix = uci:get_first(community, "community", "suffix") or "olsr"

luci.i18n.loadc("ffwizard")

-- Check if all necessary variables are available
if not (community ~= "profile_na" and lat and lon) then
	luci.http.redirect(luci.dispatcher.build_url("admin", "freifunk", "ffwizard_error"))
	return
end

function get_mac(ix)
	if string.find(ix, "radio") then
		ix = string.gsub(ix,"radio", 'wlan')
	end
	local mac = fs.readfile("/sys/class/net/" .. ix .. "/address")
	if not mac then
		mac = luci.util.exec("ifconfig " .. ix)
		mac = mac and mac:match(" ([A-F0-9:]+)%s*\n")
	else
		mac = mac:sub(1,17)
	end
	if mac and #mac > 0 then
		return mac:lower()
	end
	return "?"
end

function get_ula(imac)
	if string.len(imac) == 17 then
		local mac1 = string.sub(imac,4,8)
		local mac2 = string.sub(imac,10,14)
		local mac3 = string.sub(imac,16,17)
		return 'fdca:ffee:babe::02'..mac1..'ff:fe'..mac2..mac3..'/64'
	end
	return "?"
end

function gen_dhcp_range(n)
	local subnet_prefix = tonumber(uci:get_first(community, "community", "splash_prefix")) or 27
	local pool_network = uci:get_first(community, "community", "splash_network") or "10.104.0.0/16"
	local pool = luci.ip.IPv4(pool_network)
	local ip = tostring(n)
	if pool and ip then
		local hosts_per_subnet = 2^(32 - subnet_prefix)
		local number_of_subnets = (2^pool:prefix())/hosts_per_subnet
		local seed1, seed2 = ip:match("(%d+)%.(%d+)$")
		if seed1 and seed2 then
			math.randomseed((seed1+1)*(seed2+1))
		end
		local subnet = pool:add(hosts_per_subnet * math.random(number_of_subnets))
		dhcp_ip = subnet:network(subnet_prefix):add(1):string()
		dhcp_mask = subnet:mask(subnet_prefix):string()
	end
	return "?"
end

function cbi_meship(dev)
	meship = f:field(Value, "meship_" .. dev, dev:upper() .. " " .. translate("Mesh IP address"), 
		translate("This is a unique address in the mesh (e.g. 10.1.1.1) and has to be registered at your local community."))
	meship:depends("device_" .. dev, "1")
	meship.rmempty = true
	function meship.cfgvalue(self, section)
		return uci:get("freifunk", "wizard", "meship_" .. dev)
	end
	function meship.validate(self, value)
		local x = ip.IPv4(value)
		return ( x and x:prefix() == 32 ) and x:string() or ""
	end
	function meship.write(self, sec, value)
		uci:set("freifunk", "wizard", "meship_" .. dev, value)
	end
end

function cbi_meship6(dev)
	local meship6 = f:field(Value, "meship6_" .. dev, dev:upper() .. " " .. translate("Mesh IPv6 Address"), translate("The ipv6 address is calculated auomatically."))
	meship6:depends("device_" .. dev, "1")
	meship6.rmempty = true
	function meship6.cfgvalue(self, section)
		return get_ula(get_mac(dev))
	end
end

function cbi_netconf(dev)
	local d = f:field(Flag, "device_" .. dev , " <b>"  .. dev:upper() .. "</b>", translate("Configure this interface."))
	d:depends("netconfig", "1")
	d.rmempty = false
	function d.cfgvalue(self, section)
		return uci:get("freifunk", "wizard", "device_" .. dev)
	end
	function d.write(self, sec, value)
		if value then
			uci:set("freifunk", "wizard", "device_" .. dev, value)
			uci:save("freifunk")
		end
	end
end

function cbi_meshdhcp(dev)
	local dhcpmesh = f:field(Value, "dhcpmesh_" .. dev, dev:upper() .. " " .. translate("DHCP IP range"),
		translate("The IP range from which clients are assigned ip addresses (e.g. 10.1.2.1/28). If this is a range inside your mesh network range, then it will be announced as HNA. Any other range will use NAT. If left empty then the defaults from the community profile will be used."))
	dhcpmesh:depends("client_" .. dev, "1")
	dhcpmesh.rmempty = true
	function dhcpmesh.cfgvalue(self, section)
		return uci:get("freifunk", "wizard", "dhcpmesh_" .. dev)
	end
	function dhcpmesh.validate(self, value)
		local x = ip.IPv4(value)
		return ( x and x:prefix() <= 30 and x:minhost()) and x:string() or ""
	end
	function dhcpmesh.write(self, sec, value)
		uci:set("freifunk", "wizard", "dhcpmesh_" .. dev, value)
		uci:save("freifunk")
	end
end

function cbi_dhcp(dev)
	local client = f:field(Flag, "client_" .. dev, dev:upper() .. " " .. translate("Enable DHCP"), translate("DHCP will automatically assign ip addresses to clients"))
	client:depends("device_" .. dev, "1")
	client.rmempty = true
	function client.cfgvalue(self, section)
		return uci:get("freifunk", "wizard", "client_" .. dev)
	end
	function client.write(self, sec, value)
		uci:set("freifunk", "wizard", "client_" .. dev, value)
		uci:save("freifunk")
	end
end

function hbconf(dev)
	if has_hb then
		local ifacelist = uci:get_list("manager", "heartbeat", "interface") or {}
		table.insert(ifacelist,dev .. "dhcp")
		uci:set_list("manager", "heartbeat", "interface", ifacelist)
		uci:save("manager")
	end
end

function uci_radvd(n)
	uci:section("radvd", "interface", nil, {
		interface          =n,
		AdvSendAdvert      =1,
		AdvManagedFlag     =0,
		AdvOtherConfigFlag =0,
		ignore             =0
		})
	uci:section("radvd", "prefix", nil, {
		interface          =n,
		AdvOnLink          =1,
		AdvAutonomous      =1,
		AdvRouterAddr      =0,
		ignore             =0,
		})
	uci:save("radvd")
end

function uci_clean_radvd (n)
	uci:delete_all("radvd", "interface", {interface=n.."dhcp"})
	uci:delete_all("radvd", "interface", {interface=n})
	uci:delete_all("radvd", "prefix", {interface=n.."dhcp"})
	uci:delete_all("radvd", "prefix", {interface=n})
end


-------------------- View --------------------
f = SimpleForm("ffwizward", translate("Wizard"),
 translate("This wizard will assist you in setting up your router for Freifunk " ..
	"or another similar wireless community network."))

-- if password is not set or default then force the user to set a new one
if sys.exec("diff /rom/etc/passwd /etc/passwd") == "" then
	pw1 = f:field(Value, "pw1", translate("Password"))
	pw1.password = true
	pw1.rmempty = false

	pw2 = f:field(Value, "pw2", translate("Password confirmation"))
	pw2.password = true
	pw2.rmempty = false

	function pw2.validate(self, value, section)
		return pw1:formvalue(section) == value and value
	end
end

-- main netconfig

local cc = uci:get(community, "wifi_device", "country") or "DE"

main = f:field(Flag, "netconfig", translate("Configure network"), translate("Select this checkbox to configure your network interfaces."))

uci:foreach("wireless", "wifi-device", function(section)
	local device = section[".name"]
	local hwtype = section.type
	local syscc = section.country

	if not syscc then
		if hwtype == "atheros" then
			cc = sys.exec("grep -i '" .. cc .. "' /lib/wifi/cc_translate.txt |cut -d ' ' -f 2") or 0
			sys.exec("echo " .. cc .. " > /proc/sys/dev/" .. device .. "/countrycode")
		elseif hwtype == "mac80211" then
			sys.exec("iw reg set " .. cc)
		elseif hwtype == "broadcom" then
			sys.exec ("wlc country " .. cc)
		end
	else
		cc = syscc
	end

	cbi_netconf(device)		
	local chan = f:field(ListValue, "chan_" .. device, device:upper() .. " " .. translate("Channel"), translate("Your device and neighbouring nodes have to use the same channel."))
	chan:depends("device_" .. device, "1")
	chan.rmempty = true
	function chan.cfgvalue(self, section)
		return uci:get("freifunk", "wizard", "chan_" .. device)
	end
	chan:value('default')
	for _, f in ipairs(sys.wifi.channels(device)) do
		if not f.restricted then
			chan:value(f.channel)
		end
	end

	function chan.write(self, sec, value)
		if value then
			uci:set("freifunk", "wizard", "chan_" .. device, value)
			uci:save("freifunk")
		end
	end

	cbi_meship(device)
	if has_ipv6 then
		cbi_meship6(device)
	end
	cbi_dhcp(device)
	cbi_meshdhcp(device)
	local hwtype = section.type
	if hwtype == "atheros" then
		local vap = f:field(Flag, "vap_" .. device , " " .. translate("Virtual Access Point (VAP)"), translate("This will setup a new virtual wireless interface in Access Point mode."))
		vap:depends("client_" .. device, "1")
		vap.rmempty = false
		function vap.cfgvalue(self, section)
			return uci:get("freifunk", "wizard", "vap_" .. device)
		end
		function vap.write(self, sec, value)
			uci:set("freifunk", "wizard", "vap_" .. device, value)
			uci:save("freifunk")
		end
	end
end)

uci:foreach("network", "interface",	function(section)
	local device = section[".name"]
	local ifname = uci_state:get("network",device,"ifname")
	if device ~= "loopback" and not string.find(device, "gvpn")  and not string.find(device, "wifi") and not string.find(device, "wl") and not string.find(device, "wlan") and not string.find(device, "wireless") and not string.find(device, "radio") then
		cbi_netconf(device)
		cbi_meship(device)
		if has_ipv6 then
			cbi_meship6(device)
		end
		cbi_dhcp(device)
		cbi_meshdhcp(device)
	end
end)

share = f:field(Flag, "sharenet", "<b>" .. translate("Share your internet connection") .. "</b>", translate("Select this to allow others to use your connection to access the internet."))
share.rmempty = false
share:depends("netconfig", "1")
function share.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "share")
end
function share.write(self, section, value)
	uci:set("freifunk", "wizard", "share", value)
	uci:save("freifunk")
end

wanproto = f:field(ListValue, "wanproto", translate("Protocol"), translate ("The protocol to use for internet connectivity."))
wanproto:depends("sharenet", "1")
wanproto:value("static", translate("static", "static"))
wanproto:value("dhcp", translate("dhcp", "dhcp"))
if has_pppoe then wanproto:value("pppoe", "PPPoE") end
if has_pptp  then wanproto:value("pptp",  "PPTP")  end
function wanproto.cfgvalue(self, section)
	return uci:get("network", "wan", "proto") or "dhcp"
end
function wanproto.write(self, section, value)
	uci:set("network", "wan", "proto", value)
	uci:save("network")
end
wanip = f:field(Value, "wanipaddr", translate("IP address"))
wanip:depends("wanproto", "static")
function wanip.cfgvalue(self, section)
	return uci:get("network", "wan", "ipaddr")
end
function wanip.write(self, section, value)
	uci:set("network", "wan", "ipaddr", value)
	uci:save("network")
end
wannm = f:field(Value, "wannetmask", translate("Netmask"))
wannm:depends("wanproto", "static")
function wannm.cfgvalue(self, section)
	return uci:get("network", "wan", "netmask")
end
function wannm.write(self, section, value)
	uci:set("network", "wan", "netmask", value)
	uci:save("network")
end
wangw = f:field(Value, "wangateway", translate("Gateway"))
wangw:depends("wanproto", "static")
wangw.rmempty = true
function wangw.cfgvalue(self, section)
	return uci:get("network", "wan", "gateway")
end
function wangw.write(self, section, value)
	uci:set("network", "wan", "gateway", value)
	uci:save("network")
end
wandns = f:field(Value, "wandns", translate("DNS Server"))
wandns:depends("wanproto", "static")
wandns.rmempty = true
function wandns.cfgvalue(self, section)
	return uci:get("network", "wan", "dns")
end
function wandns.write(self, section, value)
	uci:set("network", "wan", "dns", value)
	uci:save("network")
end
wanusr = f:field(Value, "wanusername", translate("Username"))
wanusr:depends("wanproto", "pppoe")
wanusr:depends("wanproto", "pptp")
function wanusr.cfgvalue(self, section)
	return uci:get("network", "wan", "username")
end
function wanusr.write(self, section, value)
	uci:set("network", "wan", "username", value)
	uci:save("network")
end
wanpwd = f:field(Value, "wanpassword", translate("Password"))
wanpwd.password = true
wanpwd:depends("wanproto", "pppoe")
wanpwd:depends("wanproto", "pptp")
function wanpwd.cfgvalue(self, section)
	return uci:get("network", "wan", "password")
end
function wanpwd.write(self, section, value)
	uci:set("network", "wan", "password", value)
	uci:save("network")
end

wansec = f:field(Flag, "wansec", translate("Protect LAN"), translate("Check this to protect your LAN from other nodes or clients") .. " (" .. translate("recommended") .. ").")
wansec.default = "1"
wansec.rmempty = false
wansec:depends("wanproto", "static")
wansec:depends("wanproto", "dhcp")
function wansec.cfgvalue(self, section)
	return uci:get("freifunk", "wizard", "wan_security")
end
function wansec.write(self, section, value)
	uci:set("freifunk", "wizard", "wan_security", value)
	uci:save("freifunk")
end
if has_qos then
	wanqosdown = f:field(Value, "wanqosdown", translate("Limit download bandwidth"), translate("kbit/s"))
	wanqosdown:depends("sharenet", "1")
	function wanqosdown.cfgvalue(self, section)
		return uci:get("qos", "wan", "download")
	end
	function wanqosdown.write(self, section, value)
		uci:set("qos", "wan", "download", value)
		uci:save("qos")
	end
	wanqosup = f:field(Value, "wanqosup", translate("Limit upload bandwidth"), translate("kbit/s"))
	wanqosup:depends("sharenet", "1")
	function wanqosup.cfgvalue(self, section)
		return uci:get("qos", "wan", "upload")
	end
	function wanqosup.write(self, section, value)
		uci:set("qos", "wan", "upload", value)
		uci:save("qos")
	end
end

if has_l2gvpn then
	gvpn = f:field(Flag, "gvpn", translate("L2gvpn tunnel"), translate("Connect your node with other nodes with a tunnel via the internet."))
	gvpn.rmempty = false
	gvpn:depends("sharenet", "1")
	function gvpn.cfgvalue(self, section)
		return uci:get("freifunk", "wizard", "gvpn")
	end
	function gvpn.write(self, section, value)
		uci:set("freifunk", "wizard", "gvpn", value)
		uci:save("freifunk")
	end
	gvpnip = f:field(Value, "gvpnipaddr", translate("IP address"))
	gvpnip:depends("gvpn", "1")
	function gvpnip.cfgvalue(self, section)
		return uci:get("l2gvpn", "bbb", "ip") or uci:get("network", "gvpn", "ipaddr")
	end
	function gvpnip.validate(self, value)
		local x = ip.IPv4(value)
		return ( x and x:prefix() == 32 ) and x:string() or ""
	end
end

if has_hb then
	hb = f:field(Flag, "hb", translate("Heartbeat"), translate("Allow to transfer anonymous statistics about this node") .. " (" .. translate("recommended") .. ").")
	hb.rmempty = false
	hb:depends("netconfig", "1")
	function hb.cfgvalue(self, section)
		return uci:get("freifunk", "wizard", "hb")
	end
	function hb.write(self, section, value)
		uci:set("freifunk", "wizard", "hb", value)
		uci:save("freifunk")
	end
end

-------------------- Control --------------------
function f.handle(self, state, data)
	if state == FORM_VALID then
		local debug = uci:get("freifunk", "wizard", "debug")
		if debug == "1" then
			if data.pw1 then
				local stat = luci.sys.user.setpasswd("root", data.pw1) == 0
				if stat then
					f.message = translate("Password successfully changed")
				else
					f.errmessage = translate("Unknown Error")
				end
			end
			data.pw1 = nil
			data.pw2 = nil
			luci.http.redirect(luci.dispatcher.build_url(unpack(luci.dispatcher.context.requested.path), "system", "system"))
		else
			if data.pw1 then
				local stat = luci.sys.user.setpasswd("root", data.pw1) == 0
			end
			data.pw1 = nil
			data.pw2 = nil
			uci:commit("freifunk")
			uci:commit("wireless")
			uci:commit("network")
			uci:commit("dhcp")
			uci:commit("luci_splash")
			uci:commit("firewall")
			uci:commit("system")
			uci:commit("olsrd")
			uci:commit("manager")
			if has_autoipv6 then
				uci:commit("autoipv6")
			end
			if has_qos then
				uci:commit("qos")
			end
			if has_l2gvpn then
				uci:commit("l2gvpn")
			end
			if has_radvd then
				uci:commit("radvd")
			end

			sys.exec("for s in network dnsmasq luci_splash firewall olsrd radvd l2gvpn; do [ -x /etc/init.d/$s ] && /etc/init.d/$s restart;done > /dev/null &" )
			luci.http.redirect(luci.dispatcher.build_url(luci.dispatcher.context.path[1], "freifunk", "ffwizard"))
		end
		return false
	elseif state == FORM_INVALID then
		self.errmessage = "Ungültige Eingabe: Bitte die Formularfelder auf Fehler prüfen."
	end
	return true
end

local function _strip_internals(tbl)
	tbl = tbl or {}
	for k, v in pairs(tbl) do
		if k:sub(1, 1) == "." then
			tbl[k] = nil
		end
	end
	return tbl
end
-- Configure Freifunk checked
function main.write(self, section, value)
	if value == "0" then
		uci:set("freifunk", "wizard", "netconfig", "0")
		uci:save("freifunk")
		return
	end
	-- Collect IP-Address
	uci:set("freifunk", "wizard", "net", uci:get_first(community, "community", "mesh_network"))
        uci:save("freifunk")

	-- Invalidate fields
	if not community then
		net.tag_missing[section] = true
		return
	end

	uci:set("freifunk", "wizard", "netconfig", "1")
	uci:save("freifunk")

	local netname = "wireless"
	local network
	network = ip.IPv4(uci:get_first(community, "community", "mesh_network") or "104.0.0.0/8")

	-- Cleanup
	uci:delete_all("firewall","zone", {name="freifunk"})
	uci:delete_all("firewall","forwarding", {dest="freifunk"})
	uci:delete_all("firewall","forwarding", {src="freifunk"})
	uci:delete_all("firewall","rule", {dest="freifunk"})
	uci:delete_all("firewall","rule", {src="freifunk"})
	uci:save("firewall")
	-- Create firewall zone and add default rules (first time)
	-- firewall_create_zone("name"    , "input" , "output", "forward ", Masqurade)
	local newzone = tools.firewall_create_zone("freifunk", "ACCEPT", "ACCEPT", "REJECT"  , true)
	if newzone then
		uci:foreach("freifunk", "fw_forwarding", function(section)
			uci:section("firewall", "forwarding", nil, section)
		end)
		uci:foreach(community, "fw_forwarding", function(section)
			uci:section("firewall", "forwarding", nil, section)
		end)

		uci:foreach("freifunk", "fw_rule", function(section)
			uci:section("firewall", "rule", nil, section)
		end)
		uci:foreach(community, "fw_rule", function(section)
			uci:section("firewall", "rule", nil, section)
		end)
	end
	uci:save("firewall")
	if has_hb then
		uci:delete("manager", "heartbeat", "interface")
		uci:save("manager")
	end
	-- Delete olsrdv4
	uci:delete_all("olsrd", "olsrd")
	local olsrbase
	olsrbase = uci:get_all("freifunk", "olsrd") or {}
	util.update(olsrbase, uci:get_all(community, "olsrd") or {})
	if has_ipv6 then
		olsrbase.IpVersion='6and4'
	else
		olsrbase.IpVersion='4'
	end
	uci:section("olsrd", "olsrd", nil, olsrbase)
	-- Delete olsrdv4 old p2pd settings
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_mdns.so.1.0.0"})
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_p2pd.so.0.1.0"})
	-- Write olsrdv4 new p2pd settings
	uci:section("olsrd", "LoadPlugin", nil, {
		library     = "olsrd_p2pd.so.0.1.0",
		P2pdTtl     = 10,
		UdpDestPort = "224.0.0.251 5353",
		ignore      = 1,
	})
	-- Delete http plugin
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_httpinfo.so.0.1"})

	-- Delete olsrdv4 old interface
	uci:delete_all("olsrd", "Interface")
	uci:delete_all("olsrd", "Hna4")
	-- Create wireless ip4/ip6 and firewall config
	uci:foreach("wireless", "wifi-device",
	function(sec)
		local device = sec[".name"]
		if not luci.http.formvalue("cbid.ffwizward.1.device_" .. device) then
			return
		end
		node_ip = luci.http.formvalue("cbid.ffwizward.1.meship_" .. device) and ip.IPv4(luci.http.formvalue("cbid.ffwizward.1.meship_" .. device))
		if has_ipv6 then
			node_ip6 = luci.http.formvalue("cbid.ffwizward.1.meship6_" .. device) and ip.IPv6(luci.http.formvalue("cbid.ffwizward.1.meship6_" .. device))
		end
		if not node_ip or not network or not network:contains(node_ip) then
			meship.tag_missing[section] = true
			node_ip = nil
			return
		end
		-- rename the wireless interface s/wifi/wireless/
		local nif
		if string.find(device, "wifi") then
			nif = string.gsub(device,"wifi", netname)
		elseif string.find(device, "wl") then
			nif = string.gsub(device,"wl", netname)
		elseif string.find(device, "wlan") then
			nif = string.gsub(device,"wlan", netname)
		elseif string.find(device, "radio") then
			nif = string.gsub(device,"radio", netname)
		end
		-- Cleanup
		tools.wifi_delete_ifaces(device)
		-- tools.network_remove_interface(device)
		uci:delete("network", device .. "dhcp")
		uci:delete("network", device)
		tools.firewall_zone_remove_interface("freifunk", device)
		-- tools.network_remove_interface(nif)
		uci:delete("network", nif .. "dhcp")
		uci:delete("network", nif)
		tools.firewall_zone_remove_interface("freifunk", nif)
		-- Delete old dhcp
		uci:delete("dhcp", device)
		uci:delete("dhcp", device .. "dhcp")
		uci:delete("dhcp", nif)
		uci:delete("dhcp", nif .. "dhcp")
		-- Delete old splash
		uci:delete_all("luci_splash", "iface", {network=device.."dhcp", zone="freifunk"})
		uci:delete_all("luci_splash", "iface", {network=nif.."dhcp", zone="freifunk"})
		-- Delete old radvd
		if has_radvd then
			uci_clean_radvd(nif)
		end
		-- New Config
		-- Tune wifi device
		local ssid = uci:get_first(community, "community", "ssid") or "olsr.freifunk.net"
		local devconfig = uci:get_all("freifunk", "wifi_device")
		util.update(devconfig, uci:get_all(community, "wifi_device") or {})
		local channel = luci.http.formvalue("cbid.ffwizward.1.chan_" .. device)
		local hwmode = "11bg"
		local bssid = uci:get_all(community, "wifi_iface", "bssid") or "02:CA:FF:EE:BA:BE"
		local mrate = 5500
		devconfig.diversity = sec.diversity or "1"
		if sec.txantenna then
			devconfig.txantenna = sec.txantenna
		end
                if sec.rxantenna then
                        devconfig.rxantenna = sec.rxantenna
                end

		-- set bssid, see https://kifuse02.pberg.freifunk.net/moin/channel-bssid-essid for schema
		if channel and channel ~= "default" then
			if devconfig.channel ~= channel then
				devconfig.channel = channel
				local chan = tonumber(channel)
				if chan >= 0 and chan < 10 then
					bssid = channel .. "2:CA:FF:EE:BA:BE"
				elseif chan == 10 then 
					bssid = "02:CA:FF:EE:BA:BE" 
				elseif chan >= 11 and chan <= 14 then
					bssid = string.format("%X",channel) .. "2:CA:FF:EE:BA:BE"
				elseif chan >= 36 and chan <= 64 then
					hwmode = "11a"
					mrate = ""
					bssid = "00:" .. channel ..":CA:FF:EE:EE"
				elseif chan >= 100 and chan <= 140 then
					hwmode = "11a"
					mrate = ""
					bssid = "01:" .. string.sub(channel, 2) .. ":CA:FF:EE:EE"
				end
				devconfig.hwmode = hwmode
			end
			devconfig.country = cc
			ssid = ssid .. " - ch" .. channel
		end
		uci:tset("wireless", device, devconfig)
		-- Create wifi iface
		local ifconfig = uci:get_all("freifunk", "wifi_iface")
		util.update(ifconfig, uci:get_all(community, "wifi_iface") or {})
		ifconfig.device = device
		ifconfig.network = nif
		ifconfig.ssid = ssid
		ifconfig.bssid = bssid
		ifconfig.encryption="none"
		-- Read Preset 
		local netconfig = uci:get_all("freifunk", "interface")
		util.update(netconfig, uci:get_all(community, "interface") or {})
		netconfig.proto = "static"
		netconfig.ipaddr = node_ip:string()
		if has_ipv6 then
			netconfig.ip6addr = node_ip6:string()
		end
		uci:section("network", "interface", nif, netconfig)
		if has_radvd then
			uci_radvd(nif)
		end
		tools.firewall_zone_add_interface("freifunk", nif)
		uci:save("firewall")
		-- Write new olsrv4 interface
		local olsrifbase = uci:get_all("freifunk", "olsr_interface")
		util.update(olsrifbase, uci:get_all(community, "olsr_interface") or {})
		olsrifbase.interface = nif
		olsrifbase.ignore    = "0"
		uci:section("olsrd", "Interface", nil, olsrifbase)
		-- Collect MESH DHCP IP NET
		local client = luci.http.formvalue("cbid.ffwizward.1.client_" .. device)
		if client then
			local dhcpmeshnet = luci.http.formvalue("cbid.ffwizward.1.dhcpmesh_" .. device) and ip.IPv4(luci.http.formvalue("cbid.ffwizward.1.dhcpmesh_" .. device))
			hbconf(nif)
			if dhcpmeshnet then
				if not dhcpmeshnet:minhost() or not dhcpmeshnet:mask() then
					dhcpmesh.tag_missing[section] = true
					dhcpmeshnet = nil
					return
				end
				dhcp_ip = dhcpmeshnet:minhost():string()
				dhcp_mask = dhcpmeshnet:mask():string()
				dhcp_network = dhcpmeshnet:network():string()
				uci:section("olsrd", "Hna4", nil, {
					netmask  = dhcp_mask,
					netaddr  = dhcp_network
				})
				uci:foreach("olsrd", "LoadPlugin",
					function(s)		
						if s.library == "olsrd_p2pd.so.0.1.0" then
							uci:set("olsrd", s['.name'], "ignore", "0")
							local nonolsr = uci:get("olsrd", s['.name'], "NonOlsrIf") or ""
							vap = luci.http.formvalue("cbid.ffwizward.1.vap_" .. device)
							if vap then
								nonolsr = nif.."dhcp "..nonolsr
							else
								nonolsr = nif.." "..nonolsr
							end
							uci:set("olsrd", s['.name'], "NonOlsrIf", nonolsr)
						end
					end)
			else
				gen_dhcp_range(netconfig.ipaddr)
			end
			if dhcp_ip and dhcp_mask then
				-- Create alias
				local aliasbase = uci:get_all("freifunk", "alias")
				util.update(aliasbase, uci:get_all(community, "alias") or {})
				aliasbase.ipaddr = dhcp_ip
				aliasbase.netmask = dhcp_mask
				aliasbase.proto = "static"
				vap = luci.http.formvalue("cbid.ffwizward.1.vap_" .. device)
				if vap then
					uci:section("network", "interface", nif .. "dhcp", aliasbase)
					uci:section("wireless", "wifi-iface", nil, {
						device     =device,
						mode       ="ap",
						encryption ="none",
						network    =nif .. "dhcp",
						ssid       ="AP-" .. ssid
					})
					if has_radvd then
						uci_radvd(nif .. "dhcp")
					end
					tools.firewall_zone_add_interface("freifunk", nif .. "dhcp")
					uci:save("wireless")
					ifconfig.mcast_rate = nil
					ifconfig.encryption="none"
				else
					aliasbase.interface = nif
					uci:section("network", "alias", nif .. "dhcp", aliasbase)
				end
				-- Create dhcp
				local dhcpbase = uci:get_all("freifunk", "dhcp")
				util.update(dhcpbase, uci:get_all(community, "dhcp") or {})
				dhcpbase.interface = nif .. "dhcp"
				dhcpbase.force = 1
				uci:section("dhcp", "dhcp", nif .. "dhcp", dhcpbase)
				uci:set_list("dhcp", nif .. "dhcp", "dhcp_option", "119,olsr")
				-- Create firewall settings
				uci:delete_all("firewall", "rule", {
					src="freifunk",
					proto="udp",
					dest_port="53"
				})
				uci:section("firewall", "rule", nil, {
					src="freifunk",
					proto="udp",
					dest_port="53",
					target="ACCEPT"
				})
				uci:delete_all("firewall", "rule", {
					src="freifunk",
					proto="udp",
					src_port="68",
					dest_port="67"
				})
				uci:section("firewall", "rule", nil, {
					src="freifunk",
					proto="udp",
					src_port="68",
					dest_port="67",
					target="ACCEPT"
				})
				uci:delete_all("firewall", "rule", {
					src="freifunk",
					proto="tcp",
					dest_port="8082",
				})
				uci:section("firewall", "rule", nil, {
					src="freifunk",
					proto="tcp",
					dest_port="8082",
					target="ACCEPT"
				})
				-- Register splash
				uci:section("luci_splash", "iface", nil, {network=nif.."dhcp", zone="freifunk"})
				uci:save("luci_splash")
				-- Make sure that luci_splash is enabled
				sys.init.enable("luci_splash")
			end
		else
			-- Delete old splash
			uci:delete_all("luci_splash", "iface", {network=device.."dhcp", zone="freifunk"})
		end
		--Write Ad-Hoc wifi section after AP wifi section
		uci:section("wireless", "wifi-iface", nil, ifconfig)
		uci:save("network")
		uci:save("wireless")
		uci:save("network")
		uci:save("firewall")
		uci:save("dhcp")
	end)
	-- Create wired ip and firewall config
	uci:foreach("network", "interface",
		function(sec)
		local device = sec[".name"]
		if not luci.http.formvalue("cbid.ffwizward.1.device_" .. device) then
			return
		end
		if device ~= "loopback" and not string.find(device, "wifi") and not string.find(device, "wl") and not string.find(device, "wlan") and not string.find(device, "wireless") and not string.find(device, "radio") then
			local node_ip
			node_ip = luci.http.formvalue("cbid.ffwizward.1.meship_" .. device) and ip.IPv4(luci.http.formvalue("cbid.ffwizward.1.meship_" .. device))
			if has_ipv6 then
				node_ip6 = luci.http.formvalue("cbid.ffwizward.1.meship6_" .. device) --and ip.IPv6(luci.http.formvalue("cbid.ffwizward.1.meship6_" .. device))
			end
			if not node_ip or not network or not network:contains(node_ip) then
				meship.tag_missing[section] = true
				node_ip = nil
				return
			end
			-- Cleanup
			tools.firewall_zone_remove_interface(device, device)
			uci:delete_all("firewall","zone", {name=device})
			uci:delete_all("firewall","forwarding", {src=device})
			uci:delete_all("firewall","forwarding", {dest=device})
			uci:delete("network", device .. "dhcp")
			-- Delete old dhcp
			uci:delete("dhcp", device)
			uci:delete("dhcp", device .. "dhcp")
			-- Delete old splash
			uci:delete_all("luci_splash", "iface", {network=device.."dhcp", zone="freifunk"})
			if has_radvd then
				uci_clean_radvd(device)
			end
			-- New Config
			local netconfig = uci:get_all("freifunk", "interface")
			util.update(netconfig, uci:get_all(community, "interface") or {})
			netconfig.proto = "static"
			netconfig.ipaddr = node_ip:string()
			if has_ipv6 then
				netconfig.ip6addr = node_ip6:string()
			end
			uci:section("network", "interface", device, netconfig)
			uci:save("network")
			if has_radvd then
				uci_radvd(device)
			end
			tools.firewall_zone_add_interface("freifunk", device)
			uci:save("firewall")
			-- Write new olsrv4 interface
			local olsrifbase = uci:get_all("freifunk", "olsr_interface")
			util.update(olsrifbase, uci:get_all(community, "olsr_interface") or {})
			olsrifbase.interface = device
			olsrifbase.ignore    = "0"
			uci:section("olsrd", "Interface", nil, olsrifbase)
			olsrifbase.Mode = 'ether'
			-- Collect MESH DHCP IP NET
			local client = luci.http.formvalue("cbid.ffwizward.1.client_" .. device)
			if client then
				local dhcpmeshnet = luci.http.formvalue("cbid.ffwizward.1.dhcpmesh_" .. device) and ip.IPv4(luci.http.formvalue("cbid.ffwizward.1.dhcpmesh_" .. device))
				hbconf(device)

				if dhcpmeshnet then
					if not dhcpmeshnet:minhost() or not dhcpmeshnet:mask() then
						dhcpmesh.tag_missing[section] = true
						dhcpmeshnet = nil
						return
					end
					dhcp_ip = dhcpmeshnet:minhost():string()
					dhcp_mask = dhcpmeshnet:mask():string()
					dhcp_network = dhcpmeshnet:network():string()
					uci:section("olsrd", "Hna4", nil, {
						netmask  = dhcp_mask,
						netaddr  = dhcp_network
					})
					uci:foreach("olsrd", "LoadPlugin",
						function(s)		
							if s.library == "olsrd_p2pd.so.0.1.0" then
								uci:set("olsrd", s['.name'], "ignore", "0")
								local nonolsr = uci:get("olsrd", s['.name'], "NonOlsrIf") or ""
								uci:set("olsrd", s['.name'], "NonOlsrIf", device .." ".. nonolsr)
							end
						end)
				else
					gen_dhcp_range(netconfig.ipaddr)
				end
				if dhcp_ip and dhcp_mask then
					-- Create alias
					local aliasbase = uci:get_all("freifunk", "alias")
					util.update(aliasbase, uci:get_all(community, "alias") or {})
					aliasbase.interface = device
					aliasbase.ipaddr = dhcp_ip
					aliasbase.netmask = dhcp_mask
					aliasbase.proto = "static"
					uci:section("network", "alias", device .. "dhcp", aliasbase)
					-- Create dhcp
					local dhcpbase = uci:get_all("freifunk", "dhcp")
					util.update(dhcpbase, uci:get_all(community, "dhcp") or {})
					dhcpbase.interface = device .. "dhcp"
					dhcpbase.force = 1
					uci:section("dhcp", "dhcp", device .. "dhcp", dhcpbase)
					uci:set_list("dhcp", device .. "dhcp", "dhcp_option", "119,olsr")
					-- Create firewall settings
					uci:delete_all("firewall", "rule", {
						src="freifunk",
						proto="udp",
						dest_port="53"
					})
					uci:section("firewall", "rule", nil, {
						src="freifunk",
						proto="udp",
						dest_port="53",
						target="ACCEPT"
					})
					uci:delete_all("firewall", "rule", {
						src="freifunk",
						proto="udp",
						src_port="68",
						dest_port="67"
					})
					uci:section("firewall", "rule", nil, {
						src="freifunk",
						proto="udp",
						src_port="68",
						dest_port="67",
						target="ACCEPT"
					})
					uci:delete_all("firewall", "rule", {
						src="freifunk",
						proto="tcp",
						dest_port="8082",
					})
					uci:section("firewall", "rule", nil, {
						src="freifunk",
						proto="tcp",
						dest_port="8082",
						target="ACCEPT"
					})
					-- Register splash
					uci:section("luci_splash", "iface", nil, {network=device.."dhcp", zone="freifunk"})
					uci:save("luci_splash")
					-- Make sure that luci_splash is enabled
					sys.init.enable("luci_splash")
				end
			end
			uci:save("wireless")
			uci:save("network")
			uci:save("firewall")
			uci:save("dhcp")
		end
	end)
	--enable radvd
	if has_radvd then
		sys.init.enable("radvd")
	end
	-- Enforce firewall include
	local has_include = false
	uci:foreach("firewall", "include",
		function(section)
			if section.path == "/etc/firewall.freifunk" then
				has_include = true
			end
		end)

	if not has_include then
		uci:section("firewall", "include", nil,
			{ path = "/etc/firewall.freifunk" })
	end
	-- Allow state: invalid packets
	uci:foreach("firewall", "defaults",
		function(section)
			uci:set("firewall", section[".name"], "drop_invalid", "0")
		end)

	-- Prepare advanced config
	local has_advanced = false
	uci:foreach("firewall", "advanced",
		function(section) has_advanced = true end)

	if not has_advanced then
		uci:section("firewall", "advanced", nil,
			{ tcp_ecn = "0", ip_conntrack_max = "8192", tcp_westwood = "1" })
	end
	uci:save("wireless")
	uci:save("network")
	uci:save("firewall")
	uci:save("dhcp")

	if has_hb then
		local dhcphb = hb:formvalue(section)
		if dhcphb then
			uci:set("manager", "heartbeat", "enabled", "1")
			-- Make sure that heartbeat is enabled
			sys.init.enable("machash")
		else
			uci:set("manager", "heartbeat", "enabled", "0")
			-- Make sure that heartbeat is enabled
			sys.init.disable("machash")
		end
		uci:save("manager")
	end

	uci:foreach("system", "system",
		function(s)
			-- Make crond silent
			uci:set("system", s['.name'], "cronloglevel", "10")
			-- Make set timzone and zonename
			uci:set("system", s['.name'], "zonename", "Europe/Berlin")
			uci:set("system", s['.name'], "timezone", 'CET-1CEST,M3.5.0,M10.5.0/3')
		end)
	uci:save("system")

	-- Delete old watchdog settings
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_watchdog.so.0.1"})
	-- Write new watchdog settings
	uci:section("olsrd", "LoadPlugin", nil, {
		library  = "olsrd_watchdog.so.0.1",
		file     = "/var/run/olsrd.watchdog",
		interval = "30"
	})

	-- Delete old nameservice settings
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_nameservice.so.0.3"})
	-- Write new nameservice settings
	uci:section("olsrd", "LoadPlugin", nil, {
		library     = "olsrd_nameservice.so.0.3",
		suffix      = "." .. suffix ,
		hosts_file  = "/var/etc/hosts.olsr",
		latlon_file = "/var/run/latlon.js",
		lat         = lat and string.format("%.15f", lat) or "",
		lon         = lon and string.format("%.15f", lon) or "",
		services_file = "/var/etc/services.olsr"
	})

	-- Import hosts and set domain
	uci:foreach("dhcp", "dnsmasq", function(s)
		uci:set_list("dhcp", s[".name"], "addnhosts", "/var/etc/hosts.olsr")
		uci:set("dhcp", s[".name"], "local", "/" .. suffix .. "/")
		uci:set("dhcp", s[".name"], "domain", suffix)
	end)

	-- Make sure that OLSR is enabled
	sys.init.enable("olsrd")

	uci:save("olsrd")
	uci:save("dhcp")
	-- Import hosts and set domain
	if has_ipv6 then
	        uci:foreach("dhcp", "dnsmasq", function(s)
	                uci:set_list("dhcp", s[".name"], "addnhosts", {"/var/etc/hosts.olsr","/var/etc/hosts.olsr.ipv6"})
	        end)
	else
	        uci:foreach("dhcp", "dnsmasq", function(s)
	                uci:set_list("dhcp", s[".name"], "addnhosts", "/var/etc/hosts.olsr")
        	end)
	end

	uci:save("dhcp")

	-- Internet sharing
	local share_value = share:formvalue(section)
	if share_value == "1" then
		uci:set("freifunk", "wizard", "netconfig", "1")
		uci:section("firewall", "forwarding", nil, {src="freifunk", dest="wan"})

		if has_autoipv6 then
			-- Set autoipv6 tunnel mode
			uci:set("autoipv6", "olsr_node", "enable", "0")
			uci:set("autoipv6", "tunnel", "enable", "1")
			uci:save("autoipv6")
		end

		-- Delete/Disable gateway plugin
		uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_dyn_gw.so.0.5"})
		uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_dyn_gw_plain.so.0.4"})
		-- Enable gateway_plain plugin
		uci:section("olsrd", "LoadPlugin", nil, {library="olsrd_dyn_gw_plain.so.0.4"})
		sys.exec("chmod +x /etc/init.d/freifunk-p2pblock")
		sys.init.enable("freifunk-p2pblock")
		sys.init.enable("qos")
		sys.exec('grep wan /etc/crontabs/root >/dev/null || echo "0 6 * * * 	ifup wan" >> /etc/crontabs/root')

		if wansec:formvalue(section) == "1" then
			uci:foreach("firewall", "zone",
				function(s)		
					if s.name == "wan" then
						uci:set("firewall", s['.name'], "local_restrict", "1")
						return false
					end
				end)
		end
	else
		uci:set("freifunk", "wizard", "netconfig", "0")
		uci:save("freifunk")
		if has_autoipv6 then
			-- Set autoipv6 olsrd mode
			uci:set("autoipv6", "olsr_node", "enable", "1")
			uci:set("autoipv6", "tunnel", "enable", "0")
			uci:save("autoipv6")
		end
		-- Delete gateway plugins
		uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_dyn_gw.so.0.5"})
		uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_dyn_gw_plain.so.0.4"})
		-- Disable gateway_plain plugin
		uci:section("olsrd", "LoadPlugin", nil, {
			library     = "olsrd_dyn_gw_plain.so.0.4",
			ignore      = 1,
		})
		sys.init.disable("freifunk-p2pblock")
		sys.init.disable("qos")
		sys.exec("chmod -x /etc/init.d/freifunk-p2pblock")
		uci:delete_all("firewall", "forwarding", {src="freifunk", dest="wan"})
		uci:foreach("firewall", "zone",
			function(s)		
				if s.name == "wan" then
					uci:delete("firewall", s['.name'], "local_restrict")
					return false
				end
			end)
	end
	-- Write gvpn dummy interface
	if has_l2gvpn then
		if gvpn then
			local vpn = gvpn:formvalue(section)
			if vpn then
				uci:delete_all("l2gvpn", "l2gvpn")
				uci:delete_all("l2gvpn", "node")
				uci:delete_all("l2gvpn", "supernode")
				-- Write olsr tunnel interface options
				local olsr_gvpnifbase = uci:get_all("freifunk", "olsr_gvpninterface")
				util.update(olsr_gvpnifbase, uci:get_all(community, "olsr_gvpninterface") or {})
				uci:section("olsrd", "Interface", nil, olsr_gvpnifbase)
				local vpnip = gvpnip:formvalue(section)
				local gvpnif = uci:get_all("freifunk", "gvpn_node")
				util.update(gvpnif, uci:get_all(community, "gvpn_node") or {})
				if gvpnif and gvpnif.tundev and vpnip then
					uci:section("network", "interface", gvpnif.tundev, {
						ifname  =gvpnif.tundev ,
						proto   ="static" ,
						ipaddr  =vpnip ,
						netmask =gvpnif.subnet or "255.255.255.192" ,
					})
					gvpnif.ip=""
					gvpnif.subnet=""
					gvpnif.up=""
					gvpnif.down=""
					gvpnif.mac="00:00:48:"..string.format("%X",string.gsub( vpnip, ".*%." , "" ))..":00:00"
					tools.firewall_zone_add_interface("freifunk", gvpnif.tundev)
					uci:section("l2gvpn", "node" , gvpnif.community , gvpnif)
					uci:save("network")
					uci:save("l2gvpn")
					uci:save("firewall")
					uci:save("olsrd")
					sys.init.enable("l2gvpn")
				end
			else
				-- Disable l2gvpn
				sys.exec("/etc/init.d/l2gvpn stop")
				sys.init.disable("l2gvpn")
			end
		end
	end

	uci:save("freifunk")
	uci:save("firewall")
	uci:save("olsrd")
	uci:save("system")
end

return f

