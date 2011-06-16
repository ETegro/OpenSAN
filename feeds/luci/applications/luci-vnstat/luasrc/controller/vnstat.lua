module("luci.controller.vnstat", package.seeall)

function index()
	require("luci.i18n").loadc("vnstat")
	local i18n = luci.i18n.translate

	entry({"admin", "status", "vnstat"}, alias("admin", "status", "vnstat", "graphs"), i18n("VnStat Traffic Monitor"), 90).i18n = "vnstat"
	entry({"admin", "status", "vnstat", "graphs"}, template("vnstat"), i18n("Graphs"), 1)
	entry({"admin", "status", "vnstat", "config"}, cbi("vnstat"), i18n("Configuration"), 2)

	entry({"mini", "network", "vnstat"}, alias("mini", "network", "vnstat", "graphs"), i18n("VnStat Traffic Monitor"), 90).i18n = "vnstat"
	entry({"mini", "network", "vnstat", "graphs"}, template("vnstat"), i18n("Graphs"), 1)
	entry({"mini", "network", "vnstat", "config"}, cbi("vnstat"), i18n("Configuration"), 2)
end
