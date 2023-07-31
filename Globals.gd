extends Node
@onready var feltyrion = Feltyrion.new()
signal on_parsis_changed(x, y, z)

func set_parsis(vec3):
	feltyrion.set_ap_target(vec3)
	on_parsis_changed.emit(vec3.x, vec3.y, vec3.z)
