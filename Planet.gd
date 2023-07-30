extends Node3D
@export var type: int
@export var seed: float
@export var planet_index: int
@export var feltyrion: Feltyrion

# Called when the node enters the scene tree for the first time.
func _ready():
	generate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.rotate_y(delta * 0.7)

func generate():
	feltyrion.load_planet(planet_index, type, seed, false, false)
	var img = feltyrion.return_image(true, false)
	var imageTexture = ImageTexture.create_from_image(img)
	$Surface.material_override.albedo_texture = imageTexture
	
	var atmimg = feltyrion.return_atmosphere_image(true)
	var atmimageTexture = ImageTexture.create_from_image(atmimg)
	$Atmosphere.material_override.albedo_texture = atmimageTexture
	
	var l = $Surface.material_override
