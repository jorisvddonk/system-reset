extends Node3D
var Planet = preload("res://scenes/space/local/Planet.tscn")
@onready var regex = RegEx.new()
var lastp = 0
const maxparticles = 5555
var last_particle_cleared_timestamp = 0

func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	Globals.vimana_status_change.connect(_on_vimana_status_change)
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	Globals.game_loaded.connect(on_game_loaded)
	Globals.feltyrion.connect("found_ring_particle", on_ring_particle_found)
	Globals.connect("_on_local_target_orbit_changed", on_local_target_orbit_changed)
	for i in range(0, maxparticles):
		var particle: Sprite3D = %RingParticle.duplicate()
		particle.position = Vector3(0,0,0)
		particle.hide()
		%RingParticles.add_child(particle)


func clearparticles():
	printt("clearing particles")
	for i in range(0, maxparticles):
		var particle: Sprite3D = %RingParticles.get_child(i)
		particle.position = Vector3(0,0,0)
		particle.hide()

func on_local_target_orbit_changed(index):
	if index != -1:
		# Force a load of the planetary body we're orbiting now. This ensures that rings are 'repopulated'.
		printt("Forcing load of planetary body with index", index)
		Globals.feltyrion.load_planet_at_current_system(index)

func on_ring_particle_found(x, y, z, radii, unconditioned_color, body_index):
	# x/y/z is in global parsis (!)
	if Globals.feltyrion.ip_targetted != body_index:
		return
	var curtime = Time.get_unix_time_from_system()
	if curtime - last_particle_cleared_timestamp > 1: # it has been 1 second since we last got any particle locations, so clear (hide) them all!
		last_particle_cleared_timestamp = curtime
		clearparticles()
	var rp: Sprite3D = %RingParticles.get_child(lastp)
	rp.show()
	var v = Vector3((x - Globals.feltyrion.ap_target_x), (y - Globals.feltyrion.ap_target_y - 0.0005), (z - Globals.feltyrion.ap_target_z))
	rp.position = v
	lastp += 1
	if lastp > maxparticles - 1:
		lastp = 0
	
func _physics_process(delta):
	# TODO: determine how often this actually needs to be called
	if Engine.physics_ticks_per_second == 24:
		# DEPRECATED - WILL BE REMOVED
		# 24 physics tics per second: use Noctis IV's engine for movement
		# TODO: determine what to do here :)
		pass
	else:
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
	check_arrived_at_star()
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
	planet.planet_pos_relative_to_star_x = (x - Globals.feltyrion.ap_target_x)
	planet.planet_pos_relative_to_star_y = (y - Globals.feltyrion.ap_target_y)
	planet.planet_pos_relative_to_star_z = (z - Globals.feltyrion.ap_target_z)
	planet.translate(Vector3((x - Globals.feltyrion.ap_target_x), (y - Globals.feltyrion.ap_target_y), (z - Globals.feltyrion.ap_target_z)))
	$SolarSystemContainer/Planets.add_child(planet)

func _on_vimana_status_change(vimana_is_active):
	check_arrived_at_star()

func _on_parsis_changed(x: float, y: float, z: float):
	repositionContainer(x, y, z)
	
func repositionContainer(x: float, y: float, z: float):
	$SolarSystemContainer.position = Vector3(Globals.feltyrion.ap_target_x - x, Globals.feltyrion.ap_target_y - y, Globals.feltyrion.ap_target_z - z)

func check_arrived_at_star():
	if Globals.vimana_active:
		$SolarSystemContainer/Planets.hide()
		$SolarSystemContainer/SolarSystemParentStar.hide()
	else:
		for item in $SolarSystemContainer/Planets.get_children():
			item.queue_free()
		if Globals.feltyrion.ap_reached and Globals.feltyrion.ap_targetted == 1:
			print("Creating planets...")
			print(Time.get_unix_time_from_system())
			Globals.feltyrion.update_time()
			var data = Globals.feltyrion.get_current_star_info()
			if !data.has("nearstar_class"):
				print("WARN(check_arrived_at_star): current star info seems to be empty...")
				return
			print(data)
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
