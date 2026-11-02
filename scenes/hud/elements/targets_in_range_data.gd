extends VBoxContainer

## Shows the 'targets in range' list (onboard devices -> galactic cartography ->
## show targets in range), like Noctis IV: the named stars within sensor range,
## closest first.

const MAX_TARGETS = 8
const TARGET_RANGE = 450000.0 # 9 sectors, as in Noctis IV's isthere()
const DYAMS_TO_LIGHTYEARS = 0.00005

var targets: Array = []

func _ready():
	visibility_changed.connect(_visibility_changed)
	Globals.tick.connect(_tick)
	Globals.game_loaded.connect(_collect_targets)

func _visibility_changed():
	if visible:
		_collect_targets()
	refresh()

func _tick():
	if visible:
		refresh()

func _collect_targets():
	var found = []
	var on_found = func(x, y, z, _id_code): found.append(Vector3(x, y, z))
	Globals.feltyrion.found_star.connect(on_found)
	Globals.feltyrion.lock()
	Globals.feltyrion.scan_stars()
	Globals.feltyrion.unlock()
	Globals.feltyrion.found_star.disconnect(on_found)

	var origin = Vector3(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z)
	targets = []
	for position in found:
		var distance = position.distance_to(origin)
		if distance > TARGET_RANGE:
			continue
		var target_name = Globals.feltyrion.get_star_name(position.x, position.y, position.z)
		if target_name.begins_with("UNKNOWN STAR"):
			continue # only labeled stars are listed, like in Noctis IV
		targets.append({"name": target_name, "distance": distance, "position": position})
	targets.sort_custom(func(a, b): return a.distance < b.distance)
	refresh()

func refresh():
	%HeaderLabel.text = "TARGETS IN RANGE"
	if targets.is_empty():
		%ContentLabel.text = "no targets in range"
		return
	var lines = []
	for target in targets.slice(0, MAX_TARGETS):
		lines.append("%s %1.2f L.Y." % [target.name.strip_edges(), target.distance * DYAMS_TO_LIGHTYEARS])
	%ContentLabel.text = "\n".join(lines)
