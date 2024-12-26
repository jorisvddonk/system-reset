extends Node3D

func _ready():
	Globals.on_debug_tools_enabled_changed.connect(_on_debug_tools_enabled_changed)
	_on_debug_tools_enabled_changed(Globals.debug_tools_enabled)
	get_viewport().connect("size_changed", _on_resize)
	_on_resize()
	if _is_running_scene_directly_for_development(): # Force-load if we run the scene directly
		print("Running SurfaceExplorationComposition scene directly; forcing surface load...")
		if false: # toggle this to switch between current savegame and generated one when debugging/developing
			Globals.load_game()
			Globals.feltyrion.prepare_star()
			Globals.feltyrion.landing_pt_lon = 60
			Globals.feltyrion.landing_pt_lat = 60
		else:
			var x = -18928
			var y = -29680
			var z = -67336
			Globals.feltyrion.set_nearstar(x,y,z) # balastrackonastreya
			Globals.set_ap_target(Globals.feltyrion.get_nearstar_x(), Globals.feltyrion.get_nearstar_y(), Globals.feltyrion.get_nearstar_z())
			Globals.feltyrion.update_time()
			Globals.feltyrion.ip_targetted = 3 # Felysia
			Globals.feltyrion.ip_reached = 1
			Globals.feltyrion.landing_point = 1 # enable "setting landing point" mode. Without this, nightzone isn't calculated correctly.
			Globals.feltyrion.landing_pt_lat = 60
			Globals.feltyrion.landing_pt_lon = 60
			Globals.feltyrion.prepare_star()
	
	go(Globals.feltyrion.ip_targetted, Globals.feltyrion.landing_pt_lon, Globals.feltyrion.landing_pt_lat)
		
func _on_resize():
	printt("Root viewport size changed", get_viewport().size)
	$SubViewportContainer_Sky/SubViewport.size.x = get_viewport().size.x
	$SubViewportContainer_Sky/SubViewport.size.y = get_viewport().size.y
	$SubViewportContainer_Surface/SurfaceExplorationViewPort.size.x = get_viewport().size.x
	$SubViewportContainer_Surface/SurfaceExplorationViewPort.size.y = get_viewport().size.y
		
func go(planet_index, lon, lat):
	Globals.feltyrion.update_time()
	Globals.feltyrion.ip_targetted = planet_index
	Globals.feltyrion.ip_reached = 1
	Globals.feltyrion.landing_point = 1 # without this, albedo isn't calculated in load_planet_at_current_system() below
	Globals.feltyrion.landing_pt_lat = lat
	Globals.feltyrion.landing_pt_lon = lon
	
	Globals.feltyrion.load_planet_at_current_system(planet_index)
	Globals.feltyrion.prepare_planet_surface()
	Globals.planet_surface_prepared.emit()
	$SubViewportContainer_Sky/SubViewport/SurfaceSkyBackgroundScene.recalculate()
	var surfimg = Globals.feltyrion.return_surfacemap_image()
	surfimg.adjust_bcs(2, 1, 1) # fix brightness so that maximum heightmap value is white
	var surfTexture = ImageTexture.create_from_image(surfimg)
	$DebuggingTools/PlanetHeightmap.texture = surfTexture
	
	var ruinsimg = Globals.feltyrion.return_ruinschart_image()
	var ruinsTexture = ImageTexture.create_from_image(ruinsimg)
	$DebuggingTools/PlanetRuinsChart.texture = ruinsTexture
	
	var txtrTexture = ImageTexture.create_from_image(Globals.feltyrion.return_txtr_image(false))
	var paletteimg = Globals.feltyrion.get_surface_palette_as_image()
	var paletteTexture = ImageTexture.create_from_image(paletteimg)
	$DebuggingTools/PaletteImage.texture = paletteTexture
	
	Globals.feltyrion.generateSurfacePolygons()
	
	%SurfaceExploration.initialize()
	
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("quit"):
			Globals.initiate_return_sequence.emit()

func _on_debug_tools_enabled_changed(enabled: bool):
	if enabled:
		$DebuggingTools/PlanetDetails.text = "sky_brightness: %d  nightzone: %d  rainy: %2.2f" % [Globals.feltyrion.sky_brightness, Globals.feltyrion.nightzone, Globals.feltyrion.rainy]
		$DebuggingTools.show()
	else:
		$DebuggingTools.hide()


func _is_running_scene_directly_for_development():
	return get_tree().get_current_scene().name == "SurfaceExplorationComposition"
