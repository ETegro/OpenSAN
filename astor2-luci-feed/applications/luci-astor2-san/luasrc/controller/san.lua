module("luci.controller.san", package.seeall)

function index()
	entry({"san"}, call("physical_list"), "San", 10)
end

local phys_list_result =
	{ ["0:1"] = { model = "WDC WD5000BPVT-0",
		revision = "01.0",
		serial = "000003HYJJK",
		size = 476940.02,
	state = "free" },
	["0:2"] = { model = "Transcend 8GB",
		revision = "8.07",
		serial = "",
		size = 7664.00,
		state = "free" },
	["1:0"] = { model = "Kingston 16GB",
		revision = "9.65",
		serial = "rev5",
		size = 15328.00,
		state = "free" },
	["1:1"] = { model = "Samsung 16GB",
		revision = "8.5",
		serial = "rev1",
		size = 15328.00,
		state = "free" } }

function physical_list()
	luci.template.render("einarc/einarc", {phys_list_result=phys_list_result})
end
