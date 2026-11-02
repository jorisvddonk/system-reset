extends VBoxContainer

## Shows the environment data screen (onboard devices -> miscellaneous -> environment
## data), mirroring Noctis IV's "EXTERNAL ENVIRONMENT" screen.

func _ready():
	visibility_changed.connect(_visibility_changed)
	Globals.tick.connect(refresh)

func refresh():
	%HeaderLabel.text = "EXTERNAL ENVIRONMENT"
	%ContentLabel.text = _get_environment_text()

func _visibility_changed():
	refresh()

func _get_environment_text() -> String:
	var info = Globals.feltyrion.get_current_star_info()
	if not info.has("nearstar_class"):
		return "no stellar system in range"
	var dsd = _get_distance_to_star() + 1.0
	var eclipse = 0.0 # eclipses are not implemented yet, see #13
	var temp_c = 16.0 - dsd * 0.044
	temp_c *= abs(temp_c)
	temp_c -= (temp_c + 273.15) * eclipse
	var secs = Globals.feltyrion.get_secs()
	var temp_rng = RandomNumberGenerator.new()
	temp_rng.seed = int(secs / 2)
	if temp_c < -269.0:
		temp_c = temp_rng.randf() - 269.0
	return "TEMP. %1.2f@K\n      %1.2f@C\n      %1.2f@F\nLI+ IONS: %d MTPD EST.\nRADIATION: %1.1f KR" % [
		temp_c + 273.15,
		temp_c,
		temp_c * 1.8 + 32,
		_get_lithium_ion_estimate(info, dsd),
		_get_radiation_estimate(info, dsd, secs, eclipse)]

func _get_distance_to_star() -> float:
	var dx = Globals.feltyrion.dzat_x - Globals.feltyrion.get_nearstar_x()
	var dy = Globals.feltyrion.dzat_y - Globals.feltyrion.get_nearstar_y()
	var dz = Globals.feltyrion.dzat_z - Globals.feltyrion.get_nearstar_z()
	return sqrt(dx * dx + dy * dy + dz * dz)

## Lithium ion estimate, as in Noctis IV: only class 5 and 6 stars are suitable,
## with class 6 giving the best results but being harder to exploit.
func _get_lithium_ion_estimate(info: Dictionary, dsd: float) -> int:
	var star_class = info.nearstar_class
	if star_class != 5 and star_class != 6:
		return 0
	var rng = RandomNumberGenerator.new()
	rng.seed = int(abs(info.get("nearstar_id_code", 0.0)) * 1000000)
	var ions = rng.randi_range(0, 49)
	if star_class == 5:
		ions -= int(125 / dsd)
		if ions <= 0:
			ions = 1
	else:
		ions -= int(25 / dsd)
	return ions

## Radiation estimate, as in Noctis IV: a distance based base value, scaled by a
## per-star-class factor, with a small amount of jitter.
func _get_radiation_estimate(info: Dictionary, dsd: float, secs: float, eclipse: float) -> float:
	var rng = RandomNumberGenerator.new()
	rng.seed = int(secs)
	var radiation = 50.0 + rng.randi_range(0, 9) - rng.randi_range(0, 9)
	radiation *= (1.0 - eclipse)
	radiation *= 100.0 / dsd
	match info.nearstar_class:
		1: radiation *= 5.0
		2: radiation *= 18.0
		3: radiation *= 0.5
		4: radiation *= 10.0
		5: radiation *= 0.1
		6: radiation *= 0.01
		7: radiation *= 25.0
		8: radiation *= 1.5
		9: radiation *= 3.0
		10: radiation *= 0.25
		11: radiation *= 50.0
	var jitter_rng = RandomNumberGenerator.new()
	jitter_rng.seed = int(secs)
	radiation *= 1.0 + jitter_rng.randi_range(0, 99) * 0.001 - jitter_rng.randi_range(0, 99) * 0.001
	return radiation
