local skynet = require "skynet"
local cluster = require "skynet.cluster"

local M = {
	--类型和id; 如gateway1服务，它的name = gateway, id = 1
	name = "",
	id = 0,
	--回调函数; 在服务初始化和退出的时候会被调用
	exit = nil,
	init = nil,
	--分发方法；即消息处理方法
	resp = {},
}

local dispatch = function(session, source, cmd, ...)
	skynet.error("ohfTest, dispatch收到消息", M.name, cmd)
	local fun = M.resp[cmd]
	if not fun then
		skynet.error("ohfTest, dispatch没找到相应接口", cmd)
		skynet.ret()
		return
	end
	local success, tab_result = xpcall(fun, traceback, source, ...)
	skynet.error("ohfTest, 什么类型2", type(success), type(tab_result))
	local isok = success
	if not isok then
		skynet.ret()
		return
	end
	tab_result = tab_result or {}
	skynet.retpack(table.unpack(tab_result))
end

function init()
	skynet.error("ohfTest, 注册dispatch函数", M.name, M.id)
	skynet.dispatch("lua", dispatch)	--将下面的dispatch函数注册为lua消息的处理函数
	if M.init then
		M.init()
	end
end

function M.start(name, id, ...)
	M.name = name
	M.id = tonumber(id)
	skynet.start(init)
end

function traceback(err)
	skynet.error(tostring(err))
	skynet.error(debug.traceback())
end

function M.call(node, srv, ...)
	local mynode = skynet.getenv("node")
	if mynode == node then
		return skynet.call(srv, "lua", ...)
	else
		return cluster.call(node, srv, ...)
	end
end

function M.send(node, srv,...)
	local mynode = skynet.getenv("node")
	if mynode == node then
		return skynet.send(srv, "lua",...)
	else
		return cluster.send(node, srv,...)
	end
end

return M


