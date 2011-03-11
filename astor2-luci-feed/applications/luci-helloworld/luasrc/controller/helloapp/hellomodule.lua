module("luci.controller.helloapp.hellomodule", package.seeall)

function index()
    entry({"helloworld"}, cbi("helloapp-hellomodule/helloworld"), "Hello World", 10).dependent=false
end
