extends Panel
class_name PitchArrow
@export var side_of_stardrifter: SIDE_OF_STARDRIFTER = SIDE_OF_STARDRIFTER.LEFT

enum SIDE_OF_STARDRIFTER { LEFT, RIGHT } ## signifies whether this pitch arrow is on the left side of the main display, or the right side
enum _PITCH_DIRECTION { LEFT, RIGHT }

var _synthetic

func _ready():
	Globals.feltyrion.on_revcontrols_changed.connect(_on_revcontrols_changed)
	$Label.clickBegin.connect(_click_begin)
	$Label.clickEnd.connect(_click_end)
	_reset_synthetic()
	_update_label()

func _on_revcontrols_changed(_revcontrols):
	_reset_synthetic()
	_update_label()
	
func _update_label():
	if Globals.feltyrion.revcontrols:
		$Label.text = ">-" if side_of_stardrifter == SIDE_OF_STARDRIFTER.LEFT else "<-"
	else:
		$Label.text = "<-" if side_of_stardrifter == SIDE_OF_STARDRIFTER.LEFT else "->"

func _get_actual_pitch_direction():
	if Globals.feltyrion.revcontrols:
		if side_of_stardrifter == SIDE_OF_STARDRIFTER.LEFT:
			return _PITCH_DIRECTION.RIGHT
		else:
			return _PITCH_DIRECTION.LEFT
	else:
		if side_of_stardrifter == SIDE_OF_STARDRIFTER.LEFT:
			return _PITCH_DIRECTION.LEFT
		else:
			return _PITCH_DIRECTION.RIGHT

func _reset_synthetic():
	if _synthetic != null:
		_synthetic.pressed = false
		Input.parse_input_event(_synthetic)
		_synthetic = null
	if _synthetic == null:
		_synthetic = InputEventAction.new()
		_synthetic.action = "rotate_left" if _get_actual_pitch_direction() == SIDE_OF_STARDRIFTER.LEFT else "rotate_right"

func _click_begin():
	_synthetic.pressed = true
	Input.parse_input_event(_synthetic)

func _click_end():
	_synthetic.pressed = false
	Input.parse_input_event(_synthetic)
