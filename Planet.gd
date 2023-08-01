extends Node3D
@export var type: int
@export var seed: float
@export var planet_index: int
@export var planet_name: String

# Called when the node enters the scene tree for the first time.
func _ready():
	$PlanetNameLabel.text = planet_name
	generate()

func generate():
	Globals.feltyrion.load_planet(planet_index, type, seed, true, false)
	var img = Globals.feltyrion.return_image(true, false)
	var imageTexture = ImageTexture.create_from_image(img)
	$PlanetParent/Surface.mesh.material.albedo_texture = imageTexture
	
	var atmimg = Globals.feltyrion.return_atmosphere_image(true)
	var atmimageTexture = ImageTexture.create_from_image(atmimg)
	$PlanetParent/Atmosphere.mesh.material.albedo_texture = atmimageTexture

