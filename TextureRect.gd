extends TextureRect
@export var button: Button
@export var optionButton: OptionButton
@export var seedInput: TextEdit
@onready var feltyrion = Feltyrion.new()

func _ready():
	button.pressed.connect(_on_generate_pressed)
	_on_generate_pressed()
	
func _on_generate_pressed():
	if (seedInput.text == ""):
		randomize()
		generate(optionButton.selected, randf() * 1000)
	else:
		generate(optionButton.selected, float(seedInput.text))
	
func _on_found_star(x, y, z):
	print(x, ":", y, ":", z)
	print("Object name: ", feltyrion.get_object_name(x, y, z, true))

func generate(type, seed):
	feltyrion.found_star.connect(_on_found_star)
	feltyrion.lock()
	feltyrion.prepare_star()
	feltyrion.load_planet(1, type, seed, false, true)
	var img = feltyrion.return_image(true, false)
	#img = feltyrion.return_atmosphere_image()
	var imageTexture = ImageTexture.create_from_image(img)
	self.texture = imageTexture
	self.queue_redraw()
	# feltyrion.scan_stars()
	feltyrion.unlock()
