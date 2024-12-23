extends Control

var SurfaceScene = preload("res://scenes/surface/surface_exploration.tscn")
var surfaceScene
var hud_mode = true

func _ready():
	get_viewport().connect("size_changed", _on_resize)
	_on_resize()
	set_process_unhandled_input(true)
	Globals.ui_mode_changed.connect(ui_mode_changed)
	Globals.vimana.vimana_status_change.connect(vimana_status_change)
	Globals.initiate_landing_sequence.connect(initiate_landing_sequence)
	Globals.initiate_return_sequence.connect(initiate_return_sequence)
	
func vimana_status_change(status):
	pass

func _on_resize():
	printt("Root viewport size changed", get_viewport().size)
	var size_x = get_viewport().size.x
	var size_y = get_viewport().size.y
	for viewport in get_tree().get_nodes_in_group("subviewports"):
		viewport.size.x = size_x
		viewport.size.y = size_y
		viewport.notification(NOTIFICATION_VP_MOUSE_ENTER) # workaround for https://github.com/godotengine/godot/issues/89757
	$Background.size.x = size_x
	$Background.size.y = size_y

func _unhandled_input(event):
	var evt1 = event.duplicate()
	$SubViewportContainer_SpaceRemote/SubViewport.push_input(evt1, false) # is this still needed?

func ui_mode_changed(ui_mode):
	if ui_mode == Globals.UI_MODE.SET_REMOTE_TARGET:
		$SubViewportContainer_SpaceLocal.z_index = 1
		$SubViewportContainer_SpaceNear.z_index = 2
		$SubViewportContainer_SpaceRemote.z_index = 3
	elif ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET:
		$SubViewportContainer_SpaceRemote.z_index = 1
		$SubViewportContainer_SpaceNear.z_index = 2
		$SubViewportContainer_SpaceLocal.z_index = 3
	elif ui_mode == Globals.UI_MODE.NONE:
		$SubViewportContainer_SpaceRemote.z_index = 0
		$SubViewportContainer_SpaceLocal.z_index = 1
		$SubViewportContainer_SpaceNear.z_index = 2
	elif ui_mode == Globals.UI_MODE.SET_TARGET_TO_PARSIS: # same as NONE
		$SubViewportContainer_SpaceRemote.z_index = 0
		$SubViewportContainer_SpaceLocal.z_index = 1
		$SubViewportContainer_SpaceNear.z_index = 2


func initiate_landing_sequence():
	%SpaceNear.process_mode = Node.PROCESS_MODE_DISABLED
	Globals.gameplay_mode = Globals.GAMEPLAY_MODE.SURFACE
	surfaceScene = SurfaceScene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	$SubViewportContainer_SpaceNear/SubViewport.add_child(surfaceScene)

func initiate_return_sequence():
	%SpaceNear.process_mode = Node.PROCESS_MODE_INHERIT
	$SubViewportContainer_SpaceNear/SubViewport.remove_child(surfaceScene)
	surfaceScene.queue_free()
	Globals.gameplay_mode =  Globals.GAMEPLAY_MODE.SPACE

func _input(event):
	if event.is_action_pressed("toggle_crt"):
		if $CRTCanvasLayer.visible:
			$CRTCanvasLayer.hide()
		else:
			$CRTCanvasLayer.show()
		
	if event.is_action_pressed("toggle_hud"):
		hud_mode = !hud_mode
		if hud_mode:
			%HUD.show_detail()
		else:
			%HUD.hide_detail()

	if event.is_action_pressed("toggle_help"):
		if %HUD/Help.visible:
			%HUD/Help.hide()
			$SubViewportContainer_HUD.mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			%HUD/Help.show()
			$SubViewportContainer_HUD.mouse_filter = MouseFilter.MOUSE_FILTER_PASS
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("toggle_y_axis_inversion"):
		Globals.camera_inverted = !Globals.camera_inverted
