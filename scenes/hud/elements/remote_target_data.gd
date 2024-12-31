extends VBoxContainer

var starName = null

func _ready():
	visibility_changed.connect(_visibility_changed)
	Globals.tick.connect(refresh)
	Globals.on_ap_target_changed.connect(_ap_target_changed)
		
func refresh():
	if Globals.feltyrion.ap_targetted == 1:
		if starName == null:
			recomputeStarName(Globals.feltyrion.ap_target_x, Globals.feltyrion.ap_target_y, Globals.feltyrion.ap_target_z)
		var targetInfo = Globals.feltyrion.get_ap_target_info()
		%HeaderLabel.text = "%s" % starName # starName already contains class info
		var radius = targetInfo.ap_target_ray
		var mass = Globals.feltyrion.get_ap_starmass()
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
