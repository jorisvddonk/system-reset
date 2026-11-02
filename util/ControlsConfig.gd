## Loads, saves and applies the configurable control bindings. Bindings are stored
## in a configuration file, so they survive restarts, and are applied to the
## engine's InputMap on startup.

const CONFIG_PATH = "user://controls.cfg"
const SECTION = "controls"

## The actions that can be rebound from the help screen, with a human readable label.
const ACTIONS = [
	{"action": "move_forward", "label": "Move forward"},
	{"action": "move_backward", "label": "Move backward"},
	{"action": "move_left", "label": "Move left"},
	{"action": "move_right", "label": "Move right"},
	{"action": "move_jump", "label": "Jump"},
	{"action": "rotate_left", "label": "Rotate Stardrifter left"},
	{"action": "rotate_right", "label": "Rotate Stardrifter right"},
	{"action": "cancel_mouse_capture", "label": "(Re)capture mouse"},
	{"action": "toggle_y_axis_inversion", "label": "Toggle mouse y axis inversion"},
	{"action": "toggle_hud", "label": "Toggle HUD"},
	{"action": "toggle_crt", "label": "Toggle CRT effect"},
	{"action": "toggle_help", "label": "Toggle help"},
	{"action": "load_game", "label": "Load game"},
	{"action": "save_game", "label": "Save game"},
	{"action": "toggle_debug_tools", "label": "Toggle debug tools"},
	{"action": "osd_category_1", "label": "Flight control drive"},
	{"action": "osd_category_2", "label": "Onboard devices"},
	{"action": "osd_category_3", "label": "Preferences"},
	{"action": "osd_category_4", "label": "Disable display"},
	{"action": "osd_item_1", "label": "Menu command 1"},
	{"action": "osd_item_2", "label": "Menu command 2"},
	{"action": "osd_item_3", "label": "Menu command 3"},
	{"action": "osd_item_4", "label": "Menu command 4"},
]

## Applies the stored bindings, if there are any.
static func load_config():
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	for entry in ACTIONS:
		if config.has_section_key(SECTION, entry.action):
			_bind(entry.action, int(config.get_value(SECTION, entry.action)))

## Stores the current bindings.
static func save_config():
	var config = ConfigFile.new()
	for entry in ACTIONS:
		var keycode = get_keycode(entry.action)
		if keycode != 0:
			config.set_value(SECTION, entry.action, keycode)
	config.save(CONFIG_PATH)

## Binds an action to a physical key and stores the new bindings.
static func bind(action: String, keycode: int):
	_bind(action, keycode)
	save_config()

## The physical keycode currently bound to an action, or 0 if it has none.
static func get_keycode(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode if event.physical_keycode != 0 else event.keycode
	return 0

## A human readable label for the key currently bound to an action.
static func get_key_label(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			return OS.get_keycode_string(keycode)
		if event is InputEventMouseButton:
			return "Mouse %d" % event.button_index
	return "-"

static func _bind(action: String, keycode: int):
	if keycode == 0 or not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	var event = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
