extends Node3D
var Farstar = preload("res://scenes/space/remote/far_star.tscn")
@onready var regex = RegEx.new()

func _ready():
	regex.compile("\\s*S[0-9][0-9]")
	Globals.feltyrion.found_star.connect(_on_found_star)
	Globals.vimana_status_change.connect(_on_vimana_status_change)
	Globals.game_loaded.connect(on_game_loaded)
	# create lots of stars (duplicates of the first child of $Stars)
	for i in range(0, 2744):
		var star: Sprite3D = $StarsVimana/Star.duplicate()
		star.position = Vector3(0,0,0)
		$StarsVimana.add_child(star)
	
	scan_for_stars()

func _exit_tree():
	for item in $Stars.get_children():
		item.queue_free()
	for item in $StarsVimana.get_children():
		item.queue_free()

func on_game_loaded():
	scan_for_stars()

func _on_found_star(x, y, z, id_code):
	var objname = Globals.feltyrion.get_star_name(x, y, z)
	objname = regex.sub(objname, "")
	var star = Farstar.instantiate()
	star.star_class = "S??" # TODO
	star.star_name = objname
	star.parsis_x = x
	star.parsis_y = y
	star.parsis_z = z
	star.id_code = id_code
	star.position = Vector3((x - Globals.feltyrion.dzat_x) * 0.001, (y - Globals.feltyrion.dzat_y) * 0.001, (z - Globals.feltyrion.dzat_z) * 0.001)
	$Stars.add_child(star)
	
# Scan for stars and show stars around
func scan_for_stars():
	for item in $Stars.get_children():
		item.queue_free()
	Globals.feltyrion.lock()
	Globals.feltyrion.scan_stars()
	Globals.feltyrion.unlock()
	$Stars.show()
	$StarsVimana.hide()
	
# begin the 'vimana flight active' effects
func begin_vimana_flight_fx():
	updateVimanaParticles()
	$StarsVimana.show()
	$Stars.hide()
	for item in $Stars.get_children():
		item.queue_free()

func _on_vimana_status_change(vimana_is_active):
	if vimana_is_active:
		begin_vimana_flight_fx()
	else:
		scan_for_stars()

# Update the location of the vimana stars fx
func updateVimanaParticles():
	Globals.feltyrion.update_star_particles(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z, $StarsVimana.get_path())

func _process(delta):
	if Globals.vimana_active:
		# During vimana flight, continuously update the vimana flight fx
		updateVimanaParticles()
	if Globals.ui_mode == Globals.UI_MODE.SET_REMOTE_TARGET:
		# figure out which star is closest
		var playerrot = Globals.player_rotation_in_space.normalized()
		var rotation_basis: Basis = Basis().from_euler(Globals.player_rotation_in_space)
		var forward_vector: Vector3 = -rotation_basis.z
		var normalized_forward: Vector3 = forward_vector.normalized()
		var lowestdotdot = -1
		var lowestdotrot_node = null
		for star in $Stars.get_children():
			if star is Node3D and star is Farstar:
				var dotrot = normalized_forward.dot((star.global_position - Globals.playercharacter.global_position).normalized())
				if dotrot > lowestdotdot:
					lowestdotdot = dotrot
					if lowestdotrot_node != null:
						lowestdotrot_node.setSelected(false)
					star.setSelected(true)
					lowestdotrot_node = star
				else:
					star.setSelected(false)
		if lowestdotrot_node != null and lowestdotrot_node is Farstar:
			var s = (lowestdotrot_node as Farstar)
			var starLabel = Globals.feltyrion.get_star_name(s.parsis_x, s.parsis_y, s.parsis_z) # starlabel already contains star class
			Globals.update_hud_selected_star_text(starLabel)
