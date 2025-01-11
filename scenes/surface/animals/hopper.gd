extends Node3D

var speed: float = 0.0

const rayCheckVectorBegin = Vector3.UP * 10
const rayCheckVectorEnd = Vector3.DOWN * 1000

var step_tween: Tween
var rotate_tween: Tween
var height_tween: Tween

var timeToNextAction: float = 0.0

var heightAboveSurface: float = 0.0


func _ready():
	rotate_y(randf_range(0, PI * 2))


func _process(delta):
	var velocity = -Basis().from_euler(rotation).z.normalized() * speed
	position = position + velocity * delta
	position = Clipping.surfaceClip(position)
	var collision = _getCollisionPoint()
	if collision:
		if collision.position:			
			position = collision.position + (Vector3.UP * heightAboveSurface)
	timeToNextAction -= delta
	if timeToNextAction < 0:
		timeToNextAction = 1.5 + randf_range(0, 1)
		var r = randi() % 4
		if r <= 1:
			if speed < 0.01:
				_begin_move()
			else:
				_end_move()
		elif r == 2:
			_rotate()
		elif r == 3:
			pass # do nothing
		var h = randi() % 2
		if h == 0:
			_hop()


func _getCollisionPoint():
	var rc = RayCast3D.new()
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(position + rayCheckVectorBegin, position + rayCheckVectorEnd)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_back_faces = true
	query.hit_from_inside = true
	query.collision_mask = 1 # prevent colliding with the world boundaries... because that glitches somehow.. :shrug:
	var result = space_state.intersect_ray(query)
	return result

func _begin_move():
	if step_tween:
		step_tween.kill()
	step_tween = get_tree().create_tween()
	step_tween.tween_property(self, "speed", 2.0 + randf_range(2.0, 5.0), 0.2).set_trans(Tween.TRANS_SINE)
	
func _end_move():
	if step_tween:
		step_tween.kill()
	step_tween = get_tree().create_tween()
	step_tween.tween_property(self, "speed", 0, 1 + randf_range(0.0, 0.5)).set_trans(Tween.TRANS_SINE)
	
func _hop():
	# TODO: hop using gravity instead of tweens
	if heightAboveSurface > 0 or (step_tween == null or step_tween.is_running()) or (rotate_tween == null or rotate_tween.is_running()):
		return # can't hop if already hopping or if the hopper is accelerating/decelerating/rotating
	if height_tween:
		height_tween.kill()
	height_tween = get_tree().create_tween()
	height_tween.tween_property(self, "heightAboveSurface", 1  + randf_range(0, 1), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	height_tween.tween_property(self, "heightAboveSurface", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _rotate():
	if rotate_tween:
		rotate_tween.kill()
	rotate_tween = get_tree().create_tween()
	rotate_tween.tween_property(self, "quaternion", Quaternion((Vector3.UP*0.5).normalized(), randf_range((-3*PI)/4, (3*PI)/4)), 1).as_relative().set_trans(Tween.TRANS_SINE)

func _override_body_material_with_texture(meshInstance: MeshInstance3D, texture):
	var i = meshInstance.mesh.surface_find_by_name("body")
	var mat: StandardMaterial3D = meshInstance.mesh.surface_get_material(i).duplicate()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_scale = Vector3(0.7, 0.7, 0.7)
	mat.albedo_texture = texture
	meshInstance.set_surface_override_material(i, mat)

func set_body_texture(texture):
	_override_body_material_with_texture($hopper/body, texture)

func set_eye_color(color: Color):
	var meshInstance = $hopper/body
	var i = meshInstance.mesh.surface_find_by_name("eyes")
	var mat = meshInstance.mesh.surface_get_material(i).duplicate()
	mat.albedo_color = color
	meshInstance.set_surface_override_material(i, mat)
