module( "luci.controller.san_monitoring_configuration", package.seeall )

configuration = {
<<<<<<< HEAD
	front = {
		["BP_Temp"] = "FP",
		["Ambient_Temp"] = "Ambient"
	},
	rear = {
		["Power Supply 0"] = "PSU0",
		["Power Supply 1"] = "PSU1",
		["PWR Consumption"] = "PSU_TOTAL",
		["Exhaust_Temp"] = "BP"
	},
	motherboard = {
		["CPU0 Temp"] = "CPU0",
		["CPU1 Temp"] = "CPU1",
		["SYS_FAN0_PCI"] = "FAN0",
		["SYS_FAN1"] = "FAN1",
		["SYS_FAN2"] = "FAN2",
		["SYS_FAN3"] = "FAN3"
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
=======
	rear = {
		["PSU Output"] = "PSU0",
		["PSU1 Output"] = "PSU1",
		["PSU Total"] = "PSU_TOTAL",
		["BP Temp"] = "BP"
	}
}
>>>>>>> 7d18bb93998a32a293b069e40f1dac80dc542e87
