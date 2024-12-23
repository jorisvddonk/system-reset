extends Resource
class_name InterplanetaryDrive

const PIDController = preload("res://util/PIDController.gd")
const FINE_APPROACH_RAY_MULTIPLIER = 5 # 2 in NIV, but that seems too close here

var feltyrion: Feltyrion
var dzat_y_PIDController: PIDController
var planetInfo

var requested_coefficient
var coefficient
var reaction_time
var initial_distance

signal fine_approach_status_change(val: bool)
@export var active = false:
	get:
		return active
	set(value):
		active = value
		feltyrion.ip_reaching = value
		if value == true:
			Globals.local_target_orbit_index = -1
		fine_approach_status_change.emit(value)
			
func _init(feltyrion: Feltyrion):
	self.feltyrion = feltyrion
	self.dzat_y_PIDController = PIDController.new(-1.4, -0.008, -0.3)
	Globals.chase_mode_changed.connect(_on_chase_mode_change)
	Globals._on_local_target_changed.connect(_on_local_target_changed)

func start():
	active = true
	var dx = feltyrion.dzat_x - feltyrion.get_ip_targetted_x()
	var dy = feltyrion.dzat_y - feltyrion.get_ip_targetted_y()
	var dz = feltyrion.dzat_z - feltyrion.get_ip_targetted_z()
	initial_distance = sqrt(dx*dx + dy*dy + dz*dz)
	requested_coefficient = 1000 * initial_distance
	coefficient = requested_coefficient
	reaction_time = 0.01
	planetInfo = feltyrion.get_planet_info(feltyrion.ip_targetted)
	
func stop():
	active = false

func _arrived():
	dzat_y_PIDController.reset()
	dzat_y_PIDController.setError(feltyrion.dzat_y - feltyrion.get_ip_targetted_y())
	var approach_vector = Vector3(feltyrion.get_ip_targetted_x() - feltyrion.dzat_x, feltyrion.get_ip_targetted_y() - feltyrion.dzat_y, feltyrion.get_ip_targetted_z() - feltyrion.dzat_z)
	Globals.chase_direction = Vector3(-approach_vector.x, 0.0, -approach_vector.z).normalized() # chase direction needs to be in the same plane as the planet
	Globals.local_target_orbit_index = Globals.local_target_index

func process(delta):
	if active:
		var dx = feltyrion.dzat_x - feltyrion.get_ip_targetted_x()
		var dy = feltyrion.dzat_y - feltyrion.get_ip_targetted_y()
		var dz = feltyrion.dzat_z - feltyrion.get_ip_targetted_z()
		var dist = sqrt(dx*dx + dy*dy + dz*dz)
		
		if dist > 0.99999 * initial_distance:
			requested_coefficient = 25 * dist
			Globals.update_fcs_status_text("WARMING UP", 0)
			reaction_time = 0.001
			_drive(dx, dy, dz, dist, delta)
		elif dist < 25 and initial_distance > 500:
			requested_coefficient = 50 * dist
			Globals.update_fcs_status_text("REFINING", 0)
			reaction_time = 0.0002
			_drive(dx, dy, dz, dist, delta)
		elif dist < 100 and initial_distance > 500:
			requested_coefficient = 15 * dist
			Globals.update_fcs_status_text("BREAKING", 0)
			reaction_time = 0.0003
			_drive(dx, dy, dz, dist, delta)
		elif dist < 0.995 * initial_distance:
			requested_coefficient = 0.05 * dist
			Globals.update_fcs_status_text("APPROACH", 0)
			reaction_time = 0.025
			_drive(dx, dy, dz, dist, delta)
		else:
			requested_coefficient = 1.5 * dist
			Globals.update_fcs_status_text("IGNITION", 0)
			reaction_time = 0.05
			_drive(dx, dy, dz, dist, delta)
		return

	
func updateHUD(dist):
	var dyams = dist * 0.01
	Globals.update_hud_dyams_text("%1.2f DYAMS" % dyams)

func _on_chase_mode_change(new_value):
	dzat_y_PIDController.reset()
	
func _drive(dx, dy, dz, dist, delta):
	var d = delta * 23
	coefficient = max(10, coefficient + ((requested_coefficient - coefficient) * reaction_time))
	feltyrion.dzat_x -= (dx / coefficient) * d
	feltyrion.dzat_y -= (dy / (0.5 * coefficient)) * d
	feltyrion.dzat_z -= (dz / coefficient) * d
	feltyrion.pwr = feltyrion.pwr - (dist * 0.000005)
	Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
	updateHUD(dist)
	if dist < FINE_APPROACH_RAY_MULTIPLIER * planetInfo.nearstar_p_ray:
		Globals.update_fcs_status_text("STANDBY", 0)
		stop()
		_arrived()

func _on_local_target_changed(planet_idx):
	if planet_idx != -1:
		var dx = feltyrion.dzat_x - feltyrion.get_ip_targetted_x()
		var dy = feltyrion.dzat_y - feltyrion.get_ip_targetted_y()
		var dz = feltyrion.dzat_z - feltyrion.get_ip_targetted_z()
		var dist = sqrt(dx*dx + dy*dy + dz*dz)
		updateHUD(dist)
