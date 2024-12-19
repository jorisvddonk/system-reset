extends MeshInstance3D
@onready var mouseover: bool = false
@export var viewport: SubViewport
@export var sdscreen: Panel
@export var camera: Camera3D
@export var playercharacter: CharacterBody3D
@export var area: Area3D
const INPUT_DISTANCE_SQUARED = 5
var did_disable_movement: bool = false

func _ready():
	area.mouse_entered.connect(_mouse_entered)
	area.mouse_exited.connect(_mouse_exited)

func _input(event):
	# only process/forward keys to the screen when we're mouse-overing AND close enough
	# when we do, disable movement
	# otherwise, if we detect that we disabled movement and the player is now outside of the movement zone, then re-enable movement
	if mouseover:
		if Globals.ui_mode == Globals.UI_MODE.NONE:
			if (Globals.playercharacter.global_position - area.global_position).length_squared() < INPUT_DISTANCE_SQUARED:
				if event is InputEventKey and event.is_pressed():
					playercharacter.disable_movement = true
					did_disable_movement = true
					get_viewport().set_input_as_handled()
					viewport.push_input(event)
			else:
				if did_disable_movement and playercharacter.disable_movement:
					# re-enable movement when the player leaves the activation rage, if we disabled movement earlier
					playercharacter.disable_movement = true
					did_disable_movement = false

func _mouse_entered():
	mouseover = true
	
func _mouse_exited():
	mouseover = false
	playercharacter.disable_movement = false
	did_disable_movement = false
