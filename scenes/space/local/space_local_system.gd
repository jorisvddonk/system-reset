extends Node3D
var Planet = preload("res://scenes/space/local/Planet.tscn")
@onready var regex = RegEx.new()

func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	Globals.vimana.linkingToStar.connect(_on_vimana_linking)
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	Globals.game_loaded.connect(on_game_loaded)
	Globals.gameplay_mode_changed.connect(on_gameplay_mode_changed)
	Globals.connect("_on_local_target_orbit_changed", on_local_target_orbit_changed)


func on_local_target_orbit_changed(index):
	if index != -1:
		# Force a load of the planetary body we're orbiting now. This ensures that rings are 'repopulated'.
		printt("Forcing load of planetary body with index", index)
		Globals.feltyrion.load_planet_at_current_system(index)

func _physics_process(delta):
	#Globals.feltyrion.set_secs(Globals.feltyrion.get_secs() + (1000 * delta)) # use this if you want to simulate accelerated time
	Globals.feltyrion.update_time()
	Globals.feltyrion.update_current_star_planets($SolarSystemContainer/Planets.get_path())
		
func _process(delta):
	if Globals.ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET:
		# figure out which planet is closest
		var playerrot = Globals.player_rotation_in_space.normalized()
		var rotation_basis: Basis = Basis().from_euler(Globals.player_rotation_in_space)
		var forward_vector: Vector3 = -rotation_basis.z
		var normalized_forward: Vector3 = forward_vector.normalized()
		var lowestdotdot = -1
		var lowestdotrot_node = null
		for planet in %Planets.get_children():
			if planet is Node3D and planet is Planet:
				var dotrot = normalized_forward.dot((planet.global_position - Globals.stardrifter.global_position).normalized())
				if dotrot > lowestdotdot:
					lowestdotdot = dotrot
					if lowestdotrot_node != null:
						lowestdotrot_node.setSelected(false)
					planet.setSelected(true)
					lowestdotrot_node = planet
				else:
					planet.setSelected(false)
		if lowestdotrot_node != null and lowestdotrot_node is Planet:
			Globals.update_hud_selected_planet_text((lowestdotrot_node as Planet).planet_name)

func on_game_loaded():
	_load_local_system()
	repositionContainer(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z)
	
func on_gameplay_mode_changed(_a):
	repositionContainer(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z)

func load_planet(index, planet_id, seedval, x, y, z, type, owner, moonid, ring, tilt, ray, orb_ray, orb_tilt, orb_orient, orb_ecc, rtperiod, rotation, viewpoint, term_start, term_end, qsortindex, qsortdist):
	var planet_name = Globals.feltyrion.get_planet_name_by_id(planet_id)
	var planet = Planet.instantiate()
	planet.type = type
	planet.seed = seedval
	planet.planet_index = index
	planet.planet_name = planet_name
	planet.planet_viewpoint = viewpoint
	planet.planet_term_start = term_start
	planet.planet_rotation = rotation
	planet.planet_pos_relative_to_star_x = (x - Globals.feltyrion.get_nearstar_x())
	planet.planet_pos_relative_to_star_y = (y - Globals.feltyrion.get_nearstar_y())
	planet.planet_pos_relative_to_star_z = (z - Globals.feltyrion.get_nearstar_z())
	planet.translate(Vector3((x - Globals.feltyrion.get_nearstar_x()), (y - Globals.feltyrion.get_nearstar_y()), (z - Globals.feltyrion.get_nearstar_z())))
	planet.ringParticleBase = %RingParticleBase
	$SolarSystemContainer/Planets.add_child(planet)

func _on_parsis_changed(x: float, y: float, z: float):
	repositionContainer(x, y, z)
	
func repositionContainer(x: float, y: float, z: float):
	$SolarSystemContainer.position = Vector3(Globals.feltyrion.get_nearstar_x() - x, Globals.feltyrion.get_nearstar_y() - y, Globals.feltyrion.get_nearstar_z() - z)

func _on_vimana_linking():
	_load_local_system()
	
func _load_local_system():
	for item in $SolarSystemContainer/Planets.get_children():
		item.queue_free()
	print("Creating planets...")
	print(Time.get_unix_time_from_system())
	Globals.feltyrion.update_time()
	var data = Globals.feltyrion.get_current_star_info()
	if !data.has("nearstar_class"):
		print("WARN(_load_local_system): current star info seems to be empty...")
		$SolarSystemContainer.hide()
		return
	print(data)
	$SolarSystemContainer.show()
	var material = $SolarSystemContainer/SolarSystemParentStar.get_active_material(0)
	var clr = Color(float(data.nearstar_r)/64, float(data.nearstar_g)/64, float(data.nearstar_b)/64, 1)
	material.set_shader_parameter("color", clr)
	var scale_factor = float(data.nearstar_ray) / 13
	$SolarSystemContainer/SolarSystemParentStar.scale = Vector3(scale_factor, scale_factor, scale_factor)
	for i in range(0,data.nearstar_nob):
		var pl_data = Globals.feltyrion.get_planet_info(i)
		print("Found planet: ", pl_data)
		load_planet(i, pl_data.nearstar_p_identity, pl_data.nearstar_p_seedval,
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
