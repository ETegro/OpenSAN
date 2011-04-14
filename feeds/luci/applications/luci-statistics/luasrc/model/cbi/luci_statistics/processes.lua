--[[

Luci configuration model for statistics - collectd processes plugin configuration
(c) 2008 Freifunk Leipzig / Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

$Id: processes.lua 6060 2010-04-13 20:42:26Z jow $

]]--

m = Map("luci_statistics",
	translate("Processes Plugin Configuration"),
	translate(
		"The processes plugin collects informations like cpu time, " ..
		"page faults and memory usage of selected processes."
	))

-- collectd_processes config section
s = m:section( NamedSection, "collectd_processes", "luci_statistics" )

-- collectd_processes.enable
enable = s:option( Flag, "enable", translate("Enable this plugin") )
enable.default = 0

-- collectd_processes.processes (Process)
processes = s:option( Value, "Processes", translate("Monitor processes") )
processes.default = "olsrd bmxd httpd dnsmasq dropbear tinc"
processes:depends( "enable", 1 )

return m
