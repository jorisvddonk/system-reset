extends Node3D
@export var parsis: Vector3
@export var star_name: String
@export var id_code: float
const orig_color = Color.GHOST_WHITE
const highlight_color = Color.MOCCASIN
const remote_tgt_highlight_color = Color.ROYAL_BLUE
var clicking = false
var mouseover = false
signal clicked

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label3D.text = star_name
	__mouse_exited()
	$Area3D.mouse_entered.connect(__mouse_entered)
	$Area3D.mouse_exited.connect(__mouse_exited)
	Globals.on_ap_target_changed.connect(_on_ap_target_changed)
	Globals.mouse_click_begin.connect(click_begin)
	Globals.mouse_clicked.connect(clicked_end)
	Globals.ui_mode_changed.connect(func (ui_mode): __mouse_exited() if ui_mode == Globals.UI_MODE.NONE else null)
	
func click_begin():
	if mouseover:
		clicking = true

func clicked_end():
	if clicking:
		clicked.emit()
		if Globals.ui_mode == Globals.UI_MODE.SET_REMOTE_TARGET:
			Globals.set_ap_target(parsis)
			Globals.ui_mode = Globals.UI_MODE.NONE
		clicking = false
	

func __mouse_entered():
	mouseover = true
	$Label3D.modulate = highlight_color
	$Label3D.fixed_size = true
	$Label3D.pixel_size = 0.003
	if Globals.ui_mode == Globals.UI_MODE.SET_REMOTE_TARGET:
		$Label3D.modulate = remote_tgt_highlight_color
		$SelectionSprite.show()

func __mouse_exited():
	mouseover = false
	clicking = false
	$Label3D.modulate = orig_color
	$Label3D.fixed_size = false
	$Label3D.pixel_size = 0.0709
	$SelectionSprite.hide()

func _on_ap_target_changed(parsis, id_code):
	$SelectionSprite.hide()
	if self.id_code == id_code:
		$CurrentAPTargetSelectionSprite.show()
	else:
		$CurrentAPTargetSelectionSprite.hide()
