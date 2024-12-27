extends Node3D
class_name PlanetRing

@export var planetindex: int = -2
@export var ringParticleBase: Sprite3D
const maxparticles = 5555
var _cachedPlanetinfo
var _lastCacheTime = 0
var _lastp = 0
var _precreatedRingParticles = false

func _ready():
	Globals.feltyrion.connect("found_ring_particle", on_ring_particle_found)

func _precreateRingParticles():
	for i in range(0, maxparticles):
		var particle: Sprite3D = ringParticleBase.duplicate()
		particle.position = Vector3(0,0,0)
		particle.hide()
		add_child(particle)
	_precreatedRingParticles = true

func on_ring_particle_found(x, y, z, radii, unconditioned_color, body_index):
	# x/y/z is in global parsis (!)
	if planetindex != body_index:
		return

	var curtime = Time.get_unix_time_from_system()
	if curtime - _lastCacheTime > 15: # it has been 15 seconds since we last got any particle locations, so create them if needed, clear (hide) them all and reload our info
		_lastCacheTime = curtime
		if not _precreatedRingParticles:
			_precreateRingParticles()
		_clearparticles()
		_cachedPlanetinfo = Globals.feltyrion.get_planet_info(planetindex)
		
	var rp: Sprite3D = get_child(_lastp)
	rp.show()
	
	var v = Vector3((x - _cachedPlanetinfo.nearstar_p_plx), (y - _cachedPlanetinfo.nearstar_p_ply - 0.0005), (z - _cachedPlanetinfo.nearstar_p_plz))
	rp.position = v
	_lastp += 1
	if _lastp > maxparticles - 1:
		_lastp = 0


func _clearparticles():
	printt("clearing particles for planet", planetindex)
	for i in range(0, maxparticles):
		var particle: Sprite3D = get_child(i)
		particle.position = Vector3(0,0,0)
		particle.hide()
