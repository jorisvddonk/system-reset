extends Panel

var other_signals_to_cleanup = []

func _input(event):
	if Globals.ui_mode == Globals.UI_MODE.NONE:
		if event is InputEventKey and event.is_pressed():
			if event.keycode == KEY_UP:
				_scroll(-1)
			if event.keycode == KEY_DOWN:
				_scroll(1)
			if event.keycode == KEY_PAGEUP:
				_scroll(-_get_lines_per_page())
			if event.keycode == KEY_PAGEDOWN:
				_scroll(_get_lines_per_page())

## The number of lines that fit in the output label at once, i.e. one 'page'.
func _get_lines_per_page() -> int:
	return max(1, %OutputLabel.get_visible_line_count())

## Scrolls the output by the given amount of lines, clamped to the available text.
func _scroll(lines: int):
	var max_lines_skipped = max(0, %OutputLabel.get_line_count() - _get_lines_per_page())
	%OutputLabel.lines_skipped = clampi(%OutputLabel.lines_skipped + lines, 0, max_lines_skipped)

func updateText(text):
	%OutputLabel.text = text
	%OutputLabel.lines_skipped = 0
