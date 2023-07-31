extends Control

func _ready():
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	var ap_target = Globals.feltyrion.get_ap_target()
	_on_parsis_changed(ap_target.x, ap_target.y, ap_target.z)

func _on_parsis_changed(x, y, z):
	$HBoxContainer/ParsisLabel.text = "[center]Parsis: x=%s y=%s z=%s[/center]" % [x, -y, z]
