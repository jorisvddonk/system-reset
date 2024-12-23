extends Control

func _ready():
	# Bind signals
	Globals.on_parsis_changed.connect(on_parsis_changed)
	Globals.on_ap_target_changed.connect(on_ap_target_changed)
	Globals._on_local_target_changed.connect(on_local_target_changed)
	Globals.vimana.vimana_status_change.connect(on_vimana_status_changed)
	Globals.game_loaded.connect(on_game_loaded)
	Globals.osd_updated.connect(on_osd_updated)
	Globals.update_fcs_status_request.connect(update_fcs_status)
	Globals.update_hud_selected_star_text_request.connect(update_starlabel_text)
	Globals.update_hud_selected_planet_text_request.connect(update_planetlabel_text)
	Globals.update_hud_lightyears_text_request.connect(update_lightyears_text)
	Globals.update_hud_dyams_text_request.connect(update_dyams_text)
	
	# Set up timer to periodically refresh various bits of the HUD
	var timer = Timer.new()
	timer.timeout.connect(poll_fcs_status_from_engine)
	timer.timeout.connect(update_epoc_label)
	timer.timeout.connect(update_fps_label)
	timer.timeout.connect(refresh_environment_label)
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
	refresh_environment_label()
	poll_fcs_status_from_engine()
	update_epoc_label()
	# NOTE: because the Stardrifter OSD updates are purely signal-based, we can't update those here.

func refresh_parsis_text():
	%ParsisLabel.text = "[center]Parsis: x=%s y=%s z=%s[/center]" % [int(Globals.feltyrion.dzat_x), int(-Globals.feltyrion.dzat_y), int(Globals.feltyrion.dzat_z)]

func refresh_numbodies():
	if Globals.vimana.active:
		%NumBodies.hide()
	else:
		if Globals.feltyrion.ap_reached && Globals.feltyrion.ap_targetted == 1:
			var nearstar_info = Globals.feltyrion.get_current_star_info()
			%NumBodies.show()
			%NumBodies.text = "[center]Number of bodies: %s[/center]" % [nearstar_info.nearstar_nob]
		else:
			%NumBodies.hide()

func refresh_selected_targets():
	if Globals.feltyrion.ap_targetted == 1:
		var ap_target_info = Globals.feltyrion.get_ap_target_info()
		%SelectedPlanet.text = ""
		if ap_target_info.has("ap_target_x") && ap_target_info.has("ap_target_y") && ap_target_info.has("ap_target_z"):
			%APTarget.text = "[center]remote target: x=%s y=%s z=%s [/center]" % [ap_target_info.ap_target_x, -ap_target_info.ap_target_y, ap_target_info.ap_target_z]
			%SelectedStar.text = Globals.feltyrion.get_star_name(ap_target_info.ap_target_x, ap_target_info.ap_target_y, ap_target_info.ap_target_z)
			if Globals.feltyrion.ip_targetted:
				%SelectedPlanet.text = Globals.feltyrion.get_planet_name(ap_target_info.ap_target_x, ap_target_info.ap_target_y, ap_target_info.ap_target_z, Globals.feltyrion.ip_targetted)
	elif Globals.feltyrion.ap_targetted == -1:
		%APTarget.text = "[center]remote target: x=%s y=%s z=%s [/center]" % [Globals.feltyrion.ap_target_x, Globals.feltyrion.ap_target_y, Globals.feltyrion.ap_target_z]
		%SelectedStar.text = "- DIRECT PARSIS TARGET -" # TODO: actually use a separate hud element for this, as in NIV it's styled differently / not displayed in this field.
		%SelectedPlanet.text = ""

func refresh_environment_label():
	%EnvironmentLabel.text = "GRAVITY %6.3f FG & TEMPERATURE +15.0@c & PRESSURE 1.000 ATM & PULSE 120 PPS" % Globals.get_gravity()

var lastFCSStatusText = ""
## Polls the FCS status text from the engine (Feltyrion-godot).
## If it's changed, force-updates the FCS status text
func poll_fcs_status_from_engine(forceUpdate: bool = false):
	var curFCSStatusTextFromEngine = Globals.feltyrion.get_fcs_status()
	if forceUpdate or lastFCSStatusText != curFCSStatusTextFromEngine:
		update_fcs_status(curFCSStatusTextFromEngine)
		lastFCSStatusText = curFCSStatusTextFromEngine

## Update FCS status text in the HUD
## This is typically called either via poll_fcs_status_from_engine(), or through a Global method (Globals.update_fcs_status_text(val))
func update_fcs_status(val: String, timeout: int = 0):
	if timeout > 0:
		var timer = Timer.new()
		timer.timeout.connect(func(): poll_fcs_status_from_engine(true))
		timer.timeout.connect(func(): timer.queue_free())
		timer.wait_time = timeout
		timer.one_shot = true
		add_child(timer)
		timer.start()
	%FCSStatus.text = "[right]%s[/right]" % val

## Update Star label in the HUD
## This is called or through a Global method (Globals.update_hud_selected_star_text(val))
func update_starlabel_text(val: String):
	%SelectedStar.text = val
	
## Update Planet label in the HUD
## This is called or through a Global method (Globals.update_hud_selected_planet_text(val))
func update_planetlabel_text(val: String):
	%SelectedPlanet.text = val
	
## Update Lightyears in the HUD
## This is called or through a Global method (Globals.update_hud_lightyears_text(val))
func update_lightyears_text(val: String):
	%LightYears.text = val
	
## Update Dyams in the HUD
## This is called or through a Global method (Globals.update_hud_dyams_text(val))
func update_dyams_text(val: String):
	%Dyams.text = val

func update_epoc_label():
	var secs = Globals.feltyrion.get_secs()
	var epoc = floor(6011 + secs / 1e9)
	var sinisters = floor(fmod(secs, 1e9) / 1e6)
	var medii = floor(fmod(secs, 1e6) / 1e3)
	var dexters = floor(fmod(secs, 1e3))
	%EpocLabel.text = "EPOC %04s & %03s.%03s.%03s" % [epoc, sinisters, medii, dexters]

func update_fps_label():
	%FPSLabel.text = " & " + str(Engine.get_frames_per_second()) + " FPS"

func on_osd_updated(item1_text: String, item2_text: String, item3_text: String, item4_text: String):
	if item1_text != "": # if the first item is set, we know we haven't turned the screen off
		%MenuLabel.text = "6\\%-20s 7\\%-20s 8\\%-20s  9\\%-20s" % [item1_text.substr(0,20), item2_text.substr(0,20), item3_text.substr(0,20), item4_text.substr(0,20)]
	else:
		show_menulabel_for_osd_off()
		
func show_menulabel_for_osd_off():
	%MenuLabel.text = "1\\%-20s 2\\%-20s 3\\%-20s  4\\%-20s" % ["FLIGHT CONTROL DRIVE", "DEVICES", "PREFERENCES", "SCREEN OFF"]


func show_detail():
	$HUDRim/Top/HBoxContainer.show()
	$HUDRim/Top/HBoxContainer2.show()
	$HUDRim/Bottom/HBoxContainer.show()
	$HUDRim/Bottom/HBoxContainer2.show()
	$Aimpoint.show()
	$HUDTexts.show()
	
func hide_detail():
	$HUDRim/Top/HBoxContainer.hide()
	$HUDRim/Top/HBoxContainer2.hide()
	$HUDRim/Bottom/HBoxContainer.hide()
	$HUDRim/Bottom/HBoxContainer2.hide()
	$Aimpoint.hide()
	$HUDTexts.hide()
