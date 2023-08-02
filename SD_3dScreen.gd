extends MeshInstance3D
@onready var mouseover: bool = false
@export var viewport: SubViewport
@export var sdscreen: Panel

func _ready():
	$Area3D.mouse_entered.connect(_mouse_entered)
	$Area3D.mouse_exited.connect(_mouse_exited)
	
func _process(delta):
	if mouseover:
		var space_state = get_world_3d().direct_space_state
		var mousepos = get_viewport().get_mouse_position()
		var cam = get_parent().get_parent().get_node("Camera3D")
		var origin = cam.project_ray_origin(mousepos)
		var end = origin + cam.project_ray_normal(mousepos) * 1000
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true

		var result = space_state.intersect_ray(query)
		if result:
			var mouse3d = $Area3D.global_transform.affine_inverse() * result.position
			var aabb = self.mesh.get_aabb()
			var mouse2d = Vector2((mouse3d.x + (aabb.get_longest_axis_size() * 0.5)) / self.mesh.size.x, (-mouse3d.y + (self.mesh.size.y * 0.5)) / self.mesh.size.y)
			var synthetic = InputEventMouseMotion.new()
			synthetic.button_mask = Input.get_mouse_button_mask()
			var x = sdscreen.size.x * mouse2d.x
			var y = sdscreen.size.y * mouse2d.y
			synthetic.position = Vector2(x,y)
			viewport.push_input(synthetic, true)
			
			# below has been replaced by the code in sd_screen's root script!
			#if (Input.get_mouse_button_mask() != 0):
				# for some reason synthetically emitting InputEventMouseButton does not work at all
				# the first click is always 'retained', as in if you click FCD first then you will always be clicking that, even if
				# another node is highlighted..
				# hence why there's a workaround in place..
				#	var synthetic2 = InputEventMouseButton.new()
				#	synthetic2.button_index = MOUSE_BUTTON_LEFT
				#	synthetic2.button_mask = Input.get_mouse_button_mask()
				#	synthetic2.pressed = true
				#	synthetic2.meta_pressed = false
				#	synthetic2.canceled = false
				#	synthetic2.button_mask=0
				#	synthetic2.double_click=false
				#	synthetic2.position = Vector2(x,y)
				#	viewport.push_input(synthetic2, true)

func _mouse_entered():
	mouseover = true
	
func _mouse_exited():
	mouseover = false
