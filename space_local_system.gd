extends Node3D
var Farstar = preload("res://far_star.tscn")
var Planet = preload("res://Planet.tscn")
@onready var regex = RegEx.new()

func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	Globals.feltyrion.found_planet.connect(_on_found_planet)
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	
func _on_found_planet(index, planet_id, seedval, x, y, z, type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, rotation, term_start, term_end, qsortindex, qsortdist):
	var planet_name = Globals.feltyrion.get_planet_name_by_id(planet_id)
	printt("Found planet: ", planet_name, index, planet_id, seedval, x, y, z, "----", type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, "rotation", rotation, term_start, term_end, qsortindex, qsortdist)
	var planet = Planet.instantiate()
	planet.type = type
	planet.seed = seedval
	planet.planet_index = index
	planet.planet_name = planet_name
	#planet.translate(Vector3(index * 5 if owner == -1 else owner * 5, 0 if owner == -1 else (moonid + 1) * -5, 0)) # alternative placement; makes it easy to see all planets in an overview
	planet.translate(Vector3(-(Globals.feltyrion.ap_target.x - x), (Globals.feltyrion.ap_target.y - y), (Globals.feltyrion.ap_target.z - z))) # TODO: check if y should be flipped here..
	planet.get_node("PlanetParent").rotate_y(((rotation + 98) % 360) * (PI / 180)) # not entirely sure why '98' is the magic number here (it should be 89..?) but it seems to work!
	var layer_fixer = func(item): item.set_layer_mask(4); return true
	planet.find_children("?*", "CSGSphere3D", true).all(layer_fixer)
	$Planets.add_child(planet)

func _on_parsis_changed(vec3):
	# for now, we assume that when parsis changes, we need to clean the planets and wait for them to be found again
	for item in $Planets.get_children():
		$Planets.remove_child(item)
	Globals.feltyrion.lock()
	Globals.feltyrion.prepare_star()
	Globals.feltyrion.unlock()
