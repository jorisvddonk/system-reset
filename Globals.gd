extends Node
@onready var feltyrion = Feltyrion.new()
signal on_parsis_changed(x, y, z)
signal on_camera_rotation(rotation)
@export var current_parsis: Vector3 = Vector3(0,0,0) # todo set to actual current

func _ready():
	current_parsis = feltyrion.get_ap_target() # you start at the current target

func set_parsis(vec3):
	feltyrion.set_ap_target(vec3)
	on_parsis_changed.emit(vec3.x, vec3.y, vec3.z)
