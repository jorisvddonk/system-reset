extends Node
class_name SkytextureSetter
## Sets the sky of the passed-in WorldEnvironment to that of a planet surface sky automatically whenever the Globals.planet_surface_prepared signal is emitted

@export var worldenvironment: WorldEnvironment

func _ready():
	Globals.planet_surface_prepared.connect(recalculate)

func recalculate():
	var skyimg = Globals.feltyrion.return_sky_image()
	var rect = Rect2i(0, skyimg.get_height(), skyimg.get_width(), skyimg.get_height())
	skyimg.crop(skyimg.get_width(), skyimg.get_height() * 2)
	skyimg.fill_rect(rect, skyimg.get_pixel(0, int(skyimg.get_height() * 0.5 - 1)).darkened(0.1))
	var skyTexture = ImageTexture.create_from_image(skyimg)
	if worldenvironment.environment and worldenvironment.environment is Environment:
		if not worldenvironment.environment.sky:
			worldenvironment.environment.background_mode = Environment.BG_SKY
			worldenvironment.environment.sky = Sky.new()
		if not worldenvironment.environment.sky.sky_material:
			worldenvironment.environment.sky.sky_material = PanoramaSkyMaterial.new()
		worldenvironment.environment.sky.sky_material.panorama = skyTexture
	else:
		print("WARN(SkyTextureSetter): passed in WorldEnvironment does not have environment")
