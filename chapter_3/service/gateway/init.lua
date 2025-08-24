local skynet = require "skynet"
local s= require "service"
local socket = require "skynet.socket"
local runconfig = require "runconfig"


conns = {}	--[fd] = conn
players = {}	--[playerid] = gateplayer

function conn()
	local m = {
		fd = nil,
		playerid = nil,
	}
	return m
end

function gateplayer()
	local m = {
		playerid = nil,
		agent = nil,
		conn = nil,
	}
	return m
end

--消息解码
local str_unpack = function(msgstr)
	local msg = {}

	while true do
		local arg, rest = string.match(msgstr, "(.-),(.*)")
		if arg then
			msgstr = rest
			table.insert(msg, arg)
		else
			table.insert(msg, msgstr)
			break
		end
	end
	return msg[1], msg
end

--消息的编码
local str_pack = function(msg)
	return table.concat(msg, ",").."\r\n"
end

--得到处理过的数据，这些数据是已知格式的数据
--msgstr = "login,101,123"
local process_msg = function(fd, msgstr)
	local cmd, msg = str_unpack(msgstr)
	skynet.error("recv " .. fd .." [".. cmd .."] {"..table.concat(msg, ",").."}")

	local conn = conns[fd]
	local playerid = conn.playerid

	if not playerid then			--尚未完成登录流程
		local node = skynet.getenv("node")
		local nodecfg = runconfig[node]
		local login_id = math.random(1, #nodecfg.login)
		local login = "login"..login_id
		skynet.error("ohfTest, 通知login服务", login, node, #nodecfg.login, cmd)
		skynet.send(login, "lua", "client", fd, cmd, msg)	--通知login服务
	else							--完成登录流程
		local gplayer = players[playerid]
		local agent = gplayer.agent
		skynet.send(agent, "lua", "client", cmd, msg)	--将消息传给agent服务处理
	end
end

--处理从客户端中读取到的数据，让数据成为一段段可用的，已知格式的数据
local process_buff = function(fd, readbuff)
	while true do
		local msgstr, rest = string.match(readbuff, "(.-)\r\n(.*)")
		if msgstr then
			readbuff = rest
			process_msg(fd, msgstr)
		else
			return readbuff
		end
	end
end

--代码3-21
--客户端掉线，还会调用disconnect函数；会将players中的数据移除，并通知agentmgr
local disconnect = function(fd)
	local conn = conns[fd]
	if not conn then
		return
	end

	local playerid = conn.playerid
	if not playerid then	--还没完成登录
		return
	else	--已经在游戏中
		-- 不要立即删除players数据，让s.resp.kick来处理
		--players[playerid] = nil
		skynet.call("agentmgr", "lua", "reqkick", playerid, "客户端掉线")
	end
end

--从客户端不断读取数据的接口
local recv_loop = function(fd)
	socket.start(fd)					--注意：这个是socket，而不是skynet.start
	skynet.error("socket connect fd = ", fd)
	local read_buff = ""
	while true do
		local recvstr = socket.read(fd)
		if recvstr then
			read_buff = read_buff .. recvstr
			read_buff = process_buff(fd, read_buff)		--返回的数据是不完成的数据，需要和后面的数据拼接起来
		else
			skynet.error("socket close fd = ", fd)
			disconnect(fd)
			socket.close(fd)
			return
		end
	end
end

--新的客户端连接时，
local connect = function(fd, addr)
	skynet.error("connect from ".. addr .. " "..fd)
	local c = conn()
	c.fd = fd
	conns[fd] = c
	skynet.fork(recv_loop, fd)		--创建携程
end

function s.init()
	local node = skynet.getenv("node")
	local nodecfg = runconfig[node]
	local port = nodecfg.gateway[s.id].port

	local listenfd = socket.listen("0.0.0.0", port)
	socket.start(listenfd, connect)
end

s.resp.send_by_fd = function(source, fd, msg)
	skynet.error("ohfTest, send_by_fd,收到的fd", source, fd, msg)
	if not conns[fd] then
		return
	end
	
	local buff = str_pack(msg)
	skynet.error("send " .. fd .." [".. msg[1] .."] {"..table.concat(msg, ",").."}")
	socket.write(fd, buff)
end

s.resp.send = function(source, playerid, msg)
	local gplayer = players[playerid]
	if not gplayer then
		return
	end
	local c = gplayer.conn
	if not c then
		return
	end
	
	s.resp.send_by_fd(source, c.fd, msg)
end

--代码3-20
--在完成登录流程后，login会通知gateway,让gateway把客户端连接和新agent关联起来
s.resp.sure_agent = function(source, fd, playerid, agent)
	local conn = conns[fd]
	if not conn then	--在登录过程中已经下线
		skynet.call("agentmgr", "lua", "reqkick", playerid, "未完成登录即下线")
		return false
	end

	conn.playerid = playerid

	local gplayer = gateplayer()
	gplayer.playerid = playerid
	gplayer.agent = agent
	gplayer.conn = conn
	players[playerid] = gplayer

	return true
end

--代码3-22
--当agentmgr讲玩家踢下线并保存好数据后，会通知gateway，然后gateway会删掉玩家对应的conn和gateplayer对象
s.resp.kick = function(source, playerid)
	local gplayer = players[playerid]
	if not gplayer then
		return
	end
	
	local conn = gplayer.conn
	players[playerid] = nil

	if not conn then
		return
	end

	conns[conn.fd] = nil
	--disconnect(conn.fd)
	socket.close(conn.fd)
end


s.start(...)
