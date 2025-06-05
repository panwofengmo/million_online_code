local skynet = require("skynet")
local mysql = require("skynet.db.mysql")

skynet.start(function()
	local db = mysql.connect({
		host = "127.0.0.1",
		port = 3306,
		database = "message_board",
		user = "root",
		password = "55555",
		max_packet_size = 1024 * 1024,
		on_connect = nil,
	})
	local res = db:query("insert into msgs(text) values(\'hello world\')")
	res = db:query("select * from msgs")
	for i,v in ipairs(res) do
		print(i, v.id, v.text)
	end
end)