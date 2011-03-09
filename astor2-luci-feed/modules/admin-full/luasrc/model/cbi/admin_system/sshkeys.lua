--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: sshkeys.lua 5448 2009-10-31 15:54:11Z jow $
]]--
local keyfile = "/etc/dropbear/authorized_keys" 

f = SimpleForm("sshkeys", translate("<abbr title=\"Secure Shell\">SSH</abbr>-Keys"), translate("Here you can paste public <abbr title=\"Secure Shell\">SSH</abbr>-Keys (one per line) for <abbr title=\"Secure Shell\">SSH</abbr> public-key authentication."))

t = f:field(TextValue, "keys")
t.rmempty = true
t.rows = 10
function t.cfgvalue()
	return nixio.fs.readfile(keyfile) or ""
end

function f.handle(self, state, data)
	if state == FORM_VALID then
		if data.keys then
			nixio.fs.writefile(keyfile, data.keys:gsub("\r\n", "\n"))
		end
	end
	return true
end

return f
