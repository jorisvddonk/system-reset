extends Control

func _ready():
	# Bind signals
	Globals.on_parsis_changed.connect(on_parsis_changed)
	Globals.on_ap_target_changed.connect(on_ap_target_changed)
	Globals._on_local_target_changed.connect(on_local_target_changed)
	Globals.vimana_status_change.connect(on_vimana_status_changed)
	Globals.game_loaded.connect(on_game_loaded)
	Globals.osd_updated.connect(on_osd_updated)
	
	# Set up timer to periodically refresh FCS and EpocLabel
	var timer = Timer.new()
	timer.timeout.connect(update_fcs_status)
	timer.timeout.connect(update_epoc_label)
	timer.wait_time = 1
	timer.one_shot = false
	add_child(timer)
	timer.start()
	
	# Defalt to "OSD off" display
	show_menulabel_for_osd_off()
	
	# Refresh the hud immediately
	refresh_hud()


#
# -- Signal handling
#

func on_game_loaded():
	refresh_hud()

func on_parsis_changed(_x, _y, _z):
	refresh_parsis_text()

func on_vimana_status_changed(_vimana_is_active):
	refresh_numbodies()

func on_ap_target_changed(_x, _y, _z, _id_code):
	refresh_selected_targets()
	
func on_local_target_changed(_planet_index):
	refresh_selected_targets()


#
# -- Hud drawing
#

func refresh_hud():
	refresh_parsis_text()
	refresh_numbodies()
	refresh_selected_targets()
	update_fcs_status()
	update_epoc_label()
	# NOTE: because the Stardrifter OSD updates are purely signal-based, we can't update those here.

func refresh_parsis_text():
	%ParsisLabel.text = "[center]Parsis: x=%s y=%s z=%s[/center]" % [int(Globals.feltyrion.ap_target_x), int(-Globals.feltyrion.ap_target_y), int(Globals.feltyrion.ap_target_z)]

func refresh_numbodies():
	if Globals.vimana_active:
		%NumBodies.hide()
	else:
		var nearstar_info = Globals.feltyrion.get_current_star_info()
		%NumBodies.show()
		%NumBodies.text = "[center]Number of bodies: %s[/center]" % [nearstar_info.nearstar_nob]

func refresh_selected_targets():
	var ap_target_info = Globals.feltyrion.get_ap_target_info()
	%APTarget.text = "[center]remote target: x=%s y=%s z=%s [/center]" % [ap_target_info.ap_target_x, -ap_target_info.ap_target_y, ap_target_info.ap_target_z]
	%SelectedStar.text = Globals.feltyrion.get_star_name(ap_target_info.ap_target_x, ap_target_info.ap_target_y, ap_target_info.ap_target_z)
	%SelectedPlanet.text = ""
	if Globals.feltyrion.ip_targetted:
		%SelectedPlanet.text = Globals.feltyrion.get_planet_name(ap_target_info.ap_target_x, ap_target_info.ap_target_y, ap_target_info.ap_target_z, Globals.feltyrion.ip_targetted)

func update_fcs_status():
	%FCSStatus.text = "[right]%s[/right]" % Globals.feltyrion.get_fcs_status()

func update_epoc_label():
	var secs = Globals.feltyrion.get_secs()
	var epoc = floor(6011 + secs / 1e9)
	var sinisters = floor(fmod(secs, 1e9) / 1e6)
	var medii = floor(fmod(secs, 1e6) / 1e3)
	var dexters = floor(fmod(secs, 1e3))
	%EpocLabel.text = "EPOC %04s & %03s.%03s.%03s" % [epoc, sinisters, medii, dexters]

func on_osd_updated(item1_text: String, item2_text: String, item3_text: String, item4_text: String):
	if item1_text != "": # if the first item is set, we know we haven't turned the screen off
		%MenuLabel.text = "6\\%-20s 7\\%-20s 8\\%-20s  9\\%-20s" % [item1_text.substr(0,20), item2_text.substr(0,20), item3_text.substr(0,20), item4_text.substr(0,20)]
	else:
		show_menulabel_for_osd_off()
		
func show_menulabel_for_osd_off():
	%MenuLabel.text = "1\\%-20s 2\\%-20s 3\\%-20s  4\\%-20s" % ["FLIGHT CONTROL DRIVE", "DEVICES", "PREFERENCES", "SCREEN OFF"]
