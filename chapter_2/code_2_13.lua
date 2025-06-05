local skynet = require("skynet")
local cluster = require("skynet.cluster")
local mynode = skynet.getenv("node")

local CMD = {}
skynet.start(function ()
	skynet.dispatch("lua", function (session, source, cmd, ...)
		local f = assert(CMD[cmd])
		f(source, ...)
	end)
end)

--target_node:对方的节点名，如："node2"
--target:对方的服务名，如："ping"或"pong"
function CMD.start(source, target_node, target)
	cluster.send(target_node, target, "ping", mynode, skynet.self(), 1)
	--skynet.self():返回本服务名
end

function CMD.ping(source, source_node, source_srv, count)
	local id = skynet.self()
	skynet.error("["..id.."] recv ping count = "..count)
	skynet.sleep(100)

	--skynet.send(source, "lua", "ping", count+1)
	cluster.send(source_node, source_srv, "ping", mynode, skynet.self(), count+1)
	--1.ping1和ping2给ping3发送消息；
	--2.然后ping3收到消息，调用CMD.start，然后ping3向ping1和ping2发送消息
	--3.ping1和ping2收到消息之后，调用ping函数，然后分别给ping3发送消息；
	--4.ping3调用ping函数，然后回复ping1和ping2
end