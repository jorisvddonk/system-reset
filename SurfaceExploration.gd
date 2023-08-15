extends Node3D

const ymin = 0
const ymax = 199
const xmin = 0
const xmax = 199
const TERRAINMULT_X = 3
const TERRAINMULT_Y = 3
const TERRAINMULT_Z = 60

var initialized = false
var time_passed = 0

func _process(delta):
	time_passed += delta
	if time_passed > 0.10 && initialized == false:
		initialized = true
		go(20, 47, 63)
		
func go(planet_index, lat, lon):
	Globals.feltyrion.prepare_star()
	Globals.feltyrion.ip_targetted = planet_index
	Globals.feltyrion.ip_reached = 1
	Globals.set_ap_target(-18928, -29680, -67336)
	Globals.feltyrion.set_nearstar(-18928, -29680, -67336)
	Globals.feltyrion.dzat_x = -18928
	Globals.feltyrion.dzat_y = -29680
	Globals.feltyrion.dzat_z = -67336
	Globals.feltyrion.landing_pt_lat = lat
	Globals.feltyrion.landing_pt_lon = lon
	var planet_info = Globals.feltyrion.get_planet_info(Globals.feltyrion.ip_targetted)
	print(planet_info)
	Globals.feltyrion.load_planet(Globals.feltyrion.ip_targetted, planet_info["nearstar_p_type"], planet_info["nearstar_p_seedval"], true, false)
	Globals.feltyrion.prepare_planet_surface()
	var surfimg = Globals.feltyrion.return_surfacemap_image()
	var surfTexture = ImageTexture.create_from_image(surfimg)
	
	var txtrimg = Globals.feltyrion.return_txtr_image()
	var txtrTexture = ImageTexture.create_from_image(txtrimg)
	
	var skyimg = Globals.feltyrion.return_sky_image()
	skyimg.crop(skyimg.get_width(), skyimg.get_height() * 2)
	var skyTexture = ImageTexture.create_from_image(skyimg)

	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var xdiff = xmax - xmin;
	var ydiff = ymax - ymin;
	
	for y in range(ymin, ymax + 1):
		for x in range(xmin, xmax + 1):
			var vert = Vector3(
				x * TERRAINMULT_X,
				y * TERRAINMULT_Y,
				surfimg.get_pixel(x, y).get_luminance() * TERRAINMULT_Z
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

	# Recalculate the normals
	$Surface.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	var mdt = MeshDataTool.new()
	mdt.create_from_surface($Surface.mesh, 0)
	for i in range(mdt.get_face_count()):
		var normal = mdt.get_face_normal(i)
		
		mdt.set_vertex_normal(mdt.get_face_vertex(i, 0), normal)
		mdt.set_vertex_normal(mdt.get_face_vertex(i, 1), normal)
		mdt.set_vertex_normal(mdt.get_face_vertex(i, 2), normal)
	
	$Surface.mesh.clear_surfaces()
	mdt.commit_to_surface($Surface.mesh)
	
	$Surface.material_override.albedo_texture = txtrTexture
	$WorldEnvironment.environment.sky.sky_material.panorama = skyTexture
	
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
