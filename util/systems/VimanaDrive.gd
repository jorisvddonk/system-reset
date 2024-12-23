extends Resource
class_name VimanaDrive

var feltyrion: Feltyrion
			
func _init(feltyrion: Feltyrion):
	self.feltyrion = feltyrion

signal vimana_status_change(vimana_drive_active: bool)
@export var vimana_active: bool = false ## Whether vimana is active or not. Do not modify this directly (unless you're loading a game) - use `vimanaStart()` and `vimanaStop()` instead.


func vimanaStop():
	vimana_active = false
	feltyrion.stspeed = 0
	vimana_status_change.emit(vimana_active)

func vimanaStart():
	Globals.local_target_orbit_index = -1
	Globals.local_target_index = -1
	vimana_active = true
	feltyrion.stspeed = 1
	feltyrion.ap_reached = 0
	vimana_status_change.emit(vimana_active)
