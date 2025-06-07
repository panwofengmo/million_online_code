--对应代码3-4
--用于描述服务端的拓扑结构
return {
	cluster = {
		node1 = "127.0.0.1:7771",
		node2 = "127.0.0.1:7772",
	},
	--agentmgr
	agentmgr = {
		node = "node1"
	},
	--scene
	scene = {
		node1 = {1001, 1002},
		--node2 = {1003},
	},
	node1 = {
		gateway = {
			[1] = {port=8001},
			[2] = {port=8002},
		},
		
	}
}