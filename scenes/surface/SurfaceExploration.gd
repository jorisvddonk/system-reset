extends Node3D

const ymin = 0
const ymax = 199
const xmin = 0
const xmax = 199
# 3260416 ??
const SEC_H_SIZE = 16384
const SEC_V_SIZE = 2048
const SEC_X_ROOT = SEC_H_SIZE * 100
const SEC_Y_ROOT = SEC_V_SIZE * 0
const SEC_Z_ROOT = SEC_H_SIZE * 100
# do not ask me where this math comes from; it's not from the source code!!!
# 33.3008130081
const TERRAINMULT_X = 32.77
const TERRAINMULT_Y = 528 # close enough. Is this actually exponential somehow???
const TERRAINMULT_Z = 32.77
const OFFSET_X = 3300 - 9.918699 - 13.5 + 0.418699
const OFFSET_Z = 3300 - 9.918699 - 13.5 + 0.418699

func _ready():
	Globals.on_debug_tools_enabled_changed.connect(_on_debug_tools_enabled_changed)
	_on_debug_tools_enabled_changed(Globals.debug_tools_enabled)
	get_viewport().connect("size_changed", _on_resize)
	%Surface2.connect("meshUpdated", surfaceMeshUpdated)
	_on_resize()
	if get_tree().get_current_scene().name == "SurfaceExploration": # Force-load if we run the scene directly
		print("Running SurfaceExploration scene directly; forcing surface load...")
		Globals.load_game()
		Globals.feltyrion.prepare_star()
		Globals.feltyrion.landing_pt_lon = 60
		Globals.feltyrion.landing_pt_lat = 60
	
	if %Scattering_IndividualNodes.get_meta("enabled"):
		Globals.feltyrion.prepare_surface_scattering(%Scattering_IndividualNodes, "res://scenes/surface/ScatteringObject.tscn")
	
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
	
func surfaceMeshUpdated():
	var rc = RayCast3D.new()
	var space_state = %PlayerCharacterController.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(Vector3(0,1000,0), Vector3(0,-1000,0))
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_back_faces = true
	query.hit_from_inside = true
	var result = space_state.intersect_ray(query)
	if result:
		%PlayerCharacterController.position = result.position + Vector3(0,4,0)
	
func getVertexIndex(x, y, xdiff):
	return y * (xdiff + 1) + x

func getNormal(index_base, indices, vertices):
	var p1 = vertices[indices[index_base]]
	var p2 = vertices[indices[index_base]]
	var p3 = vertices[indices[index_base]]
	var u = p2 - p1
	var v = p3 - p1
	var normal = u * v
	return normal
	
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("quit"):
			Globals.initiate_return_sequence.emit()

func _on_debug_tools_enabled_changed(enabled: bool):
	if enabled:
		$DebuggingTools.show()
	else:
		$DebuggingTools.hide()
