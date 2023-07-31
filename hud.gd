extends Control

var parsis: Vector3
var apTarget: Vector3

func _ready():
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	Globals.on_ap_target_changed.connect(_on_ap_target_changed)
	var ap_target = Globals.feltyrion.get_ap_target()
	_on_parsis_changed(ap_target.x, ap_target.y, ap_target.z)

func _on_parsis_changed(x, y, z):
	parsis = Vector3(x,y,z)
	redraw_label()
	

func _on_ap_target_changed(vec, id_code):
	apTarget = vec
	redraw_label()
	

func redraw_label():
	if apTarget.x != parsis.x || apTarget.y != parsis.y || apTarget.z != parsis.z:
		$HBoxContainer/ParsisLabel.text = "[left]Parsis: x=%s y=%s z=%s[/left]   [right]remote target: x=%s y=%s z=%s [/right]" % [parsis.x, -parsis.y, parsis.z, apTarget.x, -apTarget.y, apTarget.z]
	else:
		$HBoxContainer/ParsisLabel.text = "[left]Parsis: x=%s y=%s z=%s[/left]" % [parsis.x, -parsis.y, parsis.z]
