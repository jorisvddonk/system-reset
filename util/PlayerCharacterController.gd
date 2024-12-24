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
var lockedTo: RigidBody3D ## rigidbody3d that this characterbody is locked to - only really used for pairing the player character to the cupola


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if register_as_global_camera:
		Globals.playercharacter = self
	
func _physics_process(delta):
	if lockedTo != null:
		position = lockedTo.position
	
	
	var acceleration = 10
	var gravity_vector = Vector3.ZERO
	var mouse_moved_x
	var mouse_moved_y
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= sensitivity
		mouse_moved_x = _mouse_position.x
		mouse_moved_y = _mouse_position.y
		_mouse_position = Vector2(0, 0)
	
	# Add the gravity.
	if is_on_floor() or lockedTo != null:
		gravity_vector = Vector3.ZERO
	else:
		#velocity.y -= gravity * delta
		gravity_vector = Vector3.DOWN * gravity
		acceleration = 0 # TODO: set this to a higher nozero value on planets with atmosphere to simulate air friction (though this also gives air control!)

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction *= (0 if disable_movement else 1) # cancel out movement if we're disabling movement from input keys. Yes, this happens before adding any movement from the mouse - that movement doesn't conflict with GOESNET screen input so it's fine to accept
	
	if Input.is_action_pressed("move_with_mouse_enable"):
		var addMovement = (transform.basis * Vector3(mouse_moved_x, 0, mouse_moved_y))
		if addMovement.length() > 2:
			addMovement = addMovement.normalized() * 2
		direction += addMovement
	
	
	velocity = velocity.lerp(direction * SPEED, acceleration * delta) + (gravity_vector * delta)
	
	# Handle Jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor() and !disable_movement:
		velocity.y += JUMP_VELOCITY

	move_and_slide()
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not Input.is_action_pressed("move_with_mouse_enable"):
		var yaw = mouse_moved_x
		var pitch = mouse_moved_y
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

func lock_to(object: RigidBody3D):
	lockedTo = object

func unlock():
	lockedTo = null
