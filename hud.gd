extends Control

var parsis: Vector3
var apTarget: Vector3
var ap_target_info
var nearstar_info

func _ready():
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	Globals.on_ap_target_changed.connect(_on_ap_target_changed)
	_on_parsis_changed(Globals.feltyrion.get_ap_target())

func _on_parsis_changed(vec):
	parsis = vec
	nearstar_info = Globals.feltyrion.get_current_star_info()
	$HBoxContainer/ParsisLabel.text = "[center]Parsis: x=%s y=%s z=%s[/center]" % [int(parsis.x), int(-parsis.y), int(parsis.z)]
	$HBoxContainer/NumBodies.text = "[center]Number of bodies: %s[/center]" % [nearstar_info.nearstar_nob]
	

func _on_ap_target_changed(vec, id_code):
	apTarget = vec
	ap_target_info = Globals.feltyrion.get_ap_target_info()
	$HBoxContainer/APTarget.text = "[center]remote target: x=%s y=%s z=%s [/center]" % [apTarget.x, -apTarget.y, apTarget.z]
