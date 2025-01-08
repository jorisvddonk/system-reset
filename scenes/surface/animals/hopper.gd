extends Node3D

var speed: float = 0.0

const rayCheckVectorBegin = Vector3.UP * 10
const rayCheckVectorEnd = Vector3.DOWN * 1000

var step_tween: Tween
var rotate_tween: Tween

var timeToNextAction: float = 0.0


func _ready():
	rotate_y(randf_range(0, PI * 2))


func _process(delta):
	var velocity = -Basis().from_euler(rotation).z.normalized() * speed
	position = position + velocity * delta
	var collision = _getCollisionPoint()
	if collision:
		if collision.position:			
			position = collision.position
	timeToNextAction -= delta
	if timeToNextAction < 0:
		timeToNextAction = 1.5 + randf_range(0, 1)
		var r = randi() % 4
		if r <= 1:
			speed = 1.0
			_step()
		elif r == 2:
			_rotate()
		elif r == 3:
			pass # do nothing


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

func _step():
	if step_tween:
		step_tween.kill()
	step_tween = get_tree().create_tween()
	step_tween.tween_property(self, "speed", 0, 1).set_trans(Tween.TRANS_SINE)

func _rotate():
	if rotate_tween:
		rotate_tween.kill()
	rotate_tween = get_tree().create_tween()
	rotate_tween.tween_property(self, "quaternion", Quaternion((Vector3.UP*0.5).normalized(), randf_range((-3*PI)/4, (3*PI)/4)), 1).as_relative().set_trans(Tween.TRANS_SINE)
