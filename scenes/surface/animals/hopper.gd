extends Node3D

## The three mammal movement behaviours that Noctis IV generates hoppers with.
const FELINE_LIKE = 0
const RABBIT_LIKE = 1
const KANGAROO_LIKE = 2

## Per-behaviour movement characteristics, based on the mammal behaviour in Noctis IV
## (noctis-1.cpp): felines trot around, rabbits take small frequent hops, and kangaroos
## take large, slower hops. Speeds are in metres per second.
const BEHAVIOURS = {
	FELINE_LIKE: {
		"min_speed": 3.5,
		"max_speed": 7.0,
		"hop_height": 0.4,
		"hop_duration": 0.3,
		"hop_chance": 0.15,
		"action_interval": 1.5,
		"action_variation": 1.0,
		"stop_chance": 0.5,
		"turn_chance": 0.25,
	},
	RABBIT_LIKE: {
		"min_speed": 2.0,
		"max_speed": 4.0,
		"hop_height": 0.8,
		"hop_duration": 0.35,
		"hop_chance": 0.85,
		"action_interval": 0.6,
		"action_variation": 0.5,
		"stop_chance": 0.3,
		"turn_chance": 0.25,
	},
	KANGAROO_LIKE: {
		"min_speed": 4.0,
		"max_speed": 5.0,
		"hop_height": 2.5,
		"hop_duration": 0.7,
		"hop_chance": 0.6,
		"action_interval": 0.9,
		"action_variation": 0.4,
		"stop_chance": 0.2,
		"turn_chance": 0.2,
	},
}

@export var move_type: int = FELINE_LIKE

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
		_decide_next_action()

## The movement characteristics for this hopper's behaviour.
func get_behaviour() -> Dictionary:
	return BEHAVIOURS.get(move_type, BEHAVIOURS[FELINE_LIKE])

func _decide_next_action():
	var behaviour = get_behaviour()
	timeToNextAction = behaviour.action_interval + randf_range(0, behaviour.action_variation)
	var r = randf()
	if r < behaviour.stop_chance:
		if speed < 0.01:
			_begin_move()
		else:
			_end_move()
	elif r < behaviour.stop_chance + behaviour.turn_chance:
		_rotate()
	# otherwise: do nothing for a moment
	if randf() < behaviour.hop_chance:
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
	var behaviour = get_behaviour()
	if step_tween:
		step_tween.kill()
	step_tween = get_tree().create_tween()
	step_tween.tween_property(self, "speed", randf_range(behaviour.min_speed, behaviour.max_speed), 0.2).set_trans(Tween.TRANS_SINE)
	
func _end_move():
	if step_tween:
		step_tween.kill()
	step_tween = get_tree().create_tween()
	step_tween.tween_property(self, "speed", 0, 1 + randf_range(0.0, 0.5)).set_trans(Tween.TRANS_SINE)
	
func _hop():
	# TODO: hop using gravity instead of tweens
	if heightAboveSurface > 0 or (rotate_tween != null and rotate_tween.is_running()):
		return # can't hop if already hopping or rotating
	var behaviour = get_behaviour()
	if height_tween:
		height_tween.kill()
	height_tween = get_tree().create_tween()
	height_tween.tween_property(self, "heightAboveSurface", behaviour.hop_height, behaviour.hop_duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	height_tween.tween_property(self, "heightAboveSurface", 0, behaviour.hop_duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
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
