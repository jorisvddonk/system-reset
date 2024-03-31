extends HttpRouter
class_name DebugRouter

var refnode: Node

func set_refnode(node):
	refnode = node

func handle_get(request: HttpRequest, response: HttpResponse):
	response.send(405, "Not allowed")

func handle_post(request: HttpRequest, response: HttpResponse) -> void:
	var script = GDScript.new()
	printt(request.body)
	var code = []
	for i in request.body.split('\n'):
		print(i)
		code.append("\t" + i)
	script.set_source_code("func eval(viewport, scenetree):\n" + '\n'.join(code))
	script.reload()
	var ref = RefCounted.new()
	ref.set_script(script)
	var result = ref.eval(refnode.get_viewport(), refnode.get_tree())
	response.send(200, JSON.stringify({
		result = result
	}), "application/json")

func handle_put(request: HttpRequest, response: HttpResponse) -> void:
	response.send(405, "Not allowed")

func handle_patch(request: HttpRequest, response: HttpResponse) -> void:
	response.send(405, "Not allowed")

func handle_delete(request: HttpRequest, response: HttpResponse) -> void:
	response.send(405, "Not allowed")
