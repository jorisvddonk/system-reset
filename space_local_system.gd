extends Node3D
var Farstar = preload("res://far_star.tscn")
var Planet = preload("res://Planet.tscn")
@onready var regex = RegEx.new()

func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	#Globals.feltyrion.found_planet.connect(_on_found_planet) # temporarily disabled
	Globals.vimana_status_change.connect(_on_vimana_status_change)
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	
func _process(delta):
	# TODO: determine how often this actually needs to be called
	#Globals.feltyrion.set_secs(Globals.feltyrion.get_secs() + (1000 * delta))
	Globals.feltyrion.update_time()
	Globals.feltyrion.update_current_star_planets($SolarSystemContainer/Planets.get_path())
	
func _on_found_planet(index, planet_id, seedval, x, y, z, type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, rotation, viewpoint, term_start, term_end, qsortindex, qsortdist):
	var planet_name = Globals.feltyrion.get_planet_name_by_id(planet_id)
	#var planet_name = "planet_name"
	#printt("Found planet: ", planet_name, index, planet_id, seedval, x, y, z, "----", type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, "rotation", rotation, term_start, term_end, qsortindex, qsortdist)
	var planet = Planet.instantiate()
	planet.type = type
	planet.seed = seedval
	planet.planet_index = index
	planet.planet_name = planet_name
	planet.planet_viewpoint = viewpoint
	planet.planet_rotation = rotation
	#planet.translate(Vector3(index * 5 if owner == -1 else owner * 5, 0 if owner == -1 else (moonid + 1) * -5, 0)) # alternative placement; makes it easy to see all planets in an overview
	planet.translate(Vector3(-(Globals.feltyrion.ap_target.x - x), (Globals.feltyrion.ap_target.y - y), (Globals.feltyrion.ap_target.z - z))) # TODO: check if y should be flipped here..
	var layer_fixer = func(item): item.set_layer_mask(4); return true
	planet.find_children("?*", "CSGSphere3D", true).all(layer_fixer)
	$SolarSystemContainer/Planets.add_child(planet)

func _on_vimana_status_change(vimana_is_active):
	if vimana_is_active:
		$SolarSystemContainer/Planets.hide()
		$SolarSystemContainer/SolarSystemParentStar.hide()
	else:
		on_arrive_at_star()

func _on_parsis_changed(parsis: Vector3):
	var pos = (Globals.current_solar_system_star_parsis - parsis)
	$SolarSystemContainer.position = Vector3(pos.x, pos.y, -pos.z) # yes, Z is swapped. Don't ask me why. # TODO: check if Y should be swapped here as well

func on_arrive_at_star():
	for item in $SolarSystemContainer/Planets.get_children():
		$SolarSystemContainer/Planets.remove_child(item)
	print("Creating planets...")
	print(Time.get_unix_time_from_system())
	Globals.feltyrion.prepare_star()
	var data = Globals.feltyrion.get_current_star_info()
	print(data)
	for i in range(0,data.nearstar_nob):
		var pl_data = Globals.feltyrion.get_planet_info(i)
		print("Found planet: ", pl_data)
		_on_found_planet(i, pl_data.nearstar_p_identity, pl_data.nearstar_p_seedval,
			pl_data.nearstar_p_plx,
			pl_data.nearstar_p_ply,
			pl_data.nearstar_p_plz,
			pl_data.nearstar_p_type,
			pl_data.nearstar_p_owner,
			pl_data.nearstar_p_moonid,
			pl_data.nearstar_p_ring,
			pl_data.nearstar_p_tilt,
			pl_data.nearstar_p_ray,
			pl_data.nearstar_p_orb_ray,
			pl_data.nearstar_p_orb_tilt,
			pl_data.nearstar_p_orb_orient,
			pl_data.nearstar_p_orb_ecc,
			pl_data.nearstar_p_rtperiod,
			pl_data.nearstar_p_rotation,
			pl_data.nearstar_p_viewpoint,
			pl_data.nearstar_p_term_start,
			pl_data.nearstar_p_term_end,
			pl_data.nearstar_p_qsortindex,
			pl_data.nearstar_p_qsortdist)
	print("done creating planets")
	print(Time.get_unix_time_from_system())
	$SolarSystemContainer/Planets.show()
	$SolarSystemContainer/SolarSystemParentStar.show()
