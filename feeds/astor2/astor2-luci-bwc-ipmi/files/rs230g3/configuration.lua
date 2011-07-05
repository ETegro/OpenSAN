module( "luci.controller.san_monitoring_configuration", package.seeall )

configuration = {
	front = {
		["FP Temp"] = "FP"
	},
	rear = {
		["PSU Output"] = "PSU0",
		["PSU1 Output"] = "PSU1",
		["BP Fan1"] = "FAN0",
		["BP Fan2"] = "FAN1",
		["BP Fan3"] = "FAN2",
		["BP Temp"] = "BP"
	},
	motherboard = {
		["CPU1 Temp"] = "CPU0",
		["CPU2 Temp"] = "CPU1",
		["DIMM Temp"] = "MEM-BLOCK",
		["MB Temp"] = "MB"
	}
}

network = {
	eth0 = "ETH0",
	eth1 = "ETH1",
	eth2 = "ETH2"
}
