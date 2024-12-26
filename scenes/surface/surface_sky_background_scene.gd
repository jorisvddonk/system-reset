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
	if _should_show_stars():
		Globals.feltyrion.update_star_particles(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z, $Stars.get_path())
		$Stars.show()
	else:
		$Stars.hide()
	
func _should_show_stars():
	return Globals.feltyrion.sky_brightness < 32 and Globals.feltyrion.rainy < 2.0
