module( "luci.controller.san_monitoring_configuration", package.seeall )

configuration = {
	rear = {
		["PSU Output"] = "PSU0",
		["PSU1 Output"] = "PSU1",
		["BP Fan1"] = "FAN0",
		["BP Fan2"] = "FAN1",
		["BP Fan3"] = "FAN2",
		["BP Temp"] = "BP"
	}
}
