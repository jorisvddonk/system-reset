extends Node3D

const ymin = 0
const ymax = 199
const xmin = 0
const xmax = 199
const TERRAINMULT_X = 3
const TERRAINMULT_Y = 60
const TERRAINMULT_Z = -3

func _ready():
	Globals.on_debug_tools_enabled_changed.connect(_on_debug_tools_enabled_changed)
	_on_debug_tools_enabled_changed(Globals.debug_tools_enabled)
	get_viewport().connect("size_changed", _on_resize)
	_on_resize()
	if get_tree().get_current_scene().name == "SurfaceExploration": # Force-load if we run the scene directly
		print("Running SurfaceExploration scene directly; forcing surface load...")
		Globals.load_game()
		Globals.feltyrion.landing_pt_lon = 182
		Globals.feltyrion.landing_pt_lat = 16
	
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
	
	var txtrTexture = ImageTexture.create_from_image(Globals.feltyrion.return_txtr_image())
	var paletteimg = Globals.feltyrion.get_surface_palette_as_image()
	var paletteTexture = ImageTexture.create_from_image(paletteimg)
	$DebuggingTools/PaletteImage.texture = paletteTexture
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	var colors = PackedColorArray()

	var xdiff = xmax - xmin;
	var ydiff = ymax - ymin;
	var midvert
	
	for y in range(ymin, ymax + 1):
		for x in range(xmin, xmax + 1):
			var vert = Vector3(
				x * TERRAINMULT_X,
				surfimg.get_pixel(x, y).get_luminance() * TERRAINMULT_Y,
				y * TERRAINMULT_Z
	  		)
			verts.append(vert)
			
			var color_index = min(255,ruinsimg.get_pixel(x, y).r8 + 32)
			var color = paletteimg.get_pixel(color_index, 0)
			
			if y % 2 == 0:
				if x % 2 == 0:
					uvs.append(Vector2(0,0))
					colors.append(color)
				else:
					uvs.append(Vector2(1,0))
					colors.append(color)
			else:
				if x % 2 == 0:
					uvs.append(Vector2(0,1))
					colors.append(color)
				else:
					uvs.append(Vector2(1,1))
					colors.append(color)
			
			if y == 100 && x == 100:
				midvert = vert

	# tri1
	for y in range(0, ydiff):
		for x in range(0, xdiff):
			indices.append(getVertexIndex(x + 0, y + 0, xdiff))
			indices.append(getVertexIndex(x + 0, y + 1, xdiff))
			indices.append(getVertexIndex(x + 1, y + 0, xdiff))

	# tri2
	for y in range(1, ydiff + 1):
		for x in range(0, xdiff):
			indices.append(getVertexIndex(x + 0, y + 0, xdiff))
			indices.append(getVertexIndex(x + 1, y + 0, xdiff))
			indices.append(getVertexIndex(x + 1, y - 1, xdiff))
			
	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	
	# Use SurfaceTool to calculate our normals and generate our actual mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 1, 1))
	st.set_smooth_group(-1) # set the smooth group to -1; this gives us flat shading, which is more Noctis-like
	for i in range(0, indices.size(), 3):
		for j in range(0, 3):
			st.set_color(colors[indices[i + j]])
			st.set_uv(uvs[indices[i + j]])
			st.add_vertex(verts[indices[i + j]])
	st.generate_normals()
	
	# Set the mesh, material, and create collision shape...
	%Surface.mesh = st.commit()
	%Surface.material_override.set_shader_parameter("albedo_texture", txtrTexture)
	%Surface.material_override.set_shader_parameter("ruinschart_texture", ruinsTexture)
	%Surface.material_override.set_shader_parameter("surface_palette", paletteTexture)
	%Surface.create_trimesh_collision()
	%Surface.get_child(0).get_child(0).shape.backface_collision = true
	
	%PlayerCharacterController.position = %Surface.to_global(midvert + Vector3(0,4,0))
	
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
