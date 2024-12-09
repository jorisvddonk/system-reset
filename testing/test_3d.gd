extends Node3D

var surface_scattering_verts = PackedVector3Array()
var surface_scattering_uvs = PackedVector2Array()
var surface_scattering_indices = PackedInt32Array()
var surface_scattering_colors = PackedColorArray()
var xtot = 0
var ytot = 0
var ztot = 0
var snum = 0
var time = 0
var lastTime = 0
var st: SurfaceTool

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.feltyrion.connect("found_surface_polygon3", on_found_surface_polygon3)
	
	Globals.feltyrion.lock() 
	fix_coordinates(-18928, -29680, -67336) # balastrackonastreya
	Globals.feltyrion.update_time() # strange, this does not take into effect the first time this function is called?
	Globals.feltyrion.ip_targetted = 3 # planet index
	Globals.feltyrion.ip_reached = 1
	Globals.feltyrion.landing_point = 1 # enable "setting landing point" mode. Without this, nightzone isn't calculated correctly.
	Globals.feltyrion.landing_pt_lat = 60
	Globals.feltyrion.landing_pt_lon = 60
	
	Globals.feltyrion.prepare_star()
	Globals.feltyrion.load_planet_at_current_system(Globals.feltyrion.ip_targetted)
	clearSurfaceVars()
	Globals.feltyrion.prepare_planet_surface()
	
	var txtimg = Globals.feltyrion.return_txtr_image(false)
	var txtrTexture = ImageTexture.create_from_image(txtimg)
	var txtRawimg = Globals.feltyrion.return_txtr_image(true)
	var txtrRawTexture = ImageTexture.create_from_image(txtRawimg)
	$TextureRect.texture = txtrRawTexture # txtrTextureF
	$TextureRect.queue_redraw()
	
	%MeshInstance3D.material_override.set_shader_parameter("cull_mode", 2)
	
	%MeshInstance3D.material_override.set_shader_parameter("albedo_texture", txtrTexture)
	
	%SurfaceScattering.material_override.set_shader_parameter("albedo_texture_format_l8", txtrRawTexture)
	var paletteimg = Globals.feltyrion.get_surface_palette_as_image()
	var paletteTexture = ImageTexture.create_from_image(paletteimg)
	$TextureRect2.texture = paletteTexture
	%SurfaceScattering.material_override.set_shader_parameter("surface_palette", paletteTexture)
	# DEBUG:
	#var pimage = Image.load_from_file("res://assets/debug/palette.png")
	#var ptexture = ImageTexture.create_from_image(pimage)
	#$TextureRect2.texture = ptexture
	#%SurfaceScattering.material_override.set_shader_parameter("surface_palette", ptexture)

	
	Globals.feltyrion.unlock()
	updateSurfaceFragments()

func clearSurfaceVars():
	surface_scattering_verts.clear()
	surface_scattering_uvs.clear()
	surface_scattering_indices.clear()
	surface_scattering_colors.clear()
	xtot = 0
	ytot = 0
	ztot = 0
	snum = 0

func updateSurfaceFragments():
	Globals.feltyrion.update_time() # strange, this does not take into effect the first time this function is called?
	Globals.feltyrion.prepare_planet_surface()
	#Globals.feltyrion.testSurface() # temporary testing - may not be implemented in feltyrion-godot
	bake_surface_scattering()
	%SurfaceScattering.mesh = st.commit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	if int(time) > lastTime:
		lastTime = int(time)
		#clearSurfaceVars()
		#updateSurfaceFragments()
	pass

func on_found_surface_polygon3(x0, x1, x2, y0, y1, y2, z0, z1, z2, colore):
	const MULT = 0.001
	
	if xtot == 0:
		xtot = x0
		ytot = -y0
		ztot = z0
	
	var addVert = func addVert(x,y,z):
		var v = Vector3(
			(x - xtot) * MULT,
			(-y - ytot) * MULT,
			(z - ztot) * MULT
		)
		surface_scattering_verts.append(v)
	
	addVert.call(x0,y0,z0)
	addVert.call(x1,y1,z1)
	addVert.call(x2,y2,z2)
	
	surface_scattering_colors.append(Color8(colore, 0, 0, 255))
	surface_scattering_colors.append(Color8(colore, 0, 0, 255))
	surface_scattering_colors.append(Color8(colore, 0, 0, 255))
	
	surface_scattering_uvs.append(Vector2(0,0))
	surface_scattering_uvs.append(Vector2(1,0))
	surface_scattering_uvs.append(Vector2(0,1))
	
	var ind = surface_scattering_indices.size()
	surface_scattering_indices.append(ind+0)
	surface_scattering_indices.append(ind+1)
	surface_scattering_indices.append(ind+2)
	
func bake_surface_scattering():	
	# Use SurfaceTool to calculate our normals and generate our actual mesh
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 1, 1))
	st.set_smooth_group(-1) # set the smooth group to -1; this gives us flat shading, which is more Noctis-like
	var size = surface_scattering_indices.size()
	for i in range(0, size, 3):
		for j in range(0, 3):
			st.set_color(surface_scattering_colors[surface_scattering_indices[i + j]])
			st.set_uv(surface_scattering_uvs[surface_scattering_indices[i + j]])
			st.add_vertex(surface_scattering_verts[surface_scattering_indices[i + j]])
	st.generate_normals()
	
	
func fix_coordinates(x,y,z):
	Globals.feltyrion.set_nearstar(x,y,z)
	Globals.set_ap_target(Globals.feltyrion.get_nearstar_x(), Globals.feltyrion.get_nearstar_y(), Globals.feltyrion.get_nearstar_z())
	Globals.feltyrion.dzat_x = Globals.feltyrion.get_nearstar_x()
	Globals.feltyrion.dzat_y = Globals.feltyrion.get_nearstar_y()
	Globals.feltyrion.dzat_z = Globals.feltyrion.get_nearstar_z()
	
