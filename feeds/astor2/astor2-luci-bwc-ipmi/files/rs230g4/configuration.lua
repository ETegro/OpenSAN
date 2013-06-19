module( "luci.controller.san_monitoring_configuration", package.seeall )

configuration = {
	rear = {
		["PSU Output"] = "PSU0",
		["PSU1 Output"] = "PSU1",
		["PSU Total"] = "PSU_TOTAL",
		["BP Temp"] = "BP"
	}
}
