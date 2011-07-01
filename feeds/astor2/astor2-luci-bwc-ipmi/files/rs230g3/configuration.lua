module( "luci.controller.san_monitoring_configuration", package.seeall )

configuration = {
	front = {},
	rear = {},
	motherboard = {
		["CPU1 Temp"] = "CPU0",
		["CPU2 Temp"] = "CPU1",
		["DIMM Temp"] = "MEM-BLOCK1"
	}
}
