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

func _ready():
	flight_control_drive.pressed.connect(menu_fcd)
	onboard_devices.pressed.connect(menu_od)
	preferences.pressed.connect(menu_prefs)
	disable_display.pressed.connect(menu_dd)

func menu_fcd():
	clear_connections()
	item1.text = "Set remote target"
	item2.text = "%s vimana flight" % ["Start" if true else "Stop"] # TODO: change depending on status
	item3.text = "Set local target"
	item4.text = "Deploy surface capsule"
	#--
	clear_lines()
	item1.pressed.connect(set_remote_target)
	
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
	
func menu_od_ef():
	clear_connections()
	item1.text = "Reset onboard system"
	item2.text = "Send help request"
	item3.text = "Scope for lithium"
	item4.text = "Clear status"
	#--
	clear_lines()
	
func menu_od_nav():
	clear_connections()
	item1.text = "Starfield amplificator"
	item2.text = "Local planets finder"
	item3.text = "Near chase" # TODO: change depending on status
	item4.text = "Force radiations limit"
	#--
	line1.text = "Starfield amplification enabled/disabled. High radiation fields are ignored/avoided."  # TODO: change depending on status
	line2.text = "Tracking status: disconnected."  # TODO: change depending on status
	line3.text = "Planet finder report: system has 5 planets, and 17 minor bodies. 22 labeled out of 22."  # TODO: change depending on status
	
func menu_od_misc():
	clear_connections()
	item1.text = "Internal light %s" % ["on" if true else "off"] # TODO: change depending on status
	item2.text = "Remote target data"
	item3.text = "Local target data"
	item4.text = "Environment data"
	#--
	clear_lines()
	
func menu_od_gc():
	clear_connections()
	item1.text = "Remove star label" # TODO: change depending on status?
	item2.text = "Label planet as..."
	item3.text = "Show targets in range"
	item4.text = "Set target to parsis"
	#--
	line1.text = "Epoc 6012 triads 1234,567,890" # TODO: change depending on status
	line2.text = "Parsis universal coordinates: %s:%s:%s" % [Globals.current_parsis.x, -Globals.current_parsis.y, Globals.current_parsis.z]
	line3.text = "Heading pitch: %s:%s" % [-42, -42] # TODO: change depending on status
	
func menu_prefs():
	clear_connections()
	item1.text = "Auto screen sleep %s" % ["on" if true else "off"] # TODO: change depending on status
	item2.text = "%s pitch controls" % ["Normal" if true else "Reverse"] # TODO: change depending on status
	item3.text = "Menus always onscreen" if true else "Auto-hidden menus" # TODO: change depending on status
	item4.text = "Depolarize" if true else "Polarize" # TODO: change depending on status
	#--
	clear_lines()
	
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


func set_remote_target():
	print("TODO")
