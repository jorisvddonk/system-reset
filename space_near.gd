extends Node3D

func _ready():
	var layer_fixer = func(item): item.set_layer_mask(2); return true
	$vehicle.find_children("?*", "MeshInstance3D").all(layer_fixer)
