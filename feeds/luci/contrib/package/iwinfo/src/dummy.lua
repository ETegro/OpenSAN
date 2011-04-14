module "iwinfo"

function type(x)
	if x:match("^wlan%d") or x:match("^wl%d") or
	   x:match("^wifi%d") or x:match("^ath%d") then
		return "dummy"
	end
end

dummy = {}

function dummy.channel()
	return 1
end

function dummy.frequency()
	return 2412
end

function dummy.bitrate()
	return 36000
end

function dummy.signal()
	return -53
end

function dummy.noise()
	return -96
end

function dummy.quality()
	return 50
end

function dummy.quality_max()
	return 70
end

function dummy.mode()
	return "Master"
end

function dummy.ssid()
	return "OpenWrt"
end

function dummy.bssid()
	return "00:11:22:33:44:55"
end

function dummy.enctype()
	return "WPA2 PSK (CCMP)"
end

function dummy.assoclist()
	return {}
end

function dummy.txpwrlist()
	return {
		{ dbm = 0, mw = 1 },
		{ dbm = 6, mw = 3 },
		{ dbm = 8, mw = 6 },
		{ dbm = 10, mw = 10 },
		{ dbm = 12, mw = 15 },
		{ dbm = 14, mw = 25 },
		{ dbm = 16, mw = 39 },
		{ dbm = 18, mw = 63 }
	}
end

function dummy.freqlist()
	return {
		{channel =  1, mhz = 2412},
		{channel =  2, mhz = 2417},
		{channel =  3, mhz = 2422},
		{channel =  4, mhz = 2427},
		{channel =  5, mhz = 2432},
		{channel =  6, mhz = 2437},
		{channel =  7, mhz = 2442},
		{channel =  8, mhz = 2447},
		{channel =  9, mhz = 2452},
		{channel = 10, mhz = 2457},
		{channel = 11, mhz = 2462}
	}
end

function dummy.scanlist()
	return {
		{ quality = 23, quality_max = 70, signal = -60,
		  bssid = "00:12:23:34:45:56", ssid = "Test_Net_1",
		  channel = 1, mode = "Master", wep = true },
		{ quality = 45, quality_max = 70, signal = -43,
		  bssid = "01:23:34:45:56:67", ssid = "Test_Net_2",
		  channel = 10, mode = "Master", wep = false, wpa = 3,
		  pair_ciphers = { "TKIP", "CCMP" },
		  group_ciphers = { "TKIP", "CCMP" },
		  auth_suites = { "PSK" } },
		{ quality = 5, quality_max = 70, signal = -77,
		  bssid = "02:34:45:56:67:78", ssid = "Test_Net_3",
		  channel = 3, mode = "Master", wep = false, wpa = 1,
		  pair_ciphers = { "TKIP" },
		  group_ciphers = { "TKIP" },
		  auth_suites = { "PSK" } },
		{ quality = 12, quality_max = 70, signal = -64,
		  bssid = "02:00:DE:AD:BE:EF", ssid = "Test_Net_4",
		  channel = 5, mode = "Ad-Hoc", wep = false }
	}
end

function dummy.mbssid_support()
	return 1
end
