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

function init()
	skynet.dispatch("lua", dispatch)
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

function dispatch(session, source, cmd, ...)
	local fun = M.resp[cmd]
	if not fun then
		skynet.ret()
		return
	end
	local ret  = xpcall(fun, traceback, source, ...)
	local isok = ret[1]
	if not isok then
		skynet.ret()
		return
	end
	skynet.retpack(table.unpack(ret, 2))
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


