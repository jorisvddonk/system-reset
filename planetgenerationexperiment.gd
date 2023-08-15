extends Node2D

func _ready():
	$Button.pressed.connect(_on_generate_pressed)
	Globals.feltyrion.prepare_star()
	_on_generate_pressed()
	
func _on_generate_pressed():
	if ($SeedInput.text == ""):
		randomize()
		generate(int($PlanetIndex.text), $OptionButton.selected, randf() * 1000)
	else:
		generate(int($PlanetIndex.text), $OptionButton.selected, float($SeedInput.text))

func generate(planet_index, type, seed):
	Globals.feltyrion.landing_pt_lat = $LandingPtLat.value
	Globals.feltyrion.landing_pt_lon = $LandingPtLon.value
	Globals.feltyrion.lock()
	
	Globals.feltyrion.load_planet(planet_index, type, seed, true, false)
	var img = Globals.feltyrion.return_image(true, false)
	#img = Globals.feltyrion.return_atmosphere_image()
	var imageTexture = ImageTexture.create_from_image(img)
	$TextureRect.texture = imageTexture
	$TextureRect.queue_redraw()
	
	Globals.feltyrion.ip_targetted = planet_index
	Globals.feltyrion.ip_reached = 1
	Globals.set_ap_target(-18928, -29680, -67336)
	Globals.feltyrion.set_nearstar(-18928, -29680, -67336)
	Globals.feltyrion.dzat_x = -18928
	Globals.feltyrion.dzat_y = -29680
	Globals.feltyrion.dzat_z = -67336
	
	
	Globals.feltyrion.prepare_planet_surface()
	var skyimg = Globals.feltyrion.return_sky_image()
	var skyTexture = ImageTexture.create_from_image(skyimg)
	$TextureRect2.texture = skyTexture
	$TextureRect2.queue_redraw()
	
	var surfimg = Globals.feltyrion.return_surfacemap_image()
	var surfTexture = ImageTexture.create_from_image(surfimg)
	$TextureRect3.texture = surfTexture
	$TextureRect3.queue_redraw()
	
	var txtrimg = Globals.feltyrion.return_txtr_image()
	var txtrTexture = ImageTexture.create_from_image(txtrimg)
	$TextureRect4.texture = txtrTexture
	$TextureRect4.queue_redraw()
	
	
	Globals.feltyrion.unlock()
	
