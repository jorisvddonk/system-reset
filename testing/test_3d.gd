extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.feltyrion.lock() 
	Globals.feltyrion.update_time() # strange, this does not take into effect the first time this function is called?
	Globals.feltyrion.ip_targetted = 3
	Globals.feltyrion.ip_reached = 1
	Globals.feltyrion.landing_point = 1 # enable "setting landing point" mode. Without this, nightzone isn't calculated correctly.
	Globals.feltyrion.landing_pt_lat = 30
	Globals.feltyrion.landing_pt_lon = 30
	
	Globals.feltyrion.prepare_star()
	Globals.feltyrion.load_planet_at_current_system(3)
	Globals.feltyrion.prepare_planet_surface()
	
	var txtimg = Globals.feltyrion.return_txtr_image()
	var txtrTexture = ImageTexture.create_from_image(txtimg)
	$TextureRect.texture = txtrTexture
	$TextureRect.queue_redraw()
	
	%MeshInstance3D.material_override.set_shader_parameter("cull_mode", 2)
	
	%MeshInstance3D.material_override.set_shader_parameter("albedo_texture", txtrTexture)
	
	Globals.feltyrion.unlock()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
