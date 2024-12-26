extends Node3D



# Called when the node enters the scene tree for the first time.
func _ready():
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
	Globals.feltyrion.prepare_planet_surface()
	Globals.planet_surface_prepared.emit()
	
	var txtimg = Globals.feltyrion.return_txtr_image(false)
	var txtrTexture = ImageTexture.create_from_image(txtimg)
	var txtRawimg = Globals.feltyrion.return_txtr_image(true)
	var txtrRawTexture = ImageTexture.create_from_image(txtRawimg)
	$TextureRect.texture = txtrRawTexture # txtrTextureF
	$TextureRect.queue_redraw()
	
	%MeshInstance3D.material_override.set_shader_parameter("cull_mode", 2)
	%MeshInstance3D.material_override.set_shader_parameter("albedo_texture", txtrTexture)
	
	var paletteimg = Globals.feltyrion.get_surface_palette_as_image()
	var paletteTexture = ImageTexture.create_from_image(paletteimg)
	$TextureRect2.texture = paletteTexture
	Globals.feltyrion.unlock()

func fix_coordinates(x,y,z):
	Globals.feltyrion.set_nearstar(x,y,z)
	Globals.set_ap_target(Globals.feltyrion.get_nearstar_x(), Globals.feltyrion.get_nearstar_y(), Globals.feltyrion.get_nearstar_z())
	Globals.feltyrion.dzat_x = Globals.feltyrion.get_nearstar_x()
	Globals.feltyrion.dzat_y = Globals.feltyrion.get_nearstar_y()
	Globals.feltyrion.dzat_z = Globals.feltyrion.get_nearstar_z()
	
