extends Node3D

## Regression test for #53: rings must be shown after loading a game that was
## saved around a ringed world. Run with:
##   godot --headless --path . res://testing/rings_on_load_test.tscn

const SYSTEM = preload("res://scenes/space/local/space_local_system.tscn")

var failures = 0

func _ready():
	var system = SYSTEM.instantiate()
	add_child(system)
	await get_tree().process_frame

	_prepare_default_system()
	var ringed_body = _find_ringed_planet()
	check(ringed_body != -1, "found a ringed planet in the current system")
	if ringed_body == -1:
		_finish()
		return
	var ringed_info = Globals.feltyrion.get_planet_info(ringed_body)
	print("RINGED_BODY=%d RING=%s RAY=%s" % [ringed_body, str(ringed_info.nearstar_p_ring), str(ringed_info.nearstar_p_ray)])

	# Emulate the state right after loading a game that was saved while orbiting
	# this ringed world. The ship is deliberately left far away from the planet
	# (at the star), since ring particles are distance-LODed by the engine.
	Globals.feltyrion.ip_targetted = ringed_body
	Globals.feltyrion.ip_reached = 1
	Globals.local_target_orbit_index = ringed_body
	var dzat_before = Vector3(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z)

	system.on_game_loaded()
	await get_tree().process_frame
	await get_tree().process_frame

	var planets = system.get_node("%Planets")
	check(planets.get_child_count() > ringed_body, "the system was loaded")
	if planets.get_child_count() <= ringed_body:
		_finish()
		return

	var ring = planets.get_child(ringed_body).get_node("PlanetParent/PlanetRing")
	var visible_particles = 0
	for child in ring.get_children():
		if child.visible:
			visible_particles += 1
	print("VISIBLE_RING_PARTICLES=%d" % visible_particles)
	check(visible_particles > 0, "the ringed world has ring particles after loading")

	var dzat_after = Vector3(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z)
	check(dzat_after.is_equal_approx(dzat_before), "populating the rings did not move the ship (was %s, now %s)" % [dzat_before, dzat_after])

	_finish()

func _find_ringed_planet() -> int:
	var info = Globals.feltyrion.get_current_star_info()
	for i in range(0, info.get("nearstar_nob", 0)):
		var planet = Globals.feltyrion.get_planet_info(i)
		if planet.nearstar_p_ring != 0.0 and planet.nearstar_p_owner == -1:
			return i
	return -1

func _prepare_default_system():
	Globals.feltyrion.lock()
	Globals.feltyrion.set_nearstar(-18928, -29680, -67336)
	Globals.set_ap_target(Globals.feltyrion.get_nearstar_x(), Globals.feltyrion.get_nearstar_y(), Globals.feltyrion.get_nearstar_z())
	Globals.feltyrion.dzat_x = Globals.feltyrion.get_nearstar_x()
	Globals.feltyrion.dzat_y = Globals.feltyrion.get_nearstar_y()
	Globals.feltyrion.dzat_z = Globals.feltyrion.get_nearstar_z()
	Globals.feltyrion.ap_reached = 1
	Globals.feltyrion.update_time()
	Globals.feltyrion.prepare_star()
	Globals.feltyrion.unlock()

func _finish():
	print("RESULT: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	get_tree().quit(0 if failures == 0 else 1)

func check(cond, msg):
	if cond:
		print("  OK: ", msg)
	else:
		failures += 1
		print("  FAIL: ", msg)
