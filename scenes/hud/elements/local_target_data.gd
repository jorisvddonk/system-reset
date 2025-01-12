extends VBoxContainer

func _ready():
	visibility_changed.connect(_visibility_changed)
	Globals.tick.connect(refresh)
	Globals._on_local_target_changed.connect(_local_target_changed)
		
func refresh():
	if Globals.local_target_index != -1:
		var targetInfo = Globals.feltyrion.get_planet_info(Globals.local_target_index)
		var planetName = Globals.feltyrion.get_planet_name_by_id(targetInfo.nearstar_p_identity)
		%HeaderLabel.text = "%s" % planetName # planetName already contains number as well
		var radius = targetInfo.nearstar_p_ray
		
		var rtperiod = targetInfo.nearstar_p_rtperiod
		var rotationInfo = "too far to estimate"
		if Globals.local_target_orbit_index == Globals.local_target_index:
			var p1 = int(rtperiod * 360)
			var p2 = int(int(p1 / 1000) / 1000)
			var p3 = int(int(p1 / 1000) % 1000)
			var p4 = int(p1 % 1000)
			rotationInfo = "triads %03d:%03d:%03d" % [p2, p3, p4]
		elif Globals.interplanetaryDrive.active:
			rotationInfo = "computing..."
		
		var revolutionInfo = ""
		var rtp = targetInfo.nearstar_p_revolution
		var r1 = int(rtp * 1e-9)
		var r2 = int(int(rtp * 1e-6) % 1000)
		var r3 = int(int(rtp * 1e-3) % 1000)
		var r4 = int(int(rtp) % 1000)
		if r1 < 2:
			revolutionInfo = "%1d EPOCS, %03d:%03d:%03d" % [r1, r2, r3, r4]
		else:
			if r1 < 2047:
				revolutionInfo = "%1d EPOCS, %03d:%03d:???" % [r1, r2, r3]
			else:
				revolutionInfo = "%1d EPOCS, %03d:???:???" % [r1, r2]
		
		%ContentLabel.text = "Period of rotation:
%s
Period of revolution:
%s
Radius:
%3.5f centidyams" % [rotationInfo, revolutionInfo, radius]
	else:
		%HeaderLabel.text = "Local target not set"
		%ContentLabel.text = ""
	
func _visibility_changed():
	refresh()

func _local_target_changed(_index):
	refresh()
