extends Node3D
class_name Farstar
@export var parsis_x: float
@export var parsis_y: float
@export var parsis_z: float
@export var star_name: String
@export var star_class: String
@export var id_code: float
const orig_color = Color.GHOST_WHITE
const highlight_color = Color.MOCCASIN
const remote_tgt_highlight_color = Color.ROYAL_BLUE
var clicking = false
var mouseover = false
signal clicked
const _a = -1.857e-13;
const _b = 4.362e-10;
const _c = -3.697e-07;
const _d = 1.173e-04;

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label3D.text = star_name
	setSelected(false)
	Globals.mouse_click_begin.connect(click_begin)
	Globals.mouse_clicked.connect(clicked_end)
	Globals.ui_mode_changed.connect(ui_mode_changed)
	Globals.on_debug_tools_enabled_changed.connect(on_debug_tools_enabled_changed)

func setPosition(vec):
	self.position = vec
	var l = vec.length()
	$StarSprite.pixel_size = _a * pow(l, 3) + _b * pow(l, 2) + _c * l + _d;

func updateLabelVisibility():
	if Globals.debug_tools_enabled:
		$Label3D.show()
	else:
		$Label3D.hide()
	
func ui_mode_changed(ui_mode):
	updateLabelVisibility()
	if ui_mode == Globals.UI_MODE.NONE:
		setSelected(false)
	
func click_begin():
	if mouseover:
		clicking = true

func clicked_end():
	if clicking:
		clicked.emit()
		if Globals.ui_mode == Globals.UI_MODE.SET_REMOTE_TARGET:
			Globals.set_ap_target(parsis_x, parsis_y, parsis_z)
			Globals.ui_mode = Globals.UI_MODE.NONE
		clicking = false
	

func setSelected(selected: bool):
	if selected:
		mouseover = true
		$Label3D.modulate = highlight_color
		if Globals.ui_mode == Globals.UI_MODE.SET_REMOTE_TARGET:
			$Label3D.modulate = remote_tgt_highlight_color
	else:
		mouseover = false
		clicking = false
		$Label3D.modulate = orig_color
	updateLabelVisibility()

func on_debug_tools_enabled_changed(_a):
	updateLabelVisibility()
