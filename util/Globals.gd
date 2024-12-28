extends Node

const VimanaDrive = preload("res://util/systems/VimanaDrive.gd")
const InterplanetaryDrive = preload("res://util/systems/InterplanetaryDrive.gd")

signal tick() # simple clock ticker, is emitted once per second
signal planet_surface_prepared() # manually emitted when planet surface had been prepared via `prepare_planet_surface`, and nodes should recalculate things. Might be worth considering putting this in feltyrion-godot..
@export var player_rotation_in_space: Vector3
@onready var feltyrion: Feltyrion = Feltyrion.new()
@onready var vimana: VimanaDrive = VimanaDrive.new(feltyrion)
@onready var interplanetaryDrive: InterplanetaryDrive = InterplanetaryDrive.new(feltyrion)
@export var stardrifter: Node3D
@export var playercharacter: CharacterBody3D
var debug_tools_enabled = false
signal on_debug_tools_enabled_changed(value: bool)
enum GAMEPLAY_MODE {SPACE, SURFACE}
signal gameplay_mode_changed(new_value)
@export var gameplay_mode: GAMEPLAY_MODE = GAMEPLAY_MODE.SPACE:
	get:
		return gameplay_mode
	set(value):
		gameplay_mode_changed.emit(value)
		gameplay_mode = value
signal on_parsis_changed(parsis_x: float, parsis_y: float, parsis_z: float)
signal on_camera_rotation(rotation)
signal on_ap_target_changed(parsis_x: float, parsis_y: float, parsis_z: float, id_code)
signal mouse_clicked()
signal mouse_click_begin()
signal game_loaded()
signal initiate_landing_sequence()
signal initiate_return_sequence()
signal deploy_surface_capsule_status_change(active)
enum UI_MODE {NONE, SET_REMOTE_TARGET, SET_LOCAL_TARGET, SET_TARGET_TO_PARSIS}
signal ui_mode_changing(old_value, new_value)
signal ui_mode_changed(new_value)
signal osd_updated(item1_text: String, item2_text: String, item3_text: String, item4_text: String) # emitted whenever the Stardrifter's OSD (window display) got updated
@export var ui_mode: UI_MODE = UI_MODE.NONE:
	get:
		return ui_mode
	set(new_value):
		ui_mode_changing.emit(ui_mode, new_value)
		ui_mode = new_value
		ui_mode_changed.emit(new_value)
		
enum DATA_UI_MODE {NONE, REMOTE_TARGET, LOCAL_TARGET, ENVIRONMENT}
signal data_ui_mode_changed(new_value)
@export var data_ui_mode: DATA_UI_MODE = DATA_UI_MODE.NONE:
	get:
		return data_ui_mode
	set(new_value):
		data_ui_mode = new_value
		data_ui_mode_changed.emit(new_value)

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
	FIXED_POINT_CHASE = 1, # rotating the SD keeps the planet centered in view - middle distance. similar to near/far chase but distance is in the middle
	FAR_CHASE = 2 , # rotating the SD keeps the planet centered in view - far distance
	SYNCRONE_ORBIT = 3, # SD tracks against a fixed point (which?); rotating the SD does not keep the planet centered
	HIGH_SPEED_CHASE = 4, # SD rotates around the planet, but rotating the SD does not keep it in view.
	NEAR_CHASE = 5, # rotating the SD keeps the planet centered in view - near distance
	HIGH_SPEED_VIEWPOINT_CHASE = 6, # custom mode; SD rotates around the planet, keeping the planet centered in view. Essentially, this is one of NEAR/FIXED_POINT/FAR chase modes, except the position that is used as center viewpoint is automatically moved around
}
signal chase_mode_changed(new_value) # used only for NEAR_CHASE/FIXED_POINT_CHASE/FAR_CHASE - this is the point/vector on the planet the SD tracks around
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

const STARDRIFTER_ROTATION_SPEED = 15 * DEGREES_TO_RADIANS # per second

enum HUD_MODE { SHOW, HIDE }
signal hud_mode_changed(new_hud_mode)
var hud_mode:HUD_MODE = HUD_MODE.SHOW:
	get:
		return hud_mode
	set(value):
		hud_mode = value
		hud_mode_changed.emit(value)

@export var camera_inverted = false # whether the camera is inverted on the Y axis or not.

signal update_fcs_status_request(val: String, timeout: int) ## signal to request an fcs status update from the HUD. Do not emit this manually, use Globals.update_fcs_status_text() instead
func update_fcs_status_text(val: String, timeout: int = 0):
	update_fcs_status_request.emit(val, timeout)


signal update_hud_selected_star_request(val:String, x: float, y: float, z: float) ## signal to request a HUD update to set the new selected star
func update_hud_selected_star(val: String, x: float, y: float, z: float):
	update_hud_selected_star_request.emit(val, x, y, z)
	
signal update_hud_selected_planet_text_request(val:String) ## signal to request a HUD update to set the new selected planet
func update_hud_selected_planet_text(val: String):
	update_hud_selected_planet_text_request.emit(val)
	
signal update_hud_lightyears_text_request(val:String) ## signal to request a HUD update to set the lightyears
func update_hud_lightyears_text(val: String):
	update_hud_lightyears_text_request.emit(val)
	
signal update_hud_dyams_text_request(val:String) ## signal to request a HUD update to set the dyams
func update_hud_dyams_text(val: String):
	update_hud_dyams_text_request.emit(val)


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
	var timer = Timer.new()
	timer.timeout.connect(func (): feltyrion.update_time())
	timer.timeout.connect(func (): feltyrion.additional_consumes())
	timer.timeout.connect(func (): tick.emit())
	timer.wait_time = 1
	timer.one_shot = false
	add_child(timer)
	timer.start()

func set_ap_target(x: float, y: float, z: float):
	if x != feltyrion.ap_target_x or y != feltyrion.ap_target_y or z != feltyrion.ap_target_z or feltyrion.ap_targetted != 1:
		feltyrion.lock()
		feltyrion.ap_target_x = x
		feltyrion.ap_target_y = y
		feltyrion.ap_target_z = z
		feltyrion.set_ap_targetted(1)
		var info = feltyrion.get_ap_target_info()
		feltyrion.unlock()
		on_ap_target_changed.emit(x, y, z, info.ap_target_id_code)
	
func set_direct_ap_target(x: float, y: float, z: float):
	feltyrion.lock()
	feltyrion.ap_target_x = x
	feltyrion.ap_target_y = y
	feltyrion.ap_target_z = z
	feltyrion.set_ap_targetted_without_extracting_target_infos(-1)
	feltyrion.unlock()
	on_ap_target_changed.emit(x, y, z, -1) # TODO : check if this is properly supported!

var mouse_left_held = 0
var moved_sd_initially = false
func _process(delta):
	if moved_sd_initially == false and stardrifter != null:
		# initialize rotation of the stardrifter and player character by moving sd very slightly
		# this is a dirty hack, but :shrug:
		rotate_by(0.00001)
		moved_sd_initially = true
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if mouse_left_held == 0:
			mouse_click_begin.emit()
		mouse_left_held += delta
	else:
		if mouse_left_held > 0:
			if mouse_left_held > MOUSE_CLICK_THRESHOLD_LOW && mouse_left_held < MOUSE_CLICK_THRESHOLD_HIGH:
				mouse_clicked.emit()
			mouse_left_held = 0
	
	# rotation - input tracking. TODO: interpolate these!
	if Input.is_action_pressed("rotate_left"):
		if chase_mode == CHASE_MODE.HIGH_SPEED_CHASE || chase_mode == CHASE_MODE.SYNCRONE_ORBIT || chase_mode == CHASE_MODE.TRACKING_DISABLED:
			rotate_by(STARDRIFTER_ROTATION_SPEED * delta)
		elif chase_mode == CHASE_MODE.NEAR_CHASE or chase_mode == CHASE_MODE.FAR_CHASE or chase_mode == CHASE_MODE.FIXED_POINT_CHASE:
			chase_direction = chase_direction.rotated(Vector3.UP, STARDRIFTER_ROTATION_SPEED * delta)
	if Input.is_action_pressed("rotate_right"):
		if chase_mode == CHASE_MODE.HIGH_SPEED_CHASE || chase_mode == CHASE_MODE.SYNCRONE_ORBIT || chase_mode == CHASE_MODE.TRACKING_DISABLED:
			rotate_by(STARDRIFTER_ROTATION_SPEED * -delta)
		elif chase_mode == CHASE_MODE.NEAR_CHASE or chase_mode == CHASE_MODE.FAR_CHASE or chase_mode == CHASE_MODE.FIXED_POINT_CHASE:
			chase_direction = chase_direction.rotated(Vector3.UP, STARDRIFTER_ROTATION_SPEED * -delta)
	
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

func rotate_by(i: float):
	var prev_rot = stardrifter.rotation
	stardrifter.rotation.y += i
	_recalc_player_character_orientation(prev_rot)

func rotate_to(x: float, y: float, z: float):
	# Rotate the stardrifter towards a point in 3d space, then rotate the camera and reposition it so that it feels as if the stardrifter is not rotating at all
	# yeah, this is a little wonky.. :) - for some reason, making the Camera3D in the SpaceNear scene a child of StardrifterParent does not work and cancels the stardrifter rotation!?
	var prev_rot = stardrifter.rotation
	var look_at = Vector3(x - feltyrion.dzat_x, y - feltyrion.dzat_y, z - feltyrion.dzat_z)
	stardrifter.look_at(-(look_at))
	# always force z/x rotation to zero to ensure we have a stardrifter oriented flatly on the x/z plane
	stardrifter.rotation.z = 0
	stardrifter.rotation.x = 0
	_recalc_player_character_orientation(prev_rot)

func _recalc_player_character_orientation(prev_stardrifter_rot):
	# reclculate player character orientation, based on current rotation and what the previous rotation was (prior to a rotation operation).
	var rotated = stardrifter.rotation
	var rotated_rads = fmod(rotated.y - prev_stardrifter_rot.y + deg_to_rad(540), deg_to_rad(360)) - deg_to_rad(180)
	if playercharacter != null:
		playercharacter.rotation.y += rotated_rads
		playercharacter.position = playercharacter.position.rotated(Vector3.UP, rotated_rads)
		Globals.on_camera_rotation.emit(playercharacter.camera.global_rotation)

func get_gravity():
	var gravity = 1
	if Globals.gameplay_mode == Globals.GAMEPLAY_MODE.SURFACE:
		gravity = Globals.feltyrion.planet_grav / 2000 * 38.26 # silly calculation, but it's what it is; check noctis-1.cpp
	return gravity
	
func get_temperature():
	var temperature = 15
	if Globals.gameplay_mode == Globals.GAMEPLAY_MODE.SURFACE:
		temperature = Globals.feltyrion.pp_temp
	return temperature
	
func get_pressure():
	var pressure = 1
	if Globals.gameplay_mode == Globals.GAMEPLAY_MODE.SURFACE:
		pressure = Globals.feltyrion.pp_pressure
	return pressure
