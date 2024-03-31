extends Node

@onready var feltyrion: Feltyrion = Feltyrion.new()
@export var stardrifter: Node3D
@export var playercharacter: CharacterBody3D
var debug_tools_enabled = false
signal on_debug_tools_enabled_changed(value: bool)
signal on_parsis_changed(parsis_x: float, parsis_y: float, parsis_z: float)
signal on_camera_rotation(rotation)
signal on_ap_target_changed(parsis_x: float, parsis_y: float, parsis_z: float, id_code)
signal mouse_clicked()
signal mouse_click_begin()
signal game_loaded()
signal initiate_landing_sequence()
signal initiate_return_sequence()
signal deploy_surface_capsule_status_change(active)
enum UI_MODE {NONE, SET_REMOTE_TARGET, SET_LOCAL_TARGET}
signal ui_mode_changed(new_value)
signal osd_updated(item1_text: String, item2_text: String, item3_text: String, item4_text: String) # emitted whenever the Stardrifter's OSD (window display) got updated
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
		local_target_orbit_index = -1 # if we were orbiting around a planet, we need to re-engage orbit with it now
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
			feltyrion.ip_reached = 1
			var pl_info = feltyrion.get_planet_info(value)
			local_target_orbit_coordinates = Vector3(feltyrion.get_nearstar_x() - pl_info.nearstar_p_plx, feltyrion.get_nearstar_y() - pl_info.nearstar_p_ply, feltyrion.get_nearstar_z() - pl_info.nearstar_p_plz)
		else:
			feltyrion.ip_reached = 0
			local_target_orbit_coordinates = Vector3(0,0,0) # blah!
		_on_local_target_orbit_changed.emit(value)
		
enum CHASE_MODE {
	TRACKING_DISABLED = 0, # don't even follow the planet; just stay stationary
	FIXED_POINT_CHASE = 1, # rotating the SD keeps the planet centered in view; seems similar to near chase, but the planet seems to move a little so there must be a difference
	FAR_CHASE = 2 , # planet is kept within view, rotating the SD keeps the planet centered. far chase.
	SYNCRONE_ORBIT = 3, # SD tracks against a fixed point (which?); rotating the SD does not keep the planet centered
	HIGH_SPEED_CHASE = 4, # SD rotates around the planet, but rotating the SD does not keep it in view.
	NEAR_CHASE = 5, # SD tracks against a point on the planet; when rotating the SD, the planet is kept centered in view (i.e. the point on the planet is essentially changed by this)
	HIGH_SPEED_VIEWPOINT_CHASE = 6, # custom mode; SD rotates around the planet, keeping the planet centered in view
}
signal chase_mode_changed(new_value)
var chase_direction: Vector3 = Vector3(1,0,0)
@export var chase_mode: CHASE_MODE = CHASE_MODE.HIGH_SPEED_VIEWPOINT_CHASE:
	get:
		return chase_mode
	set(value):
		chase_mode = value
		feltyrion.nsync = value
		chase_mode_changed.emit(value)

const ROOT_SCENE_NAME = "MainControl"
const CAMERA_CONTROLLER_SCENE_NAME = "SpaceNear"
const CAMERA_CONTROLLER_SCENE_NAME_2 = "SurfaceExplorationViewPort"

const MOUSE_CLICK_THRESHOLD_LOW = 0.01
const MOUSE_CLICK_THRESHOLD_HIGH = 1.5

const DEGREES_TO_RADIANS = 0.0174532925
@export var camera_inverted = false # whether the camera is inverted on the Y axis or not.



signal vimana_status_change(vimana_drive_active: bool)
@export var vimana_active: bool = false:
	get:
		return vimana_active
	set(value):
		vimana_active = value
		feltyrion.stspeed = 1 if value else 0
		vimana_status_change.emit(value)

signal fine_approach_status_change(val: bool)
@export var fine_approach_active = false:
	get:
		return fine_approach_active
	set(value):
		fine_approach_active = value
		feltyrion.ip_reaching = value
		if value == true:
			local_target_orbit_index = -1
		fine_approach_status_change.emit(value)

func _ready():
	feltyrion.update_time()
	self.add_child(feltyrion) # need to add Feltyrion to the tree so we can get nodes via the tree in C++
	chase_mode = CHASE_MODE.HIGH_SPEED_VIEWPOINT_CHASE
	if OS.has_feature("editor"):
		# fix starting position to something sensible
		feltyrion.dzat_x = -18930
		feltyrion.dzat_z = -67340
		set_ap_target(-18928, -29680, -67336)
		game_loaded.emit()
	else:
		await get_tree().create_timer(0.1).timeout # wait a bit to allow things to load
		load_game()

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
	
func vimanaStop():
	vimana_active = false
	vimana_status_change.emit(vimana_active)

func vimanaStart():
	local_target_orbit_index = -1
	local_target_index = -1
	vimana_active = true
	feltyrion.ap_reached = 0
	vimana_status_change.emit(vimana_active)

func save_game():
	print("Saving game...")
	feltyrion.freeze()

func load_game():
	print("Loading game...")
	feltyrion.unfreeze()
	set_ap_target(feltyrion.ap_target_x, feltyrion.ap_target_y, feltyrion.ap_target_z)
	local_target_index = feltyrion.ip_targetted
	local_target_orbit_index = feltyrion.ip_targetted # this is not exactly correct... meh.  - note: make sure to set this AFTER setting local_target_index!
	game_loaded.emit()
	
func _input(event):
	if event.is_action_pressed("toggle_debug_tools"):
		debug_tools_enabled = !debug_tools_enabled
		on_debug_tools_enabled_changed.emit(debug_tools_enabled)
	if event.is_action_pressed("save_game"):
		save_game()
	if event.is_action_pressed("load_game"):
		load_game()
		
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()

func slew_to(parsis_x: float, parsis_y: float, parsis_z: float, speed: float):
	feltyrion.dzat_x = parsis_x
	feltyrion.dzat_y = parsis_y
	feltyrion.dzat_z = parsis_z
	on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)

func rotate_to(x: float, y: float, z: float):
	# Rotate the stardrifter towards a point in 3d space, then rotate the camera and reposition it so that it feels as if the stardrifter is not rotating at all
	# yeah, this is a little wonky.. :) - for some reason, making the Camera3D in the SpaceNear scene a child of StardrifterParent does not work and cancels the stardrifter rotation!?
	var cur_rot = stardrifter.rotation
	var look_at = Vector3(x - feltyrion.dzat_x, y - feltyrion.dzat_y, z - feltyrion.dzat_z)
	stardrifter.look_at(-(look_at))
	var rotated = stardrifter.rotation
	var rotated_rads = fmod(rotated.y - cur_rot.y + deg_to_rad(540), deg_to_rad(360)) - deg_to_rad(180)
	if playercharacter != null:
		playercharacter.rotation.y += rotated_rads
		playercharacter.position = playercharacter.position.rotated(Vector3.UP, rotated_rads)
		Globals.on_camera_rotation.emit(playercharacter.camera.global_rotation)
