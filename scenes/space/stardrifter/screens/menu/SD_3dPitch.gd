extends MeshInstance3D
@onready var mouseover: bool = false
@export var viewport: SubViewport
@export var SCREEN_PX_WIDTH = 100
@export var SCREEN_PX_HEIGHT = 100
@export var camera: Camera3D

func _ready():
	$Area3D.mouse_entered.connect(_mouse_entered)
	$Area3D.mouse_exited.connect(_mouse_exited)
	
func _process(delta):
	var s = get_viewport().size
	
	if true:
		var space_state = get_world_3d().direct_space_state
		var mousepos = Vector2(s.x / 2, s.y / 2)
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			# use mouse position instead!
			mousepos = get_viewport().get_mouse_position()
		var origin = camera.project_ray_origin(mousepos)
		var end = origin + camera.project_ray_normal(mousepos) * 1000
		var query = PhysicsRayQueryParameters3D.create(origin, end, 128)
		query.collide_with_areas = true

		var result = space_state.intersect_ray(query)
		if result:
			var mouse3d = $Area3D.global_transform.affine_inverse() * result.position
			var aabb = self.mesh.get_aabb()
			var mouse2d = Vector2((mouse3d.x + (aabb.get_longest_axis_size() * 0.5)) / self.mesh.size.x, (-mouse3d.y + (self.mesh.size.y * 0.5)) / self.mesh.size.y)
			var synthetic = InputEventMouseMotion.new()
			synthetic.button_mask = Input.get_mouse_button_mask()
			var x = SCREEN_PX_WIDTH * mouse2d.x
			var y = SCREEN_PX_HEIGHT * mouse2d.y
			synthetic.position = Vector2(x,y)
			viewport.push_input(synthetic, true)

func _mouse_entered():
	mouseover = true
	
func _mouse_exited():
	mouseover = false
