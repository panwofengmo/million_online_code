local skynet = require("skynet")
local socket = require("skynet.socket")
local mysql = require("skynet.db.mysql")

local db = nil
skynet.start(function()
	--网络监听
	local listenfd = socket.listen("0.0.0.0", 8888)
	socket.start(listenfd, connect)
	db = mysql.connect({
		host = "127.0.0.1",
		port = 3306,
		database = "message_board",
		user = "root",
		password = "55555",
		max_packet_size = 1024 * 1024,
		on_connect = nil,
	})
end)

function connect(fd, addr)
	socket.start(fd)
	while true do
		local read_data = socket.read(fd)
		if read_data then
			if read_data == "get\r\n" then
				local res = db:query("select * from msgs;")
				for i, v in pairs(res) do
					socket.write(fd, v.id..", "..v.text.."\n")
				end
			else
				local recv_data = string.match(read_data, "set (.-)\r\n")
				local str_command = string.format( "insert into msgs(text) values(\'%s\')", recv_data)
				db:query(str_command)
			end
		else
			socket.close(fd)
			break
		end
	end
end