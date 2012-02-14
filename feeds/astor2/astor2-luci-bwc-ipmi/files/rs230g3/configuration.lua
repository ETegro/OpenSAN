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
	[1]  = "ENC1",
	[2]  = "ENC2",
	[3]  = "ENC3",
	[4]  = "ENC4",
	[5]  = "ENC5",
	[6]  = "ENC6",
	[7]  = "ENC7",
	[8]  = "ENC8",
	[9]  = "ENC9",
	[10] = "ENC10",
	[11] = "ENC11",
	[12] = "ENC12"
}

expanders = {
	["internal"] = "SASX28 A.1",
	["jbod"] = "DNS1400-01"
}
