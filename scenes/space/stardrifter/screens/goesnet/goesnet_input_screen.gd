extends Panel
@export var goesnetOutputScreen: Panel

var command_accumulator = ""
var noctis_data_dir

func _ready():
	noctis_data_dir = Globals.feltyrion.get_cwd() + "/data"
	print("Noctis data dir used by GOESNET modules is " + noctis_data_dir)
	if !OS.has_environment("NOCTIS_DATA_DIR"):
		OS.set_environment("NOCTIS_DATA_DIR", noctis_data_dir)


func _input(event):
	if Globals.ui_mode == Globals.UI_MODE.NONE:
		if event is InputEventKey and event.is_pressed():
			if event.keycode == KEY_BACKSPACE:
				command_accumulator = command_accumulator.substr(0, command_accumulator.length() - 1)
			elif event.keycode == KEY_SPACE:
				command_accumulator = command_accumulator + " "
			elif event.keycode == KEY_APOSTROPHE:
				command_accumulator = command_accumulator + "'"
			elif event.keycode == KEY_PERIOD:
				command_accumulator = command_accumulator + "."
			elif event.keycode == KEY_COMMA:
				command_accumulator = command_accumulator + ","
			elif event.keycode == KEY_PARENLEFT or event.get_keycode_with_modifiers() == KEY_9 | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "("
			elif event.keycode == KEY_PARENRIGHT or event.get_keycode_with_modifiers() == KEY_0 | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + ")"
			elif event.keycode == KEY_ASTERISK or event.get_keycode_with_modifiers() == KEY_8 | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "*"
			elif event.keycode == KEY_COLON or event.get_keycode_with_modifiers() == KEY_SEMICOLON | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + ":"
			elif event.keycode == KEY_SEMICOLON:
				command_accumulator = command_accumulator + ";"
			elif event.keycode == KEY_PERCENT or event.get_keycode_with_modifiers() == KEY_5 | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "%"
			elif event.keycode == KEY_AT or event.get_keycode_with_modifiers() == KEY_2 | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "@"
			elif event.keycode == KEY_EXCLAM or event.get_keycode_with_modifiers() == KEY_1 | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "!"
			elif event.keycode == KEY_UNDERSCORE or event.get_keycode_with_modifiers() == KEY_MINUS | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "_"
			elif event.keycode == KEY_PLUS or event.get_keycode_with_modifiers() == KEY_EQUAL | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "+"
			elif event.keycode == KEY_EQUAL:
				command_accumulator = command_accumulator + "="
			elif event.keycode == KEY_MINUS:
				command_accumulator = command_accumulator + "-"
			elif event.keycode == KEY_QUESTION or event.get_keycode_with_modifiers() == KEY_SLASH | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "?"
			elif event.keycode == KEY_SLASH:
				command_accumulator = command_accumulator + "/"
			elif event.keycode == KEY_NUMBERSIGN or event.get_keycode_with_modifiers() == KEY_3 | KEY_MASK_SHIFT:
				command_accumulator = command_accumulator + "#"
			elif event.keycode == KEY_DOLLAR or event.get_keycode_with_modifiers() == KEY_4 | KEY_MASK_SHIFT:
				pass # not supported
			elif event.keycode == KEY_AMPERSAND or event.get_keycode_with_modifiers() == KEY_7 | KEY_MASK_SHIFT:
				pass # not supported
			elif event.get_keycode_with_modifiers() == KEY_6 | KEY_MASK_SHIFT:
				pass # not supported
			elif (event.keycode >= KEY_A and event.keycode <= KEY_Z) \
				or (event.keycode >= KEY_0 and event.keycode <= KEY_9):
				command_accumulator = command_accumulator + OS.get_keycode_string(event.get_keycode_with_modifiers()).capitalize()
			elif event.keycode == KEY_ENTER:
				var output = []
				var split = command_accumulator.split(" ")
				if split[0] == "ST" or split[0] == "CAT" or split[0] == "WHERE" or split[0] == "PAR" or split[0] == "DL":
					# save the situation files before running the command
					Globals.feltyrion.freeze()
					# run the module!
					var exit_code = OS.execute("modules/" + split[0].to_lower() + ".com", split.slice(1), output, true)
				goesnetOutputScreen.updateText(" ".join(output))
				# process the comm.bin file if it exists
				Globals.feltyrion.processCommBinFile()
				Globals.set_ap_target(Globals.feltyrion.ap_target_x, Globals.feltyrion.ap_target_y, Globals.feltyrion.ap_target_z)
				Globals.local_target_index = Globals.feltyrion.ip_targetted
				Globals.local_target_orbit_index = Globals.feltyrion.ip_targetted # this is not exactly correct... meh.  - note: make sure to set this AFTER setting local_target_index!
				Globals.fine_approach_active = true if Globals.feltyrion.ip_reaching == 1 else false
				Globals.vimana.active = true if Globals.feltyrion.stspeed == 1 else false

			%InputLabel.text = command_accumulator
			
