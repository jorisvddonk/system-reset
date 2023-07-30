extends Node3D
var Farstar = preload("res://far_star.tscn")
var Planet = preload("res://Planet.tscn")
@onready var feltyrion = Feltyrion.new()
@onready var regex = RegEx.new()



# Called when the node enters the scene tree for the first time.
func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	feltyrion.found_star.connect(_on_found_star)
	feltyrion.found_planet.connect(_on_found_planet)
	feltyrion.lock()
	feltyrion.scan_stars()
	feltyrion.prepare_star()
	feltyrion.unlock()
	
	var layer_fixer = func(item): item.set_layer_mask(2); return true
	$vehicle.find_children("?*", "MeshInstance3D").all(layer_fixer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_found_planet(index, planet_id, seedval, x, y, z, type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, rotation, term_start, term_end, qsortindex, qsortdist):
	var planet_name = feltyrion.get_planet_name_by_id(planet_id)
	printt("Found planet: ", planet_name, index, planet_id, seedval, x, y, z, "----", type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, rotation, term_start, term_end, qsortindex, qsortdist)
	var planet = Planet.instantiate()
	planet.feltyrion = feltyrion
	planet.type = type
	planet.seed = seedval
	planet.planet_index = index
	planet.planet_name = planet_name
	# planet.translate(Vector3(index * 5 if owner == -1 else owner * 5, 0 if owner == -1 else (moonid + 1) * -5, 0))
	planet.rotate_y(orb_orient * (PI / 180))
	planet.translate(Vector3((feltyrion.ap_target.x - x), (feltyrion.ap_target.y - y), (feltyrion.ap_target.z - z)))
	var layer_fixer = func(item): item.set_layer_mask(4); return true
	planet.find_children("?*", "CSGSphere3D").all(layer_fixer)
	$Planets.add_child(planet)

func _on_found_star(x, y, z):
	var objname = feltyrion.get_star_name(x, y, z)
	# print(x, ":", y, ":", z, " --- name: ", objname)
	objname = regex.sub(objname, "")
	var star = Farstar.instantiate()
	star.translate(Vector3(x/1000, y/1000, z/1000))
	$Stars.add_child(star)
	star.get_node("Label3D").text = objname
