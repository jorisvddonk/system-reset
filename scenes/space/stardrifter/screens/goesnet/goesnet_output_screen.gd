extends Panel

var other_signals_to_cleanup = []

func _input(event):
	if Globals.ui_mode == Globals.UI_MODE.NONE:
		if event is InputEventKey and event.is_pressed():
			if event.keycode == KEY_UP:
				%OutputLabel.lines_skipped = %OutputLabel.lines_skipped - 1
			if event.keycode == KEY_DOWN:
				%OutputLabel.lines_skipped = %OutputLabel.lines_skipped + 1

func updateText(text):
	%OutputLabel.text = text
	%OutputLabel.lines_skipped = 0
