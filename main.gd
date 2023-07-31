extends Control

func _ready():
	get_viewport().connect("size_changed", _on_resize)

func _on_resize():
	printt("Root viewport size changed", get_viewport().size)
	$SubViewportContainer_SpaceRemote/SubViewport.size.x = get_viewport().size.x
	$SubViewportContainer_SpaceRemote/SubViewport.size.y = get_viewport().size.y
	$SubViewportContainer_SpaceLocal/SubViewport.size.x = get_viewport().size.x
	$SubViewportContainer_SpaceLocal/SubViewport.size.y = get_viewport().size.y
	$SubViewportContainer_SpaceNear/SubViewport.size.x = get_viewport().size.x
	$SubViewportContainer_SpaceNear/SubViewport.size.y = get_viewport().size.y
