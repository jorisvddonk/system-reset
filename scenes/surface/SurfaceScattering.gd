extends MeshInstance3D

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
var forceRebake = false
# 3260416 ??
const SEC_H_SIZE = 16384
const SEC_V_SIZE = 2048
const SEC_X_ROOT = SEC_H_SIZE * 100
const SEC_Y_ROOT = SEC_V_SIZE * 0
const SEC_Z_ROOT = SEC_H_SIZE * 100
enum CaptureWhat {NONE, SCATTERING, SURFACE};
@export var capture: CaptureWhat = CaptureWhat.NONE;
@export var generateCollision: bool = false;
@export var colorPaletteOffset: int = 0;
signal meshUpdated

# Called when the node enters the scene tree for the first time.
func _ready():
	clearSurfaceVars()
	if (capture == CaptureWhat.SURFACE):
		Globals.feltyrion.connect("found_surface_polygon3", on_found_polygon3)
	if (capture == CaptureWhat.SCATTERING):
		Globals.feltyrion.connect("found_scattering_polygon3", on_found_polygon3)

func clearSurfaceVars():
	surface_scattering_verts.clear()
	surface_scattering_uvs.clear()
	surface_scattering_indices.clear()
	surface_scattering_colors.clear()
	xtot = 0
	ytot = 0
	ztot = 0
	snum = 0

var done = false
func updateSurfaceFragments():
	Globals.feltyrion.update_time() # strange, this does not take into effect the first time this function is called?
	#Globals.feltyrion.prepare_planet_surface()
	Globals.feltyrion.generateSurfacePolygons() # temporary testing

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	if forceRebake:
		bake_surface_scattering()
	if int(time) > lastTime and not done:
		done = true
		lastTime = int(time)
		clearSurfaceVars()
		updateSurfaceFragments()
		bake_surface_scattering()
	

func on_found_polygon3(x0, x1, x2, y0, y1, y2, z0, z1, z2, colore):
	const MULT = 0.002
	forceRebake = true
	
	if xtot == 0:
		xtot = SEC_X_ROOT
		ytot = SEC_Y_ROOT
		ztot = SEC_Z_ROOT
		printt("FIRST VERT", x0, y0, z0)
	
	var addVert = func addVert(x,y,z):
		var v = Vector3(
			(x - xtot) * -MULT,
			(-y - ytot) * MULT,
			(z - ztot) * MULT
		)
		surface_scattering_verts.append(v)
	
	addVert.call(x0,y0,z0)
	addVert.call(x1,y1,z1)
	addVert.call(x2,y2,z2)
	
	surface_scattering_colors.append(Color8(colore+colorPaletteOffset, 0, 0, 255))
	surface_scattering_colors.append(Color8(colore+colorPaletteOffset, 0, 0, 255))
	surface_scattering_colors.append(Color8(colore+colorPaletteOffset, 0, 0, 255))
	
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
	if generateCollision:
		self.create_trimesh_collision()
		# self.get_child(0).get_child(0).get_child(0).backface_collision = true # this doesn't seem to work anymore... but thankfully it doesn't seem to matter!
	forceRebake = false
	self.mesh = st.commit()
	var txtRawimg = Globals.feltyrion.return_txtr_image(true)
	var txtrRawTexture = ImageTexture.create_from_image(txtRawimg)
	self.material_override.set_shader_parameter("albedo_texture_format_l8", txtrRawTexture)
	var paletteimg = Globals.feltyrion.get_surface_palette_as_image()
	var paletteTexture = ImageTexture.create_from_image(paletteimg)
	self.material_override.set_shader_parameter("surface_palette", paletteTexture)
	
	self.meshUpdated.emit()
