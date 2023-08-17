extends Node2D

func _ready():
	#fix_coordinates(-18928, -29680, -67336) # balastrackonastreya
	#fix_coordinates(-56784, -15693, -129542) # ylastravenya
	Globals.feltyrion.landing_point = 1 # enable "setting landing point" mode. Without this, nightzone isn't calculated correctly.
	$Button.pressed.connect(_on_generate_pressed)
	$Button2.pressed.connect(_on_generate_from_parsis_pressed)
	$LandingPtLat.value_changed.connect(update_latlon)
	$LandingPtLon.value_changed.connect(update_latlon)
	_on_generate_pressed()
	update_latlon(0)
	
func _on_generate_from_parsis_pressed():
	$TextureRect2.show()
	$TextureRect3.show()
	$TextureRect4.show()
	fix_coordinates(float($ParsisX.text), -float($ParsisY.text), float($ParsisZ.text))
	generate(int($PlanetIndex.text), $OptionButton.selected, float($SeedInput.text))
	
func _on_generate_pressed():
	$TextureRect2.hide()
	$TextureRect3.hide()
	$TextureRect4.hide()
	fix_coordinates(0,0,0)
	if ($SeedInput.text == ""):
		randomize()
		generate(-1, $OptionButton.selected, randf() * 1000)
	else:
		generate(-1, $OptionButton.selected, float($SeedInput.text))
	
func update_latlon(_a):
	$Label.text = "tgt: %s:%s" % [$LandingPtLon.value, $LandingPtLat.value]

func fix_coordinates(x,y,z):
	Globals.feltyrion.set_nearstar(x,y,z)
	Globals.set_ap_target(Globals.feltyrion.get_nearstar_x(), Globals.feltyrion.get_nearstar_y(), Globals.feltyrion.get_nearstar_z())
	Globals.feltyrion.dzat_x = Globals.feltyrion.get_nearstar_x()
	Globals.feltyrion.dzat_y = Globals.feltyrion.get_nearstar_y()
	Globals.feltyrion.dzat_z = Globals.feltyrion.get_nearstar_z()

func generate(planet_index, type, seed):
	Globals.feltyrion.lock() 
	Globals.feltyrion.update_time() # strange, this does not take into effect the first time this function is called?
	Globals.feltyrion.ip_targetted = planet_index if planet_index != -1 else 0
	Globals.feltyrion.ip_reached = 1
	Globals.feltyrion.landing_pt_lat = $LandingPtLat.value
	Globals.feltyrion.landing_pt_lon = $LandingPtLon.value
	
	Globals.feltyrion.prepare_star()
	
	if planet_index == -1:
		Globals.feltyrion.load_planet(0, type, seed, true, false)
	else:
		Globals.feltyrion.load_planet_at_current_system(planet_index)
	
	var img = Globals.feltyrion.return_image(true, false)
	#img = Globals.feltyrion.return_atmosphere_image()
	var imageTexture = ImageTexture.create_from_image(img)
	$TextureRect.texture = imageTexture
	$TextureRect.queue_redraw()
		
	Globals.feltyrion.prepare_planet_surface()
	
	var skyimg = Globals.feltyrion.return_sky_image()
	var skyTexture = ImageTexture.create_from_image(skyimg)
	$TextureRect2.texture = skyTexture
	$TextureRect2.queue_redraw()

	var surfimg = Globals.feltyrion.return_surfacemap_image()
	surfimg.adjust_bcs(2, 1, 1) # fix brightness so that maximum heightmap value is white
	var surfTexture = ImageTexture.create_from_image(surfimg)
	$TextureRect3.texture = surfTexture
	$TextureRect3.queue_redraw()
	
	var txtrimg = Globals.feltyrion.return_txtr_image()
	var txtrTexture = ImageTexture.create_from_image(txtrimg)
	$TextureRect4.texture = txtrTexture
	$TextureRect4.queue_redraw()
	
	Globals.feltyrion.unlock()
	
