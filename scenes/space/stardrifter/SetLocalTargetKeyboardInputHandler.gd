extends Node
## Handles keyboard input when Globals.ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET, 
## specifically for setting local target manually through keyboard instead of spatially

var inputBuffer = ""

func _ready():
	Globals.ui_mode_changed.connect(_on_ui_mode_changed)

func _on_ui_mode_changed(ui_mode):
	if ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET:
		inputBuffer = ""

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
	elif event.is_action_pressed("number_slash"):
		if inputBuffer.find("/") == -1: # can only add one slash, so ignore any second
			addInputCharacter("/")
	#elif event.is_action_pressed("number_minus"): # minus is not supported here...
	#	if inputBuffer.length() == 0: # can only start with minus
	#		addInputCharacter("-")
	elif event.is_action_pressed("number_backspace"):
		inputBuffer = inputBuffer.substr(0, inputBuffer.length() - 1)
		Globals.update_fcs_status_text(inputBuffer)
	elif event.is_action_pressed("number_enter"):
		if inputBuffer.length() > 0:
			var result = trySetLocalTarget()
			if result:
				Globals.ui_mode = Globals.UI_MODE.NONE
				Globals.update_fcs_status_text("TGT FIXED")
		else:
			# cancel input completely
			Globals.ui_mode = Globals.UI_MODE.NONE
			Globals.update_fcs_status_text("CANCELLED")

func addInputCharacter(c):
	inputBuffer += c
	Globals.update_fcs_status_text(inputBuffer)

func trySetLocalTarget():
	var starInfo = Globals.feltyrion.get_current_star_info()
	if starInfo == null:
		return # ?? - doesn't actually happen I don't think
	if inputBuffer.find("/") == -1: # planet search directly
		var search = int(inputBuffer)
		if search <= starInfo.nearstar_nop:
			Globals.local_target_index = search - 1 # body indexes start at 0; planets come first, then following are the moons
			return true
		else:
			if search <= starInfo.nearstar_nob:
				for i in range(starInfo.nearstar_nop - 1, starInfo.nearstar_nob):
					var objInfo = Globals.feltyrion.get_planet_info(i)
					if objInfo.n == search - 1:
						Globals.update_fcs_status_text("NOT EXTANT - BUT MOON P%0*d EXISTS (%d/%d)" % [2, search, objInfo.nearstar_p_moonid + 1, objInfo.nearstar_p_owner + 1]) # convenience feature to log the moonid
			else:
				Globals.update_fcs_status_text("NOT EXTANT")
	else: # moon search - need to iterate through all moons
		var aSearchMoon = int(inputBuffer.substr(0, inputBuffer.find('/'))) - 1 # ABSOLUTE, ZERO-INDEXED owner value
		var aSearchOwner = int(inputBuffer.substr(inputBuffer.find('/') + 1)) - 1 # ABSOLUTE, ZERO-INDEXED moonid
		if aSearchOwner != -1 and aSearchMoon != -1:
			for i in range(starInfo.nearstar_nop - 1, starInfo.nearstar_nob):
				var objInfo = Globals.feltyrion.get_planet_info(i)
				if objInfo.nearstar_p_owner == aSearchOwner and objInfo.nearstar_p_moonid == aSearchMoon:
					Globals.local_target_index = objInfo.n
					return true
			# not found
			Globals.update_fcs_status_text("NOT EXTANT")
		else:
			Globals.update_fcs_status_text("ERROR") # you tried doing "1/", "1/0" or something like that.... doesn't work
	return false
