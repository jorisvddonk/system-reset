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
			elif (event.keycode >= KEY_A and event.keycode <= KEY_Z) or (event.keycode >= KEY_0 and event.keycode <= KEY_9):
				command_accumulator = command_accumulator + OS.get_keycode_string(event.keycode).capitalize()
			elif event.keycode == KEY_ENTER:
				var output = []
				var split = command_accumulator.split(" ")
				if split[0] == "ST" or split[0] == "CAT" or split[0] == "WHERE" or split[0] == "PAR" or split[0] == "DL":
					var exit_code = OS.execute("modules/" + split[0].to_lower() + ".com", split.slice(1), output, true)
				goesnetOutputScreen.updateText(" ".join(output))

			%InputLabel.text = command_accumulator
			
