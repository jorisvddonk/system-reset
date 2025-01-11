extends Node3D

var speed: float = 0.0

const rayCheckVectorBegin = Vector3.UP * 10
const rayCheckVectorEnd = Vector3.DOWN * 1000

var speed_tween: Tween
var rotate_tween: Tween
var height_tween: Tween

var timeToNextAction: float = 0.0

var flying = false
var heightAboveSurface: float = 0.0


func _ready():
	rotate_y(randf_range(0, PI * 2))

func _process(delta):
	var velocity = -Basis().from_euler(rotation).z.normalized() * speed
	position = position + (velocity * delta)
	position = Clipping.surfaceClip(position)
	var collision = _getCollisionPoint()
	if collision:
		if collision.position:			
			position = collision.position + (Vector3.UP * heightAboveSurface)
	timeToNextAction -= delta
	if timeToNextAction < 0:
		timeToNextAction = 1.5 + randf_range(0, 1)
		var f = randi() % 2
		if f == 0:
			if not flying:
				_fly()
		elif f == 1:
			if flying:
				_land()
		elif f == 3:
			_rotate()
		var r = randi() % 2
		if r == 0:
			_rotate()


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

func _rotate():
	if rotate_tween:
		rotate_tween.kill()
	rotate_tween = get_tree().create_tween()
	rotate_tween.tween_property(self, "quaternion", Quaternion((Vector3.UP*0.5).normalized(), randf_range((-3*PI)/4, (3*PI)/4)), 1).as_relative().set_trans(Tween.TRANS_SINE)

func _fly():
	flying = true
	$birdy/AnimationTree["parameters/conditions/flying"] = true
	$birdy/AnimationTree["parameters/conditions/landed"] = false
	
	if height_tween:
		height_tween.kill()
	height_tween = get_tree().create_tween()
	height_tween.tween_property(self, "heightAboveSurface", 15  + randf_range(0, 25), 3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if speed_tween:
		speed_tween.kill()
	speed_tween = get_tree().create_tween()
	speed_tween.tween_property(self, "speed", 6 + randf_range(0, 20), 1.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
func _land():
	flying = false
	$birdy/AnimationTree["parameters/conditions/flying"] = false
	$birdy/AnimationTree["parameters/conditions/landed"] = true
	
	if height_tween:
		height_tween.kill()
	height_tween = get_tree().create_tween()
	height_tween.tween_property(self, "heightAboveSurface", 0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if speed_tween:
		speed_tween.kill()
	speed_tween = get_tree().create_tween()
	speed_tween.tween_property(self, "speed", 0, 1.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
