extends Node3D


var planet_img: Image
var p_console_img: Image
var camera_is_around_deployment_console = false

func _ready():
	var layer_fixer = func(item): item.set_layer_mask(2); return true
	$StardrifterParent/vehicle.find_children("?*", "MeshInstance3D").all(layer_fixer)
	Globals.stardrifter = $StardrifterParent
	Globals.deploy_surface_capsule_status_change.connect(on_deploy_surface_capsule_status_change)
	$StardrifterParent/DeploymentSelectionScreen/Area3D.area_entered.connect(deployment_console_entered)
	$StardrifterParent/DeploymentSelectionScreen/Area3D.area_exited.connect(deployment_console_exited)

func _process(delta):
	# Make the SD semitransparent when selecting local or remote target
	# TODO: determine if this is some kind of perf issue; rewrite to a Signal handler if so.
	if Globals.ui_mode != Globals.UI_MODE.NONE:
		$StardrifterParent/vehicle/vehicle_007.transparency = 0.5
	else:
		$StardrifterParent/vehicle/vehicle_007.transparency = 0.0
	
	if $StardrifterParent/DeploymentSelectionScreen.material_override != null:
		printt(Globals.feltyrion.landing_pt_lon, Globals.feltyrion.landing_pt_lat)
		updatePConsoleImage(false)

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
		
	$StardrifterParent/DeploymentSelectionScreen.material_override.uv1_offset = Vector3(float(Globals.feltyrion.landing_pt_lon / 360.0), float(0 + (Globals.feltyrion.landing_pt_lat / 236.0)), 1)

func on_deploy_surface_capsule_status_change(active):
	if active:
		var material = StandardMaterial3D.new()
		$StardrifterParent/DeploymentSelectionScreen.material_override = material
		planet_img = Globals.feltyrion.return_image(true, false)
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
				
			if event.keycode == KEY_ENTER:
				# Drop down!
				get_tree().change_scene_to_file("res://surface_exploration.tscn")

func deployment_console_entered(area):
	if area == $Camera3D/Area3D:
		camera_is_around_deployment_console = true
		
func deployment_console_exited(area):
	if area == $Camera3D/Area3D:
		camera_is_around_deployment_console = false
