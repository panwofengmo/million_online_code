local skynet = require "skynet"
local runconfig = require "runconfig"
local skynet_manager = require "skynet.manager"
local cluster = require "skynet.cluster"

skynet.start(function()
	skynet.error("[start main]")
	local node = skynet.getenv("node")
	local nodecfg = runconfig[node]
	--参数1：代表要启动的服务类型
	--参数2：s.name的值
	--参数3：s.id的值
	local gateway = skynet.newservice("gateway", "gateway", 1)
	--login
	for i, v in pairs(nodecfg.login or {})  do
		local srv = skynet.newservice("login","login", i)
		local str_name = "login"..i
		skynet.name(str_name, srv)
	end
		
	-- local login = skynet.newservice("login", "login1", 1)
	-- local login = skynet.newservice("login", "login2", 2)
	skynet.newservice("debug_console",8000)
	skynet.exit()
end)
