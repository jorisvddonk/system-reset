extends Control

var ap_target_info

func _ready():
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	Globals.on_ap_target_changed.connect(_on_ap_target_changed)
	Globals._on_local_target_changed.connect(_on_local_target_changed)
	Globals.vimana_status_change.connect(_on_vimana_status_changed)
	_on_parsis_changed(Globals.feltyrion.ap_target_x, Globals.feltyrion.ap_target_y, Globals.feltyrion.ap_target_z)
	var timer = Timer.new()
	timer.timeout.connect(update_fcs_status)
	timer.wait_time = 1
	timer.one_shot = false
	add_child(timer)
	timer.start()

func _on_parsis_changed(x, y, z):
	$VBoxContainer/HBoxContainer/ParsisLabel.text = "[center]Parsis: x=%s y=%s z=%s[/center]" % [int(x), int(-y), int(z)]
	
func _on_vimana_status_changed(vimana_is_active):
	if vimana_is_active:
		$VBoxContainer/HBoxContainer/NumBodies.hide()
	else:
		var nearstar_info = Globals.feltyrion.get_current_star_info()
		$VBoxContainer/HBoxContainer/NumBodies.show()
		$VBoxContainer/HBoxContainer/NumBodies.text = "[center]Number of bodies: %s[/center]" % [nearstar_info.nearstar_nob]

func _on_ap_target_changed(x, y, z, id_code):
	ap_target_info = Globals.feltyrion.get_ap_target_info()
	$VBoxContainer/HBoxContainer/APTarget.text = "[center]remote target: x=%s y=%s z=%s [/center]" % [x, -y, z]
	$VBoxContainer_Selected/SelectedStar.text = Globals.feltyrion.get_star_name(ap_target_info.ap_target_x, ap_target_info.ap_target_y, ap_target_info.ap_target_z)
	$VBoxContainer_Selected/SelectedPlanet.text = ""

func _on_local_target_changed(planet_index):
	if planet_index != -1:
		ap_target_info = Globals.feltyrion.get_ap_target_info()
		$VBoxContainer_Selected/SelectedPlanet.text = Globals.feltyrion.get_planet_name(ap_target_info.ap_target_x, ap_target_info.ap_target_y, ap_target_info.ap_target_z, planet_index)
	else:
		$VBoxContainer_Selected/SelectedPlanet.text = ""

func update_fcs_status():
	$VBoxContainer/FCSStatus.text = "[right]%s[/right]" % Globals.feltyrion.get_fcs_status()
