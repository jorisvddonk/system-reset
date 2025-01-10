extends Node

var secs
var epoc = 6012
var sinisters
var medii
var dexters

func _ready():
	_update_time()
	var timer = Timer.new()
	timer.timeout.connect(_update_time)
	timer.wait_time = 1
	timer.one_shot = false
	add_child(timer)
	timer.start()

func _update_time():
	secs = Globals.feltyrion.get_secs()
	epoc = floor(6011 + secs / 1e9)
	sinisters = floor(fmod(secs, 1e9) / 1e6)
	medii = floor(fmod(secs, 1e6) / 1e3)
	dexters = floor(fmod(secs, 1e3))
