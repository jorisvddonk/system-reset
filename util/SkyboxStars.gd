extends Node3D
class_name SkyboxStars
## Creates a bunch of star particles, to be used as a skybox on planet surfaces.
## TODO: do not show stars underneath the horizon
## TODO: orient stars depending on where you are on the planet

@export var baseSprite: Sprite3D
@export var distanceMultiplier: float = 1
@export var counterRotateCamera: bool = false

func _ready():
	for i in range(0, 2744):
		var star: Sprite3D = baseSprite.duplicate()
		star.position = Vector3(0,0,0)
		star.show()
		add_child(star)
	Globals.planet_surface_prepared.connect(recalculate)
	if counterRotateCamera:
		Globals.on_camera_rotation.connect(_on_camera_rotate)

func recalculate():
	if _should_show_stars():
		Globals.feltyrion.update_star_particles(Globals.feltyrion.dzat_x, Globals.feltyrion.dzat_y, Globals.feltyrion.dzat_z, distanceMultiplier, self.get_path())
		show()
	else:
		hide()
	
func _should_show_stars():
	return Globals.feltyrion.sky_brightness < 32 and Globals.feltyrion.rainy < 2.0

func _on_camera_rotate(rotation):
	#self.rotation.x = rotation.x
	self.rotation.y = -rotation.y
	#self.rotation.z = rotation.z
