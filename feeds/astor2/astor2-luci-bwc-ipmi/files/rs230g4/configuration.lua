module( "luci.controller.san_monitoring_configuration", package.seeall )

configuration = {
	front = {
		["BP_Temp"] = "FP"
	},
	rear = {
		["PSU Output"] = "PSU0",
		["PSU1 Output"] = "PSU1",
		["SYS_FAN0_PCI"] = "FAN0",
		["SYS_FAN1"] = "FAN1",
		["SYS_FAN2"] = "FAN2",
        ["SYS_FAN3"] = "FAN3",
		["Exhaust_Temp"] = "BP"
	},
	motherboard = {
		["CPU0 Temp"] = "CPU0",
		["CPU1 Temp"] = "CPU1",
		["Temp_DIMM_A0"] = "MEM-BLOCK0",
        ["Temp_DIMM_D0"] = "MEM-BLOCK1",
        ["TEMP_DIMM_F0"] = "MEM-BLOCK2",
		["Inlet_Temp"] = "MB"
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
