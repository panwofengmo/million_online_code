local skynet = require "skynet"
local s = require "service"

s.client = {}

--@param source 消息发送方，比如某个gateway
--@param fd 客户端连接的fd
--@param cmd 协议名
--@param msg 客户端发送的消息
s.resp.client = function(source, fd, cmd, msg)
	if s.client[cmd] then
		local ret_msg = s.client[cmd](source, fd, msg)
		skynet.send(source, "lua", "send_by_fd", fd, ret_msg)
		return ret_msg
	else
		skynet.error("s.resp.client fail", cmd)
	end
	return {cmd, -1, "s.resp.client 未找到相应函数"}
end

s.client.login = function(source, fd, msg)
	skynet.error("login recv"..msg[1].." "..msg[2])
	return {"login", -1, "测试"}
end

function s.init(...)
	skynet.error("启动login服务")
end

s.start(...)