extends Control

func _ready():
	get_viewport().connect("size_changed", _on_resize)
	set_process_unhandled_input(true)
	Globals.ui_mode_changed.connect(ui_mode_changed)
	Globals.vimana_status_change.connect(vimana_status_change)
	
func vimana_status_change(status):
	if status == false:
		Globals.feltyrion.freeze()

func _on_resize():
	printt("Root viewport size changed", get_viewport().size)
	$SubViewportContainer_SpaceRemote/SubViewport.size.x = get_viewport().size.x
	$SubViewportContainer_SpaceRemote/SubViewport.size.y = get_viewport().size.y
	$SubViewportContainer_SpaceLocal/SubViewport.size.x = get_viewport().size.x
	$SubViewportContainer_SpaceLocal/SubViewport.size.y = get_viewport().size.y
	$SubViewportContainer_SpaceNear/SubViewport.size.x = get_viewport().size.x
	$SubViewportContainer_SpaceNear/SubViewport.size.y = get_viewport().size.y
	$Background.size.x = get_viewport().size.x
	$Background.size.y = get_viewport().size.y

func _unhandled_input(event):
	var evt1 = event.duplicate()
	var evt2 = event.duplicate()
	$SubViewportContainer_SpaceRemote/SubViewport.push_input(evt1, false)
	$SubViewportContainer_SpaceNear/SubViewport.push_input(evt2, false)

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
