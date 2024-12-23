extends Resource
class_name VimanaDrive

const VIMANA_SPEED = 50000
const VIMANA_APPROACH_DISTANCE = 10
const VIMANA_APPROACH_DISTANCE_DIRECT_PARSIS_TARGET = 25000
const VIMANA_APPROACH_DISTANCE_MULTIPLIER_ANTIRAD = 44
const VIMANA_APPROACH_DISTANCE_MULTIPLIER_NORMAL = 1.5

var feltyrion: Feltyrion
var requested_vimana_coefficient;
var vimana_coefficient;
var vimana_reaction_time
var _initial_vimana_distance
			
func _init(feltyrion: Feltyrion):
	self.feltyrion = feltyrion
	Globals.on_ap_target_changed.connect(_ap_target_changed)

signal vimana_status_change(vimana_drive_active: bool)
@export var active: bool = false ## Whether vimana is active or not. Do not modify this directly (unless you're loading a game) - use `vimanaStart()` and `vimanaStop()` instead.


func vimanaStop():
	active = false
	feltyrion.stspeed = 0
	vimana_status_change.emit(active)

func vimanaStart():
	Globals.local_target_orbit_index = -1
	Globals.local_target_index = -1
	active = true
	feltyrion.stspeed = 1
	feltyrion.ap_reached = 0
	var dx = feltyrion.dzat_x - feltyrion.ap_target_x
	var dy = feltyrion.dzat_y - feltyrion.ap_target_y
	var dz = feltyrion.dzat_z - feltyrion.ap_target_z
	_initial_vimana_distance = sqrt(dx*dx + dy*dy + dz*dz)
	requested_vimana_coefficient = 1000 * _initial_vimana_distance
	vimana_coefficient = requested_vimana_coefficient
	vimana_reaction_time = 0.01
	vimana_status_change.emit(active)

func process(delta):
	if active:
		# this has some precision issues initially as you Vimana far across the universe, but will become more precise as you get closer
		var dx = feltyrion.dzat_x - feltyrion.ap_target_x
		var dy = feltyrion.dzat_y - feltyrion.ap_target_y
		var dz = feltyrion.dzat_z - feltyrion.ap_target_z
		var dist = sqrt(dx*dx + dy*dy + dz*dz)
		var approach_vector = Vector3(dx, dy, dz)
		var ray_dist_multiplier = VIMANA_APPROACH_DISTANCE_MULTIPLIER_NORMAL if true else VIMANA_APPROACH_DISTANCE_MULTIPLIER_ANTIRAD # TODO: set this based on the anti radiation setting
		var target_distance = (ray_dist_multiplier * feltyrion.get_ap_target_info().ap_target_ray) if Globals.feltyrion.ap_targetted == 1 else VIMANA_APPROACH_DISTANCE_DIRECT_PARSIS_TARGET
		
		if dist < target_distance:
			Globals.update_fcs_status_text("CALIBRATED", 0)
			if Globals.feltyrion.ap_targetted == 1:
				_arrive_at_star(approach_vector)
			elif Globals.feltyrion.ap_targetted == -1:
				_arrive_at_direct_parsis_target(approach_vector)
		else:
			if dist > 0.9999 * _initial_vimana_distance:
				requested_vimana_coefficient = 0.001 * dist
				Globals.update_fcs_status_text("CHARGING", 0)
				vimana_reaction_time = 0.1
				_drive(dx, dy, dz, dist, delta)
			elif dist < 7500 + target_distance:
				requested_vimana_coefficient = 0.005 * dist
				Globals.update_fcs_status_text("PARKING", 0)
				vimana_reaction_time = 0.01
				_drive(dx, dy, dz, dist, delta)
			elif dist < 15000 + target_distance:
				requested_vimana_coefficient = 0.005 * dist
				Globals.update_fcs_status_text("LINKING", 0)
				vimana_reaction_time = 0.0025
				_drive(dx, dy, dz, dist, delta)
			elif dist < 0.9990 * _initial_vimana_distance:
				requested_vimana_coefficient = 0.00001 * dist
				Globals.update_fcs_status_text("DRIVING", 0)
				vimana_reaction_time = 0.05
				_drive(dx, dy, dz, dist, delta)
			else:
				requested_vimana_coefficient = 0.0002 * dist
				Globals.update_fcs_status_text("IGNITION", 0)
				vimana_reaction_time = 0.08
				_drive(dx, dy, dz, dist, delta)

func _arrive_at_star(approach_vector: Vector3):
	printt("we have arrived at remote target; expecting a star")
	feltyrion.ap_reached = 1
	feltyrion.set_nearstar(feltyrion.ap_target_x, feltyrion.ap_target_y, feltyrion.ap_target_z)
	feltyrion.prepare_star()
	var av = (approach_vector.normalized() * -1 * VIMANA_APPROACH_DISTANCE)
	feltyrion.dzat_x = feltyrion.ap_target_x - av.x
	feltyrion.dzat_y = feltyrion.ap_target_y # make sure we're in the same plane as the solar system, like Noctis does
	feltyrion.dzat_z = feltyrion.ap_target_z - av.z
	Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
	vimanaStop()

func _arrive_at_direct_parsis_target(approach_vector: Vector3):
	printt("we have arrived at remote target; expecting nothing (direct parsis target)")
	feltyrion.ap_reached = 1
	var av = (approach_vector.normalized() * -1 * VIMANA_APPROACH_DISTANCE)
	feltyrion.dzat_x = feltyrion.ap_target_x - av.x
	feltyrion.dzat_y = feltyrion.ap_target_y - av.y
	feltyrion.dzat_z = feltyrion.ap_target_z - av.z
	Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
	vimanaStop()

func _drive(dx, dy, dz, dist, delta):
	var d = delta * 23
	vimana_coefficient = max(10, vimana_coefficient + (requested_vimana_coefficient - vimana_coefficient) * (vimana_reaction_time))
	feltyrion.dzat_x -= (dx / vimana_coefficient) * d
	feltyrion.dzat_y -= (dy / vimana_coefficient) * d
	feltyrion.dzat_z -= (dz / vimana_coefficient) * d
	feltyrion.pwr = feltyrion.pwr - dist * 0.00001
	Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
	updateHUD(dist)
	
func updateHUD(dist):
	var ly = dist * 0.00005
	Globals.update_hud_lightyears_text("%1.2f L.Y." % ly)

func _ap_target_changed(_x, _y, _z, _id_code):
	var dx = feltyrion.dzat_x - feltyrion.ap_target_x
	var dy = feltyrion.dzat_y - feltyrion.ap_target_y
	var dz = feltyrion.dzat_z - feltyrion.ap_target_z
	updateHUD(sqrt(dx*dx + dy*dy + dz*dz))
