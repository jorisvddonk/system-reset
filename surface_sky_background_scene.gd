extends Node3D

"""
Surface sky background scene

This scene contains the 'sky' for the background scene; both the sky texture as well as any stars visible.

TODO: do not show stars underneath the horizon
TODO: show current solar system sun(s)
TODO: orient stars depending on where you are on the planet
"""

func _ready():
	for i in range(0, 2744):
		var star: Sprite3D = $Stars/Star.duplicate()
		star.position = Vector3(0,0,0)
		$Stars.add_child(star)
	recalculate()

func recalculate():
	print("RECALC")
	Globals.feltyrion.update_star_particles(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z, $Stars.get_path())
	var skyimg = Globals.feltyrion.return_sky_image()
	var rect = Rect2i(0, skyimg.get_height(), skyimg.get_width(), skyimg.get_height())
	skyimg.crop(skyimg.get_width(), skyimg.get_height() * 2)
	skyimg.fill_rect(rect, skyimg.get_pixel(0, int(skyimg.get_height() * 0.5 - 1)).darkened(0.1))
	var skyTexture = ImageTexture.create_from_image(skyimg)
	$WorldEnvironment.environment.sky.sky_material.panorama = skyTexture
