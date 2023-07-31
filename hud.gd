extends Node2D

func _ready():
	Globals.on_parsis_changed.connect(_on_parsis_changed)
	var ap_target = Globals.feltyrion.get_ap_target()
	_on_parsis_changed(ap_target.x, ap_target.y, ap_target.z)

func _on_parsis_changed(x, y, z):
	$ParsisLabel.text = "Parsis: x=%s y=%s z=%s" % [x, -y, z]
