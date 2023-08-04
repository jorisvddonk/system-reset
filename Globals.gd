extends Node

@onready var feltyrion: Feltyrion = Feltyrion.new()
@export var stardrifter: Node3D
@export var maincamera: Camera3D
signal on_parsis_changed(parsis_x: float, parsis_y: float, parsis_z: float)
signal on_camera_rotation(rotation)
signal on_ap_target_changed(parsis_x: float, parsis_y: float, parsis_z: float, id_code)
signal mouse_clicked()
signal mouse_click_begin()
signal vimana_status_change(vimana_drive_active: bool)

enum UI_MODE {NONE, SET_REMOTE_TARGET, SET_LOCAL_TARGET}
signal ui_mode_changed(new_value)
@export var ui_mode: UI_MODE = UI_MODE.NONE:
	get:
		return ui_mode
	set(value):
		ui_mode_changed.emit(value)
		ui_mode = value

signal _on_local_target_changed(planet_index: int)
@export var local_target_index: int = -1: # the *selected* local target; -1 if none - basically a wrapper around feltyrion.ip_targetted that emits a signal on change
	get:
		return local_target_index
	set(value):
		local_target_index = value
		feltyrion.ip_targetted = value
		if value != -1:
			var pl_info = feltyrion.get_planet_info(value)
			printt("Local target selected: ", pl_info)
		_on_local_target_changed.emit(value)
		
signal _on_local_target_orbit_changed(planet_index: int)
@export var local_target_orbit_coordinates: Vector3 = Vector3(0,0,0) # coordinates of target we are orbiting, in LOCAL parsis offset
@export var local_target_orbit_index: int = -1: # the *orbiting* local target; -1 if none
	get:
		return local_target_orbit_index
	set(value):
		local_target_orbit_index = value
		if value != -1:
			var pl_info = feltyrion.get_planet_info(value)
			local_target_orbit_coordinates = Vector3(feltyrion.get_nearstar_x() - pl_info.nearstar_p_plx, feltyrion.get_nearstar_y() - pl_info.nearstar_p_ply, feltyrion.get_nearstar_z() - pl_info.nearstar_p_plz)
		else:
			local_target_orbit_coordinates = Vector3(0,0,0) # blah!
		_on_local_target_orbit_changed.emit(value)
		
enum CHASE_MODE {
	NEAR_CHASE, # SD tracks against a point on the planet; when rotating the SD, the planet is kept centered in view (i.e. the point on the planet is essentially changed by this)
	DRIVE_TRACKING_MODE, # don't even follow the planet; just stay stationary
	FIXED_POINT_CHASE, # rotating the SD keeps the planet centered in view; seems similar to near chase, but the planet seems to move a little so there must be a difference
	FAR_CHASE, # planet is kept within view, rotating the SD keeps the planet centered. far chase.
	SYNCRONE_ORBIT, # SD tracks against a fixed point (which?); rotating the SD does not keep the planet centered
	HIGH_SPEED_CHASE, # SD rotates around the planet, but rotating the SD does not keep it in view.
	HIGH_SPEED_VIEWPOINT_CHASE, # custom mode; SD rotates around the planet, keeping the planet centered in view
}
signal chase_mode_changed(new_value)
var chase_direction: Vector3 = Vector3(1,0,0)
@export var chase_mode: CHASE_MODE = CHASE_MODE.HIGH_SPEED_VIEWPOINT_CHASE:
	get:
		return chase_mode
	set(value):
		chase_mode = value
		chase_mode_changed.emit(value)

const ROOT_SCENE_NAME = "MainControl"
const CAMERA_CONTROLLER_SCENE_NAME = "SpaceNear"

const MOUSE_CLICK_THRESHOLD_LOW = 0.01
const MOUSE_CLICK_THRESHOLD_HIGH = 1.5

const DEGREES_TO_RADIANS = 0.0174532925

const VIMANA_SPEED = 50000
const VIMANA_APPROACH_DISTANCE = 10
const FINE_APPROACH_SPEED = 100
const FINE_APPROACH_DISTANCE = 15
const TRACKING_SPEED = 1
const TRACKING_DISTANCE__NEAR_CHASE = 0.1
const TRACKING_DISTANCE__HIGH_SPEED_CHASE = 0.3
const TRACKING__HIGH_SPEED_CHASE__ORBIT_SPEED = 10 * DEGREES_TO_RADIANS # in radians per second

@export var vimana_active = false
signal fine_approach_status_change(val: bool)
@export var fine_approach_active = false:
	get:
		return fine_approach_active
	set(value):
		fine_approach_active = value
		if value == true:
			local_target_orbit_index = -1
		fine_approach_status_change.emit(value)

func _ready():
	self.add_child(feltyrion) # need to add Feltyrion to the tree so we can get nodes via the tree in C++

func set_ap_target(x: float, y: float, z: float):
	feltyrion.lock()
	feltyrion.ap_target_x = x
	feltyrion.ap_target_y = y
	feltyrion.ap_target_z = z
	feltyrion.set_ap_targetted(1)
	var info = feltyrion.get_ap_target_info()
	feltyrion.unlock()
	on_ap_target_changed.emit(x, y, z, info.ap_target_id_code)

var mouse_left_held = 0
func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if mouse_left_held == 0:
			mouse_click_begin.emit()
		mouse_left_held += delta
	else:
		if mouse_left_held > 0:
			if mouse_left_held > MOUSE_CLICK_THRESHOLD_LOW && mouse_left_held < MOUSE_CLICK_THRESHOLD_HIGH:
				mouse_clicked.emit()
			mouse_left_held = 0
	
	if vimana_active:
		# this has some precision issues initially as you Vimana far across the universe, but will become more precise as you get closer
		var dist = Vector3(feltyrion.dzat_x - feltyrion.ap_target_x, feltyrion.dzat_y - feltyrion.ap_target_y, feltyrion.dzat_z - feltyrion.ap_target_z)
		if dist.length() > VIMANA_APPROACH_DISTANCE + (VIMANA_SPEED * (delta*2)):
			dist = dist.normalized() * delta * VIMANA_SPEED
			feltyrion.dzat_x -= dist.x
			feltyrion.dzat_y -= dist.y
			feltyrion.dzat_z -= dist.z
			on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
		else:
			printt("we have arrived at remote target")
			feltyrion.set_nearstar(feltyrion.ap_target_x, feltyrion.ap_target_y, feltyrion.ap_target_z)
			feltyrion.prepare_star()
			dist = (dist.normalized() * VIMANA_APPROACH_DISTANCE).reflect(Vector3(0,0,1)) # don't ask me about this reflect.... :|
			feltyrion.dzat_x = feltyrion.ap_target_x - dist.x
			feltyrion.dzat_y = feltyrion.ap_target_y # make sure we're in the same plane as the solar system, like Noctis does
			feltyrion.dzat_z = feltyrion.ap_target_z - dist.z
			on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
			vimanaStop()
	
	if fine_approach_active:
		var dist = Vector3(feltyrion.dzat_x - feltyrion.get_ip_targetted_x(), feltyrion.dzat_y - feltyrion.get_ip_targetted_y(), feltyrion.dzat_z - feltyrion.get_ip_targetted_z())
		if dist.length() > FINE_APPROACH_DISTANCE + (FINE_APPROACH_SPEED * (delta*2)):
			dist = dist.normalized() * delta * FINE_APPROACH_SPEED
			feltyrion.dzat_x -= dist.x
			feltyrion.dzat_y -= dist.y
			feltyrion.dzat_z -= dist.z
			on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
		else:
			printt("we have arrived at local target")
			dist = dist.normalized() * FINE_APPROACH_DISTANCE
			local_target_orbit_index = local_target_index
			feltyrion.dzat_x = feltyrion.get_ip_targetted_x() - dist.x
			feltyrion.dzat_y = feltyrion.get_ip_targetted_y() # make sure we're in the same plane as the solar system, like Noctis does
			feltyrion.dzat_z = feltyrion.get_ip_targetted_z() - dist.z
			fine_approach_active = false
			on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
			chase_direction = dist.normalized()
	
	if local_target_orbit_index != -1:
		# orbit tracking
		if chase_mode == CHASE_MODE.NEAR_CHASE:
			# near chase
			var vec = (chase_direction*TRACKING_DISTANCE__NEAR_CHASE)
			slew_to(feltyrion.get_ip_targetted_x() + vec.x, feltyrion.get_ip_targetted_y() + vec.y, feltyrion.get_ip_targetted_z() + vec.z, TRACKING_SPEED)
			rotate_to(feltyrion.get_ip_targetted_x(), feltyrion.get_ip_targetted_y(), feltyrion.get_ip_targetted_z())
		elif chase_mode == CHASE_MODE.HIGH_SPEED_CHASE:
			chase_direction = chase_direction.rotated(Vector3.UP, TRACKING__HIGH_SPEED_CHASE__ORBIT_SPEED * delta)
			var vec = (chase_direction*TRACKING_DISTANCE__HIGH_SPEED_CHASE)
			slew_to(feltyrion.get_ip_targetted_x() + vec.x, feltyrion.get_ip_targetted_y() + vec.y, feltyrion.get_ip_targetted_z() + vec.z, TRACKING_SPEED)
			# do not rotate!
		elif chase_mode == CHASE_MODE.HIGH_SPEED_VIEWPOINT_CHASE:
			# same as HIGH_SPEED_CHASE, but we rotate as well
			chase_direction = chase_direction.rotated(Vector3.UP, TRACKING__HIGH_SPEED_CHASE__ORBIT_SPEED * delta)
			var vec = (chase_direction*TRACKING_DISTANCE__HIGH_SPEED_CHASE)
			slew_to(feltyrion.get_ip_targetted_x() + vec.x, feltyrion.get_ip_targetted_y() + vec.y, feltyrion.get_ip_targetted_z() + vec.z, TRACKING_SPEED)
			rotate_to(feltyrion.get_ip_targetted_x(), feltyrion.get_ip_targetted_y(), feltyrion.get_ip_targetted_z())
			
	if ui_mode != UI_MODE.NONE && Input.is_key_pressed(KEY_ESCAPE): # TODO: use Input System instead for this
		ui_mode = UI_MODE.NONE


func vimanaStop():
	vimana_active = false
	vimana_status_change.emit(vimana_active)

func vimanaStart():
	local_target_orbit_index = -1
	local_target_index = -1
	vimana_active = true
	vimana_status_change.emit(vimana_active)

func _unhandled_key_input(event): # debug shortcut key - TODO: use Input system instead.
	if event.keycode == KEY_F1 && event.is_pressed():
		vimanaStart()

func slew_to(parsis_x: float, parsis_y: float, parsis_z: float, speed: float):
	var dist = Vector3(feltyrion.dzat_x - parsis_x, feltyrion.dzat_y - parsis_y, feltyrion.dzat_z - parsis_z)
	feltyrion.dzat_x = parsis_x
	feltyrion.dzat_y = parsis_y
	feltyrion.dzat_z = parsis_z
	on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)

func rotate_to(x: float, y: float, z: float):
	# Rotate the stardrifter towards a point in 3d space, then rotate the camera and reposition it so that it feels as if the stardrifter is not rotating at all
	# yeah, this is a little wonky.. :) - for some reason, making the Camera3D in the SpaceNear scene a child of StardrifterParent does not work and cancels the stardrifter rotation!?
	var cur_rot = stardrifter.rotation
	var look_at = Vector3(feltyrion.dzat_x - x, feltyrion.dzat_y - y, feltyrion.dzat_z - z)
	stardrifter.look_at(-(look_at).reflect(Vector3(0,0,1))) # don't ask me about this reflect.... :|
	var rotated = stardrifter.rotation
	var rotated_rads = fmod(rotated.y - cur_rot.y + deg_to_rad(540), deg_to_rad(360)) - deg_to_rad(180)
	maincamera.rotation.y += rotated_rads
	maincamera.position = maincamera.position.rotated(Vector3.UP, rotated_rads)
	Globals.on_camera_rotation.emit(maincamera.rotation)
