--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 5485 2009-11-01 14:24:04Z jow $
]]--

module("luci.controller.mini.index", package.seeall)

function index()
	luci.i18n.loadc("base")
	local i18n = luci.i18n.translate

	local root = node()
	if not root.lock then
		root.target = alias("mini")
		root.index = true
	end
	
	entry({"about"}, template("about"))
	
	local page   = entry({"mini"}, alias("mini", "index"), i18n("Essentials"), 10)
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.index = true
	
	entry({"mini", "index"}, alias("mini", "index", "index"), i18n("Overview"), 10).index = true
	entry({"mini", "index", "index"}, form("mini/index"), i18n("General"), 1).ignoreindex = true
	entry({"mini", "index", "luci"}, cbi("mini/luci", {autoapply=true}), i18n("Settings"), 10)
	entry({"mini", "index", "logout"}, call("action_logout"), i18n("Logout"))
end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
	luci.http.redirect(luci.dispatcher.build_url())
end
