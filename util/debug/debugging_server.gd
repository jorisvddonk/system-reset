extends Node

func _ready() -> void:
	var args = OS.get_cmdline_args()
	if args.find("--debugserver") > -1:
		print("Enabling debug server!")
		var server = HttpServer.new()
		var portarg = args.find("--debugport")
		if portarg > -1:
			server.port = int(args[portarg + 1])
		else:
			server.port = 8096
		server.bind_address = '127.0.0.1'
		printt("Binding debug server to addess", server.bind_address, "port", server.port)
		var router = DebugRouter.new()
		router.set_refnode(self)
		server.register_router("/", router)
		add_child(server)	
		server.enable_cors(["http://localhost:8060"])
		server.start()
