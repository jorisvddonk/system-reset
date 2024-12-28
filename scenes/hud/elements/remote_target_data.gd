extends VBoxContainer

var starName = null

func _ready():
	visibility_changed.connect(_visibility_changed)
	Globals.tick.connect(refresh)
	Globals.on_ap_target_changed.connect(_ap_target_changed)
	
func get_starmass_correction(starclass):
	# TODO: move this to feltyrion-godot
	if starclass == 0:
		return 1.886
	if starclass == 1:
		return 1.50   
	if starclass == 2:
		return 8000.40
	if starclass == 3:
		return 0.05   
	if starclass == 4:
		return 2.44   
	if starclass == 5:
		return 3.10   
	if starclass == 6:
		return 9.30   
	if starclass == 7:
		return 48.00  
	if starclass == 8:
		return 1.00 # TODO: this has some additional randomness correction!
	if starclass == 9:
		return 1.00 # TODO: this has some additional randomness correction!
	if starclass == 10:
		return 0.07   
	if starclass == 11:
		return 15000.00
		
func refresh():
	if Globals.feltyrion.ap_targetted == 1:
		if starName == null:
			recomputeStarName(Globals.feltyrion.ap_target_x, Globals.feltyrion.ap_target_y, Globals.feltyrion.ap_target_z)
		var targetInfo = Globals.feltyrion.get_ap_target_info()
		%HeaderLabel.text = "%s" % starName # starName already contains class info
		var radius = targetInfo.ap_target_ray
		var mass = 0.001 * (4 * PI / 3) * radius * radius * radius * get_starmass_correction(targetInfo.ap_target_class)
		var temperature = mass / (0.38e-4 * targetInfo.ap_target_ray)
		var starnop = Globals.feltyrion.get_starnop_estimate(Globals.feltyrion.ap_target_x, Globals.feltyrion.ap_target_y, Globals.feltyrion.ap_target_z)
		if targetInfo.ap_target_class == 6:
			temperature = temperature * 0.0022
		
		%ContentLabel.text = "Primary mass:    Radius:
%8.5f BAL M  %8.3f\n              Centidyams
Surface temperature:
%5.0f@k&%5.0f@c&%6.0f@f
major bodies: %d est." % [mass, radius, temperature + 273.15, temperature, temperature * 1.8 + 32, starnop]
	else:
		%HeaderLabel.text = "Remote target not set"
		%ContentLabel.text = ""
	
func _visibility_changed():
	refresh()

func _ap_target_changed(x, y, z, _code):
	recomputeStarName(x, y, z)
	refresh()

func recomputeStarName(x, y, z):
	if Globals.feltyrion.ap_targetted == 1:
		starName = Globals.feltyrion.get_star_name(x, y, z)
	else:
		starName = null
