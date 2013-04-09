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
	[0] = "ENC1",
	[1] = "ENC2",
	[2] = "ENC3",
	[3] = "ENC4",
	[4] = "ENC5",
	[5] = "ENC6",
	[6] = "ENC7",
	[7] = "ENC8",
	[8] = "ENC9",
	[9] = "ENC10",
	[10] = "ENC11",
	[11] = "ENC12"
}

expanders = {
	["internal"] = "SASX28 A.1",
	["jbod"] = { "DNS1400-01", "JS2-01" }
}

jbods = {
	["DNS1400-01"] = { 6, 4 },
	["JS2-01"] = { 3, 4 }
}
