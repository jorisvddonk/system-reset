extends Node3D
var Farstar = preload("res://far_star.tscn")
@onready var regex = RegEx.new()

func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	Globals.feltyrion.found_star.connect(_on_found_star)
	Globals.feltyrion.lock()
	Globals.feltyrion.scan_stars()
	Globals.feltyrion.unlock()
	Globals.vimana_status_change.connect(_on_vimana_status_change)
	# create lots of stars (duplicates of the first child of $Stars)
	for i in range(0, 2744):
		var star: Sprite3D = $StarsVimana/Star.duplicate()
		star.position = Vector3(0,0,0)
		$StarsVimana.add_child(star)

func _on_found_star(x, y, z, id_code):
	var objname = Globals.feltyrion.get_star_name(x, y, z)
	objname = regex.sub(objname, "")
	var star = Farstar.instantiate()
	star.star_name = objname
	star.parsis_x = x
	star.parsis_y = y
	star.parsis_z = z
	star.id_code = id_code
	star.position = Vector3((x - Globals.feltyrion.dzat_x) * 0.001, (y - Globals.feltyrion.dzat_y) * 0.001, (z - Globals.feltyrion.dzat_z) * 0.001)
	$Stars.add_child(star)

func _on_vimana_status_change(vimana_is_active):
	if vimana_is_active:
		updateVimanaParticles()
		$StarsVimana.show()
		$Stars.hide()
	else:
		for item in $Stars.get_children():
			$Stars.remove_child(item)
		Globals.feltyrion.scan_stars()
		$Stars.show()
		$StarsVimana.hide()

func updateVimanaParticles():
	Globals.feltyrion.update_star_particles(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z, $StarsVimana.get_path())

func _process(delta):
	if Globals.vimana_active:
		updateVimanaParticles()
