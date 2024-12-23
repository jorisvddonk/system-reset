extends Resource
class_name InterplanetaryDrive

const PIDController = preload("res://util/PIDController.gd")

const FINE_APPROACH_SPEED = 10
const FINE_APPROACH_DISTANCE = 0.25

var feltyrion: Feltyrion
var dzat_y_PIDController: PIDController
			
func _init(feltyrion: Feltyrion):
	self.feltyrion = feltyrion
	self.dzat_y_PIDController = PIDController.new(-1.4, -0.008, -0.3)

@export var active: bool = false ## Whether vimana is active or not. Do not modify this directly (unless you're loading a game) - use `vimanaStart()` and `vimanaStop()` instead.

func process(delta):
	var approach_vector = Vector3(feltyrion.get_ip_targetted_x() - feltyrion.dzat_x, feltyrion.get_ip_targetted_y() - feltyrion.dzat_y, feltyrion.get_ip_targetted_z() - feltyrion.dzat_z)
	if approach_vector.length() > FINE_APPROACH_DISTANCE + (FINE_APPROACH_SPEED * (delta*2)):
		approach_vector = approach_vector.normalized() * delta * FINE_APPROACH_SPEED
		feltyrion.dzat_x += approach_vector.x
		feltyrion.dzat_y += approach_vector.y
		feltyrion.dzat_z += approach_vector.z
		Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
	else:
		printt("we have arrived at local target")
		approach_vector = approach_vector.normalized() * FINE_APPROACH_DISTANCE
		Globals.local_target_orbit_index = Globals.local_target_index
		feltyrion.dzat_x = feltyrion.get_ip_targetted_x() - approach_vector.x
		feltyrion.dzat_y = feltyrion.get_ip_targetted_y() - approach_vector.y
		feltyrion.dzat_z = feltyrion.get_ip_targetted_z() - approach_vector.z
		Globals.fine_approach_active = false
		Globals.on_parsis_changed.emit(feltyrion.dzat_x, feltyrion.dzat_y, feltyrion.dzat_z)
		Globals.chase_direction = Vector3(-approach_vector.x, 0.0, -approach_vector.z).normalized() # chase direction needs to be in the same plane as the planet
		dzat_y_PIDController.reset()
		dzat_y_PIDController.setError(feltyrion.dzat_y - feltyrion.get_ip_targetted_y())

	
func updateHUD(dist):
	var dyams = dist * 0.00005 # todo figure out const
	Globals.update_hud_dyams_text("%1.2f DYAMS" % dyams)
