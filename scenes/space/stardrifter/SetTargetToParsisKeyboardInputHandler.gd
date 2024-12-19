extends Node
## Handles keyboard input when Globals.ui_mode == Globals.UI_MODE.SET_TARGET_TO_PARSIS, 
## specifically for typing in parsis coordinates

var inputBuffer = ""
var parsisX = 0
var parsisY = 0 # in SOURCE DATA PARSIS COORDINATES, so negative when users type in positive and vice-versa
var parsisZ = 0

enum INPUT_COMPONENT {NONE, X, Y, Z}
var input_component: INPUT_COMPONENT = INPUT_COMPONENT.NONE

func _ready():
	Globals.ui_mode_changed.connect(_on_ui_mode_changed)

func _on_ui_mode_changed(ui_mode):
	if ui_mode == Globals.UI_MODE.SET_TARGET_TO_PARSIS:
		inputBuffer = ""
		input_component = INPUT_COMPONENT.X
	else:
		input_component = INPUT_COMPONENT.NONE

func process_input(event: InputEvent):
	if event.is_action_pressed("number_1"):
		addInputCharacter("1")
	elif event.is_action_pressed("number_2"):
		addInputCharacter("2")
	elif event.is_action_pressed("number_3"):
		addInputCharacter("3")
	elif event.is_action_pressed("number_4"):
		addInputCharacter("4")
	elif event.is_action_pressed("number_5"):
		addInputCharacter("5")
	elif event.is_action_pressed("number_6"):
		addInputCharacter("6")
	elif event.is_action_pressed("number_7"):
		addInputCharacter("7")
	elif event.is_action_pressed("number_8"):
		addInputCharacter("8")
	elif event.is_action_pressed("number_9"):
		addInputCharacter("9")
	elif event.is_action_pressed("number_0"):
		if inputBuffer.length() > 0: # can NOT start with zero
			addInputCharacter("0")
	elif event.is_action_pressed("number_minus"):
		if inputBuffer.length() == 0: # can only start with minus
			addInputCharacter("-")
	elif event.is_action_pressed("number_backspace"):
		inputBuffer = inputBuffer.substr(0, inputBuffer.length() - 1)
		Globals.update_fcs_status_text(inputBuffer)
	elif event.is_action_pressed("number_enter"):
		if inputBuffer.length() > 0:
			var result = trySetParsisComponent()
			if result:
				if input_component == INPUT_COMPONENT.X:
					input_component = INPUT_COMPONENT.Y
					_clearAndRedrawInputBuffer()
				elif input_component == INPUT_COMPONENT.Y:
					input_component = INPUT_COMPONENT.Z
					_clearAndRedrawInputBuffer()
				elif input_component == INPUT_COMPONENT.Z:
					input_component = INPUT_COMPONENT.NONE
					_clearAndRedrawInputBuffer()
					_commitTarget()
					Globals.ui_mode = Globals.UI_MODE.NONE
					Globals.update_fcs_status_text("TGT FIXED")
				else: # fallback
					Globals.ui_mode = Globals.UI_MODE.NONE
					Globals.update_fcs_status_text("ERROR")
		else:
			# cancel input completely
			Globals.ui_mode = Globals.UI_MODE.NONE
			Globals.update_fcs_status_text("CANCELLED")

func _clearAndRedrawInputBuffer():
	inputBuffer = ""
	Globals.update_fcs_status_text(inputBuffer)

func addInputCharacter(c):
	inputBuffer += c
	Globals.update_fcs_status_text(inputBuffer)

func trySetParsisComponent():
	var parsisComponent = int(inputBuffer)
	if input_component == INPUT_COMPONENT.X:
		parsisX = parsisComponent
		return true
	elif input_component == INPUT_COMPONENT.Y:
		parsisY = -1 * parsisComponent
		return true
	elif input_component == INPUT_COMPONENT.Z:
		parsisZ = parsisComponent
		return true
	return false

func _commitTarget():
	Globals.set_ap_target(parsisX, parsisY, parsisZ)  # NOTE: set_ap_target uses SOURCE DATA PARSIS COORDINATES, but we've set parsisY to be in that format previously
