module( "luci.controller.smart", package.seeall )

einarc = require( "astor2.einarc" )

function index()
	local i18n = luci.i18n.translate
	local e = entry(
		{ "smart" },
		call( "get_smart" )
	)
	e.dependent = false
	e.i18n = "astor2_san"
end

function get_smart()
	local id = luci.http.formvalue( "id" )
	if id then
		luci.template.render(
			"smart",
			einarc.Physical.list()[ id ]:extended_info()
		)
	end
end
