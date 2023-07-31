extends Node3D
var Farstar = preload("res://far_star.tscn")
var Planet = preload("res://Planet.tscn")
@onready var regex = RegEx.new()



# Called when the node enters the scene tree for the first time.
func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	Globals.feltyrion.found_star.connect(_on_found_star)
	Globals.feltyrion.found_planet.connect(_on_found_planet)
	Globals.feltyrion.lock()
	#Globals.set_parsis(Vector3(3579984, -1002801, 305857)) # 'hello' star
	Globals.feltyrion.scan_stars()
	Globals.feltyrion.prepare_star()
	Globals.feltyrion.unlock()
	
	var layer_fixer = func(item): item.set_layer_mask(2); return true
	$vehicle.find_children("?*", "MeshInstance3D").all(layer_fixer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_found_planet(index, planet_id, seedval, x, y, z, type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, rotation, term_start, term_end, qsortindex, qsortdist):
	var planet_name = Globals.feltyrion.get_planet_name_by_id(planet_id)
	printt("Found planet: ", planet_name, index, planet_id, seedval, x, y, z, "----", type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, "rotation", rotation, term_start, term_end, qsortindex, qsortdist)
	var planet = Planet.instantiate()
	planet.type = type
	planet.seed = seedval
	planet.planet_index = index
	planet.planet_name = planet_name
	#planet.translate(Vector3(index * 5 if owner == -1 else owner * 5, 0 if owner == -1 else (moonid + 1) * -5, 0))
	planet.translate(Vector3(-(Globals.feltyrion.ap_target.x - x), (Globals.feltyrion.ap_target.y - y), (Globals.feltyrion.ap_target.z - z))) # TODO: check if y should be flipped here..
	planet.get_node("PlanetParent").rotate_y(((rotation + 98) % 360) * (PI / 180)) # not entirely sure why '98' is the magic number here (it should be 89..?) but it seems to work!
	var layer_fixer = func(item): item.set_layer_mask(4); return true
	planet.find_children("?*", "CSGSphere3D", true).all(layer_fixer)
	$Planets.add_child(planet)

func _on_found_star(x, y, z):
	var objname = Globals.feltyrion.get_star_name(x, y, z)
	# print(x, ":", y, ":", z, " --- name: ", objname)
	objname = regex.sub(objname, "")
	var star = Farstar.instantiate()
	star.star_name = objname
	star.parsis = Vector3(x, y, z)
	star.translate(Vector3(x/1000, y/1000, z/1000))
	$Stars.add_child(star)
