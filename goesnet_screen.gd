extends MeshInstance3D
@onready var mouseover: bool = false
@export var viewport: SubViewport
@export var sdscreen: Panel
@export var camera: Camera3D
@export var playercharacter: CharacterBody3D

func _ready():
	$Area3D.mouse_entered.connect(_mouse_entered)
	$Area3D.mouse_exited.connect(_mouse_exited)

func _input(event):
	if mouseover and Globals.ui_mode == Globals.UI_MODE.NONE:
		if event is InputEventKey and event.is_pressed():
			get_viewport().set_input_as_handled()
			viewport.push_input(event)

func _mouse_entered():
	mouseover = true
	playercharacter.disable_movement = true
	
func _mouse_exited():
	mouseover = false
	playercharacter.disable_movement = false
