extends Panel
@export var line1: Label
@export var line2: Label
@export var line3: Label
@export var item1: Label
@export var item2: Label
@export var item3: Label
@export var item4: Label
@export var flight_control_drive: Label
@export var onboard_devices: Label
@export var preferences: Label
@export var disable_display: Label

const star_descriptions = ["medium size, yellow star, suitable for planets having indigenous lifeforms.",
	"very large, blue giant star, high energy radiations around.",
	"white dwarf star, possible harmful radiations.",
	"very large, ancient, red giant star.",
	"large and glowing, orange giant star, high nuclear mass.",
	"small, weak, cold, brown dwarf substellar object.",
	"large, very weak, very cold, gray giant dead star.",
	"very small, blue dwarf star, strong gravity well around.",
	"possible MULTIPLE system - planets spread over wide ranges.",
	"medium size, surrounded by gas clouds, young star.",
	"very large and ancient runaway star, unsuitable for planets.",
	"tiny pulsar object, unsafe, high radiation, strong gravity."];
	
const planet_description = ["medium size, internally hot, unstable surface, no atmosphere.",
	"small, solid, dusty, craterized, no atmosphere.",
	"medium size, solid, thick atmosphere, fully covered by clouds.",
	"medium size, felisian, breathable atmosphere, suitable for life.",
	"medium size, rocky, creased, no atmosphere.",
	"small, solid, thin atmosphere.",
	"large, not consistent, covered with dense clouds.",
	"small, solid, icy surface, no atmosphere.",
	"medium size, surface is mainly native quartz, oxygen atmosphere.",
	"very large, substellar object, not consistent.",
	"companion star - not a planet"];

const ordinal = ["zeroth",     "first",     "second",    "third",       "fourth",     "fifth",      "sixth",
   "seventh",    "eight",     "nineth",    "tenth",       "eleventh",   "twelveth",   "thiteenth",
   "fourteenth", "fifteenth", "sixteenth", "seventeenth", "eighteenth", "nineteenth", "twentyth"]

var other_signals_to_cleanup = []

func _ready():
	_disable_display()
	flight_control_drive.pressed.connect(menu_fcd)
	onboard_devices.pressed.connect(menu_od)
	preferences.pressed.connect(menu_prefs)
	disable_display.pressed.connect(menu_dd)
	

func _input(event):
	if Globals.ui_mode == Globals.UI_MODE.NONE:
		if event.is_action_pressed("osd_category_1"):
			flight_control_drive.pressed.emit()
		if event.is_action_pressed("osd_category_2"):
			onboard_devices.pressed.emit()
		if event.is_action_pressed("osd_category_3"):
			preferences.pressed.emit()
		if event.is_action_pressed("osd_category_4"):
			disable_display.pressed.emit()
		if event.is_action_pressed("osd_item_1"):
			item1.pressed.emit()
		if event.is_action_pressed("osd_item_2"):
			item2.pressed.emit()
		if event.is_action_pressed("osd_item_3"):
			item3.pressed.emit()
		if event.is_action_pressed("osd_item_4"):
			item4.pressed.emit()

func menu_fcd():
	clear_connections()
	item1.text = "Set remote target"
	item2.text = "%s vimana flight" % ["Start" if !Globals.vimana.vimana_active else "Stop"]
	item3.text = "Start fine approach" if can_start_fine_approach() else ("Stop fine approach" if can_stop_fine_approach() else ("Set local target" if can_set_local_target() else ""))
	item4.text = "Deploy surface capsule" if can_maybe_deploy_surface_capsule() else ("Cancel local target" if can_cancel_local_target() else "")
	#--
	clear_lines()
	var curline = line1
	var apinfo = Globals.feltyrion.get_ap_target_info()
	if Globals.feltyrion.ip_targetted != -1:
		var ipinfo = Globals.feltyrion.get_planet_info(Globals.feltyrion.ip_targetted)
		if ipinfo["nearstar_p_owner"] == -1:
			curline.text = "Local target: %s planet. %s" % [ordinal[ipinfo["n"] + 1], planet_description[ipinfo["nearstar_p_type"]]]
		else:
			curline.text = "Local target: moon #%s of %s planet. %s" % [ipinfo["nearstar_p_moonid"] + 1, ordinal[ipinfo["nearstar_p_owner"] + 1], planet_description[ipinfo["nearstar_p_type"]]]
		curline = line2
	if apinfo.ap_targetted:
		if apinfo.ap_targetted == 1:
			curline.text = "Remote target: class %s star; %s" % [apinfo.ap_target_class, star_descriptions[apinfo.ap_target_class]]
		else:
			curline.text = "Direct parsis target: non-star type."
	else:
		curline.text = "no remote target selected"
	var kdyams = max(0, Globals.feltyrion.pwr - 15000)
	line2.text = ("current range: elapsed %d kilodyams" % kdyams) + (", remaining lithium: %d grams." % Globals.feltyrion.charge if Globals.feltyrion.charge >= 0 else ". OMEGA DRIVE installed")
	#-
	item1.pressed.connect(set_remote_target) # see FarStar scene for the part that handles actually setting the remote target
	item2.pressed.connect(toggle_vimana_active)
	item3.pressed.connect(local_target_button) # see Planet scene for the part that handles actually setting the local target
	item4.pressed.connect(interact_local_target_button)
	add_connection(Globals.on_ap_target_changed, func(_x, _y, _z, _b): menu_fcd()) # redraw screen if current remote target changed
	add_connection(Globals._on_local_target_changed, func(_a): menu_fcd()) # redraw screen if current local target changed
	add_connection(Globals.vimana.vimana_status_change, func(_a): menu_fcd()) # redraw screen if vimana status changed
	add_connection(Globals.fine_approach_status_change, func(_a): menu_fcd()) # redraw screen if fine approach status changed
	add_connection(Globals.tick, func(): menu_fcd()) # redraw screen on clock tick (every second) to update kilodyams if needed
	setup_extra_default_connections()
	
func menu_od():
	clear_connections()
	item1.text = "Navigation instruments"
	item2.text = "Miscellaneous"
	item3.text = "Galactic cartography"
	item4.text = "Emergency functions"
	#--
	clear_lines()
	item1.pressed.connect(menu_od_nav)
	item2.pressed.connect(menu_od_misc)
	item3.pressed.connect(menu_od_gc)
	item4.pressed.connect(menu_od_ef)
	setup_extra_default_connections()
	
func menu_od_ef():
	clear_connections()
	item1.text = "Reset onboard system"
	item2.text = "Send help request"
	item3.text = "Scope for lithium"
	item4.text = "Clear status"
	#--
	clear_lines()
	item1.pressed.connect(not_implemented_yet)
	item2.pressed.connect(not_implemented_yet)
	item3.pressed.connect(not_implemented_yet)
	item4.pressed.connect(not_implemented_yet)
	setup_extra_default_connections()
	
const CHASE_MODES = ["tracking disabled", "fixed-point chase", "far chase", "syncrone orbit", "high-speed orbit", "near chase", "high speed viewpoint chase"]
func menu_od_nav():
	clear_connections()
	item1.text = "Starfield amplificator"
	item2.text = "Local planets finder"
	item3.text = CHASE_MODES[Globals.chase_mode]
	item4.text = "Force radiations limit"
	#--
	clear_lines()
	line1.text = "Starfield amplification enabled/disabled. High radiation fields are ignored/avoided."  # TODO: change depending on status
	if Globals.chase_mode == Globals.CHASE_MODE.TRACKING_DISABLED:
		line2.text = "Tracking status: inactive."
	else:
		line2.text = "Tracking status: performing %s." % CHASE_MODES[Globals.chase_mode] if Globals.feltyrion.ip_reached && Globals.feltyrion.ip_targetted != -1 else "Tracking status: disconnected."
	if Globals.feltyrion.ap_targetted == 1 and Globals.feltyrion.ap_reached == 1:
		var starInfo = Globals.feltyrion.get_current_star_info()
		if starInfo.has("nearstar_class"):
			line3.text = "Planet finder report: system has %s %s%s, and %s minor bodies. %s labeled out of %s." % [
				starInfo.nearstar_nop, 
				"proto" if starInfo.nearstar_class == 9 else "",
				"planet" if starInfo.nearstar_nop == 1 else "planets",
				starInfo.nearstar_nob - starInfo.nearstar_nop,
				starInfo.nearstar_labeled,
				starInfo.nearstar_nob
			]
	item1.pressed.connect(not_implemented_yet)
	item2.pressed.connect(not_implemented_yet) # this just toggles between having the planet finder on or off; at the moment it's always on
	item3.pressed.connect(change_tracking_mode)
	item4.pressed.connect(not_implemented_yet)
	add_connection(Globals.chase_mode_changed, func(_a): menu_od_nav()) # redraw screen if chase mode changed
	setup_extra_default_connections()
	
func menu_od_misc():
	clear_connections()
	item1.text = "Internal light %s" % ["on" if true else "off"] # TODO: change depending on status
	item2.text = "Remote target data"
	item3.text = "Local target data"
	item4.text = "Environment data"
	#--
	clear_lines()
	item1.pressed.connect(not_implemented_yet)
	item2.pressed.connect(not_implemented_yet)
	item3.pressed.connect(not_implemented_yet)
	item4.pressed.connect(not_implemented_yet)
	setup_extra_default_connections()
	
func menu_od_gc():
	clear_connections()
	item1.text = "Remove star label" # TODO: change depending on status?
	item2.text = "Label planet as..."
	item3.text = "Show targets in range"
	item4.text = "Set target to parsis" if Globals.ui_mode != Globals.UI_MODE.SET_TARGET_TO_PARSIS else "(Enter coordinates)"
	#--
	clear_lines()
	line1.text = "Epoc 6012 triads 1234,567,890" # TODO: change depending on status
	line2.text = "Parsis universal coordinates: %s:%s:%s" % [Globals.feltyrion.dzat_x, -Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z]
	line3.text = "Heading pitch: %s:%s" % [-42, -42] # TODO: change depending on status
	item1.pressed.connect(not_implemented_yet)
	item2.pressed.connect(not_implemented_yet)
	item3.pressed.connect(not_implemented_yet)
	item4.pressed.connect(set_target_to_parsis)
	add_connection(Globals.ui_mode_changed, func(_a): menu_od_gc()) # redraw screen if ui mode mode changed.. hmm, this doesn't work?
	setup_extra_default_connections()
	
func menu_prefs():
	clear_connections()
	item1.text = "Auto screen sleep %s" % ["on" if true else "off"] # TODO: change depending on status
	item2.text = "%s pitch controls" % ["Normal" if true else "Reverse"] # TODO: change depending on status
	item3.text = "Menus always onscreen" if true else "Auto-hidden menus" # TODO: change depending on status
	item4.text = "Depolarize" if true else "Polarize" # TODO: change depending on status
	#--
	clear_lines()
	item1.pressed.connect(not_implemented_yet)
	item2.pressed.connect(not_implemented_yet)
	item3.pressed.connect(not_implemented_yet)
	item4.pressed.connect(not_implemented_yet)
	setup_extra_default_connections()
	
func menu_dd():
	clear_connections()
	_disable_display()
	
	
func _disable_display():
	item1.text = ""
	item2.text = ""
	item3.text = ""
	item4.text = ""
	#--
	clear_lines()

func clear_lines():
	line1.text = ""
	line2.text = ""
	line3.text = ""
	
func clear_connections_for_node(node):
	var conns = node.get_signal_connection_list("pressed");
	for cur_conn in conns:
		cur_conn.signal.disconnect(cur_conn.callable)
	
func clear_connections():
	clear_connections_for_node(item1)
	clear_connections_for_node(item2)
	clear_connections_for_node(item3)
	clear_connections_for_node(item4)
	for item in other_signals_to_cleanup:
		item.signal.disconnect(item.callable)
	other_signals_to_cleanup.clear()

func add_connection(signal_, callable):
	signal_.connect(callable)
	other_signals_to_cleanup.append({"signal": signal_, "callable": callable})

func set_remote_target():
	Globals.ui_mode = Globals.UI_MODE.SET_REMOTE_TARGET
	
func local_target_button():
	if can_start_fine_approach():
		Globals.fine_approach_active = true
	elif can_stop_fine_approach():
		Globals.fine_approach_active = false
	elif can_set_local_target():
		Globals.ui_mode = Globals.UI_MODE.SET_LOCAL_TARGET

func interact_local_target_button():
	if can_maybe_deploy_surface_capsule():
		if can_deploy_surface_capsule():
			start_deploy_surface_capsule()
		else:
			# show 'IMPOSSIBLE' status
			# TODO; requires being able to set fcs_status from Godot side
			print("IMPOSSIBLE")
			pass
	elif can_cancel_local_target():
		Globals.local_target_index = -1

func toggle_vimana_active():
	if Globals.vimana.vimana_active:
		Globals.vimana.vimanaStop()
	else:
		Globals.vimana.vimanaStart()

func can_set_local_target():
	return Globals.local_target_index == -1 || Globals.local_target_orbit_index != -1 # we don't have a local target yet, or we're orbiting one

func can_start_fine_approach():
	return !Globals.fine_approach_active && Globals.local_target_index != -1 && Globals.local_target_orbit_index != Globals.local_target_index # we have a local target that's not the one we're currently orbiting, and we're not doing a fine approach either

func can_stop_fine_approach():
	return Globals.fine_approach_active
	
func can_maybe_deploy_surface_capsule():
	# checks if the conditions are correct for deploying a surface capsule, but does NOT check if you can actually land on the planet/moon (based on its type)
	# note: logic possibly different from NIV
	return Globals.local_target_orbit_index != -1

func can_deploy_surface_capsule():
	# checks if you can ACTUALLY deploy it
	# note: logic possibly different from NIV
	if Globals.local_target_orbit_index == -1:
		return false
	var ipinfo = Globals.feltyrion.get_planet_info(Globals.local_target_orbit_index)
	return ipinfo["nearstar_p_type"] != 0 && ipinfo["nearstar_p_type"] != 6 && ipinfo["nearstar_p_type"] < 9

func can_cancel_local_target():
	return Globals.local_target_index != -1

func change_tracking_mode():
	Globals.chase_mode = 0 if Globals.chase_mode >= 6 else Globals.chase_mode + 1
	
func start_deploy_surface_capsule():
	Globals.deploy_surface_capsule_status_change.emit(true)

func set_target_to_parsis():
	if Globals.ui_mode != Globals.UI_MODE.SET_TARGET_TO_PARSIS:
		Globals.ui_mode = Globals.UI_MODE.SET_TARGET_TO_PARSIS
		Globals.update_fcs_status_text("TGT MANUAL")
	elif Globals.ui_mode == Globals.UI_MODE.SET_TARGET_TO_PARSIS:
		Globals.ui_mode = Globals.UI_MODE.NONE
		Globals.update_fcs_status_text("TGT REJECT")

# Set up some additional connections to ensure that we send the on_hud_pressed signal (used for the HUD)
func setup_extra_default_connections():
	item1.pressed.connect(on_hud_pressed)
	item2.pressed.connect(on_hud_pressed)
	item3.pressed.connect(on_hud_pressed)
	item4.pressed.connect(on_hud_pressed)
	flight_control_drive.pressed.connect(on_hud_pressed)
	onboard_devices.pressed.connect(on_hud_pressed)
	preferences.pressed.connect(on_hud_pressed)
	disable_display.pressed.connect(on_hud_pressed)
	# simulate immediately
	on_hud_pressed()

func on_hud_pressed():
	Globals.osd_updated.emit(item1.text, item2.text, item3.text, item4.text)

func not_implemented_yet():
	Globals.update_fcs_status_text("NOT IMPLEMENTED YET", 1)
