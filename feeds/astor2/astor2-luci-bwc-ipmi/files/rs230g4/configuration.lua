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

enclosures = {
	[0] = "ENC12",
	[1] = "ENC11",
	[2] = "ENC10",
	[3] = "ENC9",
	[4] = "ENC8",
	[5] = "ENC7",
	[6] = "ENC6",
	[7] = "ENC5",
	[8] = "ENC4",
	[9] = "ENC3",
	[10] = "ENC2",
	[11] = "ENC1"
}

expanders = {
	["internal"] = "BACKPLANE",
	["jbod"] = { "DNS1400-01", "JS2-01" }
}

jbods = {
	["DNS1400-01"] = { 6, 4 },
	["JS2-01"] = { 3, 4 }
}
