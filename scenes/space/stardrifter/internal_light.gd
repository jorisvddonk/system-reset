extends OmniLight3D

var tween
const LIGHT_ENERGY_ON = 1
const LIGHT_ENERGY_OFF = 0

func _ready():
	Globals.game_loaded.connect(func (): update_internal_light())
	Globals.feltyrion.on_ilightv_changed.connect(func (_a): update_internal_light())
	update_internal_light()

func update_internal_light():
	if Globals.feltyrion.ilightv == 1:
		_create_tween(LIGHT_ENERGY_ON)
	else:
		_create_tween(LIGHT_ENERGY_OFF)

func _create_tween(light_energy):
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "light_energy", light_energy, 1)
