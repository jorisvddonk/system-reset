extends Node3D
@export var parsis: Vector3
@export var star_name: String
const orig_color = Color.GHOST_WHITE
const highlight_color = Color.MOCCASIN

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label3D.text = star_name
	_mouse_exited()
	$StaticBody3D.mouse_entered.connect(_mouse_entered)
	$StaticBody3D.mouse_exited.connect(_mouse_exited)

func _mouse_entered():
	$Label3D.modulate = highlight_color
	$Label3D.fixed_size = true
	$Label3D.pixel_size = 0.003

func _mouse_exited():
	$Label3D.modulate = orig_color
	$Label3D.fixed_size = false
	$Label3D.pixel_size = 0.0709
