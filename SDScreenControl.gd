extends Control
const orig_color = Color.GHOST_WHITE
const highlight_color = Color.MOCCASIN
const DEBOUNCE = 100
var last_click: int = 0
signal pressed()

# Called when the node ente= e scene tree for the first time.
func _ready():
	self.mouse_entered.connect(_mouse_entered)
	self.mouse_exited.connect(_mouse_exited)
	self.gui_input.connect(_gui_input)
	_mouse_exited()

func _mouse_entered():
	self.modulate = highlight_color
	
func _mouse_exited():
	self.modulate = orig_color
	
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed() && !event.is_echo():
			if last_click < Time.get_ticks_msec() - DEBOUNCE:
				last_click = Time.get_ticks_msec()
				pressed.emit()
