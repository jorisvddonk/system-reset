extends Node3D

func _ready():
	var layer_fixer = func(item): item.set_layer_mask(2); return true
	$StardrifterParent/vehicle.find_children("?*", "MeshInstance3D").all(layer_fixer)
	Globals.stardrifter = $StardrifterParent

func _process(delta):
	# Make the SD semitransparent when selecting local or remote target
	# TODO: determine if this is some kind of perf issue; rewrite to a Signal handler if so.
	if Globals.ui_mode != Globals.UI_MODE.NONE:
		$StardrifterParent/vehicle/vehicle_007.transparency = 0.5
	else:
		$StardrifterParent/vehicle/vehicle_007.transparency = 0.0
