extends Control

var ap_target_info

func _ready():
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	Globals.on_ap_target_changed.connect(_on_ap_target_changed)
	Globals.vimana_status_change.connect(_on_vimana_status_changed)
	_on_parsis_changed(Globals.feltyrion.ap_target_x, Globals.feltyrion.ap_target_y, Globals.feltyrion.ap_target_z)

func _on_parsis_changed(x, y, z):
	$HBoxContainer/ParsisLabel.text = "[center]Parsis: x=%s y=%s z=%s[/center]" % [int(x), int(-y), int(z)]
	
func _on_vimana_status_changed(vimana_is_active):
	if vimana_is_active:
		$HBoxContainer/NumBodies.hide()
	else:
		var nearstar_info = Globals.feltyrion.get_current_star_info()
		$HBoxContainer/NumBodies.show()
		$HBoxContainer/NumBodies.text = "[center]Number of bodies: %s[/center]" % [nearstar_info.nearstar_nob]

func _on_ap_target_changed(x, y, z, id_code):
	ap_target_info = Globals.feltyrion.get_ap_target_info()
	$HBoxContainer/APTarget.text = "[center]remote target: x=%s y=%s z=%s [/center]" % [x, -y, z]
