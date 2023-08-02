extends Control
const orig_color = Color.GHOST_WHITE
const highlight_color = Color.MOCCASIN
const DEBOUNCE = 100
var last_click: int = 0
signal pressed()
@export var rootNode: Panel
var mouse_over

func _ready():
	self.mouse_entered.connect(_mouse_entered)
	self.mouse_exited.connect(_mouse_exited)
	Globals.mouse_clicked.connect(on_mouse_clicked)
	_mouse_exited()

func _mouse_entered():
	if Globals.ui_mode == Globals.UI_MODE.NONE:
		mouse_over = true
		self.modulate = highlight_color
	
func _mouse_exited():
	mouse_over = false
	self.modulate = orig_color
	
func on_mouse_clicked():
	pressed_check()

func pressed_check():
	if mouse_over && Globals.ui_mode == Globals.UI_MODE.NONE:
		if mouse_over && last_click < Time.get_ticks_msec() - DEBOUNCE:
			last_click = Time.get_ticks_msec()
			pressed.emit()
