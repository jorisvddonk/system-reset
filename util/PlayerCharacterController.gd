extends CharacterBody3D


const SPEED = 10
const JUMP_VELOCITY = 9
@export var gravity = 9.8 ## gravity applied to player character in m/s squared

var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0
var emit_event_next = false
const sensitivity = 0.25
@onready var camera = $CollisionShape3D/camera
@export var register_as_global_camera: bool = false
@export var disable_movement = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if register_as_global_camera:
		Globals.playercharacter = self
	
func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor() and !disable_movement:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * (0 if disable_movement else 1)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= sensitivity
		var yaw = _mouse_position.x
		var pitch = _mouse_position.y
		_mouse_position = Vector2(0, 0)
		
		# Prevents looking up/down too far
		pitch = pitch * (-1 if Globals.camera_inverted else 1)
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
		_total_pitch += pitch
	
		rotate_y(deg_to_rad(-yaw))
		%camera.rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))
		if emit_event_next:
			Globals.on_camera_rotation.emit(%camera.global_rotation)
			emit_event_next = false
	
	if Input.is_action_just_pressed("cancel_mouse_capture"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_released("cancel_mouse_capture"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_mouse_position = Vector2(0, 0)


func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_position = event.relative
		emit_event_next = true
