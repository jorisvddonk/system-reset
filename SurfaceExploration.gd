extends Node3D

const ymin = 0
const ymax = 199
const xmin = 0
const xmax = 199
const TERRAINMULT_X = -3
const TERRAINMULT_Y = 60
const TERRAINMULT_Z = -3

var initialized = false
var time_passed = 0

@onready var surface = $SubViewportContainer_Surface/SurfaceExplorationViewPort/Surface

func _process(delta):
	time_passed += delta
	if time_passed > 0.10 && initialized == false:
		initialized = true
		go(Globals.feltyrion.ip_targetted, Globals.feltyrion.landing_pt_lon, Globals.feltyrion.landing_pt_lat)
		
func _ready():
	get_viewport().connect("size_changed", _on_resize)
	_on_resize()
		
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
	var surfTexture = ImageTexture.create_from_image(surfimg)
	$DebuggingTools/PlanetHeightmap.texture = surfTexture
	
	var txtrimg = Globals.feltyrion.return_txtr_image()
	var txtrTexture = ImageTexture.create_from_image(txtrimg)
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

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
			normals.append(vert.normalized())
			if y % 2 == 0:
				if x % 2 == 0:
					uvs.append(Vector2(0,0))
				else:
					uvs.append(Vector2(1,0))
			else:
				if x % 2 == 0:
					uvs.append(Vector2(0,1))
				else:
					uvs.append(Vector2(1,1))
			
			if y == 100 && x == 100:
				midvert = vert

	# tri1
	for y in range(0, ydiff):
		for x in range(0, xdiff):
			indices.append(getVertexIndex(x + 0, y + 0, xdiff))
			indices.append(getVertexIndex(x + 1, y + 0, xdiff))
			indices.append(getVertexIndex(x + 0, y + 1, xdiff))

	# tri2
	for y in range(1, ydiff + 1):
		for x in range(0, xdiff):
			indices.append(getVertexIndex(x + 0, y + 0, xdiff))
			indices.append(getVertexIndex(x + 1, y - 1, xdiff))
			indices.append(getVertexIndex(x + 1, y + 0, xdiff))
			
	# normals
	for i in range(0, indices.size(), 3):
		normals.append(getNormal(i, indices, verts))

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices

	# Recalculate the normals and set the mesh
	surface.mesh = ArrayMesh.new()
	surface.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(surface.mesh, 0)
	for i in range(mdt.get_face_count()):
		var normal = mdt.get_face_normal(i)
		
		mdt.set_vertex_normal(mdt.get_face_vertex(i, 0), normal)
		mdt.set_vertex_normal(mdt.get_face_vertex(i, 1), normal)
		mdt.set_vertex_normal(mdt.get_face_vertex(i, 2), normal)
	
	surface.mesh.clear_surfaces()
	mdt.commit_to_surface(surface.mesh)
	
	surface.material_override.albedo_texture = txtrTexture
	surface.create_trimesh_collision()
	
	%PlayerCharacterController.position = surface.to_global(midvert + Vector3(0,4,0))
	
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
		if event.keycode == KEY_ESCAPE:
			Globals.initiate_return_sequence.emit()
