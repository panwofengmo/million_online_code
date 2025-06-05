--对应代码2-5 和 2-6
--为Pmain.lua的代码
local skynet = require("skynet")
local socket = require("skynet.socket")

skynet.start(function()
	local listenfd = socket.listen("0.0.0.0", 8888)
	socket.start(listenfd, connect)
end)

function connect(fd, addr)
	print(fd.." connected addr:"..addr)
	socket.start(fd)
	--消息处理
	while true do
		local read_data = socket.read(fd)
		--正常接收
		if read_data then
			print(fd.." recv "..read_data)
			socket.write(fd, read_data)
		else
			--断开连接
			print(fd.." close")
			socket.close()
			break
		end
	end
end