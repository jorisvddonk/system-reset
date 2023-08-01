@tool

extends Node3D
var Farstar = preload("res://far_star.tscn")
@onready var regex = RegEx.new()

func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	Globals.feltyrion.found_star.connect(_on_found_star)
	Globals.feltyrion.lock()
	#Globals.set_parsis(Vector3(3579984, -1002801, 305857)) # 'hello' star
	Globals.feltyrion.scan_stars()
	Globals.feltyrion.unlock()

func _on_found_star(x, y, z, id_code):
	var objname = Globals.feltyrion.get_star_name(x, y, z)
	objname = regex.sub(objname, "")
	var star = Farstar.instantiate()
	star.star_name = objname
	star.parsis = Vector3(x, y, z)
	star.id_code = id_code
	star.translate(Vector3(x/1000, y/1000, z/1000))
	$Stars.add_child(star)
