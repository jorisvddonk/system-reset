extends Node3D


var planet_img: Image
var p_console_img: Image
var camera_is_around_deployment_console = false

const VIMANA_SPEED = 50000
const VIMANA_APPROACH_DISTANCE = 10
const FINE_APPROACH_SPEED = 10
const FINE_APPROACH_DISTANCE = 0.25
const TRACKING_SPEED = 1
const TRACKING_DISTANCE__NEAR = 0.05
const TRACKING_DISTANCE__MIDDLE = 0.08
const TRACKING_DISTANCE__FAR = 0.12
const TRACKING__HIGH_SPEED_CHASE__ORBIT_SPEED = 10 * Globals.DEGREES_TO_RADIANS # in radians per second

var nearstar_ray = 1

func _ready():
	%vehicle/vehicle_007/StaticBody3D/CollisionShape3D.shape.backface_collision = true 
	var layer_fixer = func(item): item.set_layer_mask(2); return true
	$StardrifterParent/vehicle.find_children("?*", "MeshInstance3D").all(layer_fixer)
	Globals.stardrifter = $StardrifterParent
	Globals.deploy_surface_capsule_status_change.connect(on_deploy_surface_capsule_status_change)
	$StardrifterParent/DeploymentSelectionScreen/Area3D.area_entered.connect(deployment_console_entered)
	$StardrifterParent/DeploymentSelectionScreen/Area3D.area_exited.connect(deployment_console_exited)
	Globals.vimana_status_change.connect(on_vimana_status_change)
	Globals.game_loaded.connect(on_game_load)
	update_star_lights()
	Globals.on_debug_tools_enabled_changed.connect(_on_debug_tools_enabled_changed)
	_on_debug_tools_enabled_changed(Globals.debug_tools_enabled)

func _process(delta):
	# Make the SD semitransparent when selecting local or remote target
	# TODO: determine if this is some kind of perf issue; rewrite to a Signal handler if so.
	if Globals.ui_mode != Globals.UI_MODE.NONE:
		$StardrifterParent/vehicle/vehicle_007.transparency = 0.5
	else:
		$StardrifterParent/vehicle/vehicle_007.transparency = 0.0
	
	if $StardrifterParent/DeploymentSelectionScreen.material_override != null:
		updatePConsoleImage(false)
		
func _physics_process(delta):
	var feltyrion = Globals.feltyrion
	if Engine.physics_ticks_per_second == 24:
		# 24 physics tics per second: use Noctis IV's engine for movement
		var old_stspeed = feltyrion.stspeed
		feltyrion.loop_iter()
		Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
		if feltyrion.stspeed != old_stspeed:
			printt("Detected vimana status change", feltyrion.stspeed)
			# vimana status changed
			if feltyrion.stspeed == 0:
				# we just got out of vimana
				feltyrion.set_nearstar(feltyrion.ap_target_x, feltyrion.ap_target_y, feltyrion.ap_target_z)
				feltyrion.prepare_star()
			Globals.vimana_status_change.emit(true if feltyrion.stspeed == 1 else false)
	else:
		# Some other physics tics per second rating: use the custom engine for movement
		if Globals.vimana_active:
			# this has some precision issues initially as you Vimana far across the universe, but will become more precise as you get closer
			var approach_vector = Vector3(feltyrion.ap_target_x - feltyrion.dzat_x, feltyrion.ap_target_y - feltyrion.dzat_y, feltyrion.ap_target_z - feltyrion.dzat_z)
			if approach_vector.length() > VIMANA_APPROACH_DISTANCE + (VIMANA_SPEED * (delta*2)):
				approach_vector = approach_vector.normalized() * delta * VIMANA_SPEED
				feltyrion.dzat_x += approach_vector.x
				feltyrion.dzat_y += approach_vector.y
				feltyrion.dzat_z += approach_vector.z
				Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
			else:
				printt("we have arrived at remote target")
				feltyrion.ap_reached = 1
				feltyrion.set_nearstar(feltyrion.ap_target_x, feltyrion.ap_target_y, feltyrion.ap_target_z)
				feltyrion.prepare_star()
				approach_vector = (approach_vector.normalized() * VIMANA_APPROACH_DISTANCE)
				feltyrion.dzat_x = feltyrion.ap_target_x - approach_vector.x
				feltyrion.dzat_y = feltyrion.ap_target_y # make sure we're in the same plane as the solar system, like Noctis does
				feltyrion.dzat_z = feltyrion.ap_target_z - approach_vector.z
				Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
				Globals.vimanaStop()
		
		if Globals.fine_approach_active:
			var approach_vector = Vector3(feltyrion.get_ip_targetted_x() - feltyrion.dzat_x, feltyrion.get_ip_targetted_y() - feltyrion.dzat_y, feltyrion.get_ip_targetted_z() - feltyrion.dzat_z)
			if approach_vector.length() > FINE_APPROACH_DISTANCE + (FINE_APPROACH_SPEED * (delta*2)):
				approach_vector = approach_vector.normalized() * delta * FINE_APPROACH_SPEED
				feltyrion.dzat_x += approach_vector.x
				feltyrion.dzat_y += approach_vector.y
				feltyrion.dzat_z += approach_vector.z
				Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
			else:
				printt("we have arrived at local target")
				approach_vector = approach_vector.normalized() * FINE_APPROACH_DISTANCE
				Globals.local_target_orbit_index = Globals.local_target_index
				feltyrion.dzat_x = feltyrion.get_ip_targetted_x() - approach_vector.x
				feltyrion.dzat_y = feltyrion.get_ip_targetted_y() # make sure we're in the same plane as the solar system, like Noctis does
				feltyrion.dzat_z = feltyrion.get_ip_targetted_z() - approach_vector.z
				Globals.fine_approach_active = false
				Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
				Globals.chase_direction = -approach_vector.normalized()
	
	if !Globals.vimana_active and feltyrion.get_nearstar_x() != 0 and feltyrion.get_nearstar_y() != 0 and feltyrion.get_nearstar_z() != 0:
		# we are in a solar system and not in Vimana flight; update the local star's light!
		var star_vector = Vector3(feltyrion.dzat_x - feltyrion.get_nearstar_x(), feltyrion.dzat_y - feltyrion.get_nearstar_y(), feltyrion.dzat_z - feltyrion.get_nearstar_z())
		var light_energy = tanh(nearstar_ray/max(0.0001, star_vector.length()/10))
		$SolarSystemParentStarLight.look_at(star_vector)
		$SolarSystemParentStarLight.light_energy = light_energy
	
	if Globals.stardrifter != null and Globals.local_target_orbit_index != -1 && Globals.local_target_orbit_index == Globals.local_target_index:
		# orbit tracking
		if Globals.chase_mode == Globals.CHASE_MODE.NEAR_CHASE or Globals.chase_mode == Globals.CHASE_MODE.FAR_CHASE or Globals.chase_mode == Globals.CHASE_MODE.FIXED_POINT_CHASE:
			# near chase / fixed point chase (middle distance) / far chase
			var vec = (Globals.chase_direction*TRACKING_DISTANCE__NEAR)
			if Globals.chase_mode == Globals.CHASE_MODE.FAR_CHASE:
				vec = (Globals.chase_direction*TRACKING_DISTANCE__FAR)
			elif Globals.chase_mode == Globals.CHASE_MODE.FIXED_POINT_CHASE:
				vec = (Globals.chase_direction*TRACKING_DISTANCE__MIDDLE)
			Globals.slew_to(feltyrion.get_ip_targetted_x() + vec.x, feltyrion.get_ip_targetted_y() + vec.y, feltyrion.get_ip_targetted_z() + vec.z, TRACKING_SPEED)
			Globals.rotate_to(feltyrion.get_ip_targetted_x(), feltyrion.get_ip_targetted_y(), feltyrion.get_ip_targetted_z())
		elif Globals.chase_mode == Globals.CHASE_MODE.HIGH_SPEED_CHASE:
			Globals.chase_direction = Globals.chase_direction.rotated(Vector3.UP, TRACKING__HIGH_SPEED_CHASE__ORBIT_SPEED * delta)
			var vec = (Globals.chase_direction*TRACKING_DISTANCE__MIDDLE)
			Globals.slew_to(feltyrion.get_ip_targetted_x() + vec.x, feltyrion.get_ip_targetted_y() + vec.y, feltyrion.get_ip_targetted_z() + vec.z, TRACKING_SPEED)
			# do not rotate!
		elif Globals.chase_mode == Globals.CHASE_MODE.HIGH_SPEED_VIEWPOINT_CHASE:
			# same as HIGH_SPEED_CHASE, but we rotate as well
			Globals.chase_direction = Globals.chase_direction.rotated(Vector3.UP, TRACKING__HIGH_SPEED_CHASE__ORBIT_SPEED * delta)
			var vec = (Globals.chase_direction*TRACKING_DISTANCE__MIDDLE)
			Globals.slew_to(feltyrion.get_ip_targetted_x() + vec.x, feltyrion.get_ip_targetted_y() + vec.y, feltyrion.get_ip_targetted_z() + vec.z, TRACKING_SPEED)
			Globals.rotate_to(feltyrion.get_ip_targetted_x(), feltyrion.get_ip_targetted_y(), feltyrion.get_ip_targetted_z())
			
	if Globals.ui_mode != Globals.UI_MODE.NONE && Input.is_key_pressed(KEY_ESCAPE): # TODO: use Input System instead for this
		Globals.ui_mode = Globals.UI_MODE.NONE



func updatePConsoleImage(redraw):
	if redraw:
		p_console_img.crop(p_console_img.get_width(), p_console_img.get_height() * 2)
		p_console_img.fill(Color.SADDLE_BROWN.darkened(0.90))
		p_console_img.blit_rect(planet_img, Rect2i(0, 0, planet_img.get_width(), planet_img.get_height()), Vector2(0, 59))
		var imageTexture = ImageTexture.create_from_image(p_console_img)
		$StardrifterParent/DeploymentSelectionScreen.material_override.albedo_texture = imageTexture
		$StardrifterParent/DeploymentSelectionScreen.material_override.shading_mode = $StardrifterParent/DeploymentSelectionScreen.material_override.SHADING_MODE_UNSHADED
		$StardrifterParent/DeploymentSelectionScreen.material_override.texture_filter = $StardrifterParent/DeploymentSelectionScreen.material_override.TEXTURE_FILTER_NEAREST
		$StardrifterParent/DeploymentSelectionScreen.material_override.uv1_scale = Vector3(100.0 / 360, (100.0 / 118) * 0.5, 1)
		
	$StardrifterParent/DeploymentSelectionScreen.material_override.uv1_offset = Vector3(float(34 + Globals.feltyrion.landing_pt_lon / 360.0) - 0.1375, float(0 + (Globals.feltyrion.landing_pt_lat / 236.0)) + 0.0315, 1)

func on_deploy_surface_capsule_status_change(active):
	if active:
		var material = StandardMaterial3D.new()
		$StardrifterParent/DeploymentSelectionScreen.material_override = material
		Globals.feltyrion.load_planet_at_current_system(Globals.feltyrion.ip_targetted)
		var ipinfo = Globals.feltyrion.get_planet_info(Globals.feltyrion.ip_targetted)
		planet_img = Globals.feltyrion.return_image(true, false, ipinfo["nearstar_p_owner"] > -1)
		p_console_img = planet_img.duplicate()
		updatePConsoleImage(true)
	else:
		$StardrifterParent/DeploymentSelectionScreen.material_override = null

func _unhandled_input(event):
	if camera_is_around_deployment_console:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_LEFT:
				Globals.feltyrion.landing_pt_lon = (Globals.feltyrion.landing_pt_lon - 1) % 360
			if event.keycode == KEY_RIGHT:
				Globals.feltyrion.landing_pt_lon = (Globals.feltyrion.landing_pt_lon + 1) % 360
			if event.keycode == KEY_UP:
				Globals.feltyrion.landing_pt_lat = (Globals.feltyrion.landing_pt_lat - 1)
			if event.keycode == KEY_DOWN:
				Globals.feltyrion.landing_pt_lat = (Globals.feltyrion.landing_pt_lat + 1)
			if Globals.feltyrion.landing_pt_lon < 0:
				Globals.feltyrion.landing_pt_lon += 360
			if Globals.feltyrion.landing_pt_lat < 1:
				Globals.feltyrion.landing_pt_lat = 1
			if Globals.feltyrion.landing_pt_lat > 119:
				Globals.feltyrion.landing_pt_lat = 119
			
			Globals.feltyrion.set_fcs_status("%s:%s" % [Globals.feltyrion.landing_pt_lon, Globals.feltyrion.landing_pt_lat])
				
			if event.keycode == KEY_ENTER:
				# Drop down!
				Globals.initiate_landing_sequence.emit()

func _input(event):
	if Globals.ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET: # need to do this first, or else we might capture an inputevent when tapping the 'set local target' shortcut key
		$SetLocalTargetKeyboardInputHandler.process_input(event)
	if Globals.ui_mode != Globals.UI_MODE.SET_LOCAL_TARGET and (event.is_action_pressed("osd_category_1")\
		or event.is_action_pressed("osd_category_2")\
		or event.is_action_pressed("osd_category_3")\
		or event.is_action_pressed("osd_category_4")\
		or event.is_action_pressed("osd_item_1")\
		or event.is_action_pressed("osd_item_2")\
		or event.is_action_pressed("osd_item_3")\
		or event.is_action_pressed("osd_item_4")):
			$SubViewport.push_input(event)
	if event.is_action_pressed("quit"):
		if Globals.ui_mode == Globals.UI_MODE.NONE:
			if not OS.has_feature("editor"):
				Globals.save_game() # save the game on exit, but don't do it when running the game via the editor as it can make debugging more difficult
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		elif Globals.ui_mode == Globals.UI_MODE.SET_REMOTE_TARGET:
			Globals.ui_mode = Globals.UI_MODE.NONE
		elif Globals.ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET:
			Globals.local_target_index = -1
			Globals.ui_mode = Globals.UI_MODE.NONE

func deployment_console_entered(area):
	if area == %PlayerCharacterController/Area3D:
		camera_is_around_deployment_console = true
		
func deployment_console_exited(area):
	if area == %PlayerCharacterController/Area3D:
		camera_is_around_deployment_console = false

func on_vimana_status_change(active):
	update_star_lights()
	
func on_game_load():
	update_star_lights()
	
func update_star_lights():
	var lightcolor = Color(0.2, 0.3, 0.6) # _very_ 'ambient' light if in interstellar space
	
	if !Globals.vimana_active and Globals.feltyrion.get_nearstar_x() != 0 and Globals.feltyrion.get_nearstar_y() != 0 and Globals.feltyrion.get_nearstar_z() != 0:
		# We have possibly arrived at a star!
		var data = Globals.feltyrion.get_ap_target_info()
		nearstar_ray = data.ap_target_ray
		lightcolor = Color(data.ap_target_r / 64.0, data.ap_target_g / 64.0, data.ap_target_b / 64.0)
		$SolarSystemParentStarLight.visible = true
	else:
		$SolarSystemParentStarLight.visible = false
	
	$SolarSystemParentStarLight.light_color = lightcolor
	$StardrifterParent/InternalLightExtra1.light_color = lightcolor
	$StardrifterParent/InternalLightExtra2.light_color = lightcolor
	
func _on_debug_tools_enabled_changed(enabled: bool):
	if enabled and Globals.gameplay_mode == Globals.GAMEPLAY_MODE.SPACE:
		$DebuggingTools.show()
		Globals.feltyrion.load_planet_at_current_system(Globals.feltyrion.ip_targetted)
		var ipinfo = Globals.feltyrion.get_planet_info(Globals.feltyrion.ip_targetted)
		var img = Globals.feltyrion.return_image(true, false, ipinfo["nearstar_p_owner"] > -1)
		var imageTexture = ImageTexture.create_from_image(img)
		$DebuggingTools/PlanetSurfaceTexture.texture = imageTexture
		
		var paletteimg = Globals.feltyrion.get_palette_as_image()
		var paletteTexture = ImageTexture.create_from_image(paletteimg)
		$DebuggingTools/PaletteImage.texture = paletteTexture
		
		$DebuggingTools/PlanetsLabel.text = ""
		var data = Globals.feltyrion.get_current_star_info()
		for i in range(0,data.nearstar_nob):
			var pl_data = Globals.feltyrion.get_planet_info(i)
			var name = Globals.feltyrion.get_planet_name_by_id(pl_data.nearstar_p_identity).rstrip(" \t")
			if name.length() < 24:
				name = "---                  P%02d" % i
			name = "%s   type: %02d" % [name, pl_data.nearstar_p_type]
			if pl_data.nearstar_p_ring != 0.0:
				name += ' ring'
				name += " (%d layers)" % int(0.05 * (pl_data.nearstar_p_qsortdist / pl_data.nearstar_p_ray))
			$DebuggingTools/PlanetsLabel.text =  $DebuggingTools/PlanetsLabel.text + " " + name + "\n"
	else:
		$DebuggingTools.hide()
