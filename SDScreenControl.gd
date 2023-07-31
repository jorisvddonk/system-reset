extends Control
const orig_color = Color.GHOST_WHITE
const highlight_color = Color.MOCCASIN
const DEBOUNCE = 100
var last_click: int = 0
signal pressed()
@export var rootNode: Panel

# Called when the node ente= e scene tree for the first time.
func _ready():
	self.mouse_entered.connect(_mouse_entered)
	self.mouse_exited.connect(_mouse_exited)
	#self.gui_input.connect(_gui_input) # disabled for now; see below
	_mouse_exited()

func _mouse_entered():
	self.modulate = highlight_color
	rootNode.active_control = self
	
func _mouse_exited():
	self.modulate = orig_color
	if rootNode.active_control == self:
		rootNode.active_control = null
	

func pressed_check():
	if last_click < Time.get_ticks_msec() - DEBOUNCE:
		last_click = Time.get_ticks_msec()
		pressed.emit()

# for some reason this does not work at all trough a viewport, hence why the rootNode.active_control exists...
# disabled for now!
#func _gui_input(event):
#	if event is InputEventMouseButton:
#		print("Clicked on %s" % self.text, event)
#		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
#			pressed_check()

