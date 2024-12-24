extends Node3D

func _ready():
	Globals.on_debug_tools_enabled_changed.connect(_on_debug_tools_enabled_changed)
	_on_debug_tools_enabled_changed(Globals.debug_tools_enabled)
	get_viewport().connect("size_changed", _on_resize)
	_on_resize()
	if get_tree().get_current_scene().name == "SurfaceExploration": # Force-load if we run the scene directly
		print("Running SurfaceExploration scene directly; forcing surface load...")
		Globals.load_game()
		Globals.feltyrion.prepare_star()
		Globals.feltyrion.landing_pt_lon = 60
		Globals.feltyrion.landing_pt_lat = 60
	
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
		$DebuggingTools.show()
	else:
		$DebuggingTools.hide()
