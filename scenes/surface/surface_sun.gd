extends Sprite3D
class_name SurfaceSun
## Renders the local system's sun(s) in the sky of a planet surface, using the sun
## positions that the engine computes when preparing the planet surface (see
## planetary_main() in noctis-1.cpp). The engine's surface coordinate system uses
## the same axes as the surface scene, except that its Y axis points down.

## The distance at which the sun is rendered. Only used to size it: the apparent
## size of the sun is derived from its real angular size, so it looks the same
## regardless of this distance.
const SUN_RENDER_DISTANCE = 8000.0

@export var player: Node3D
@export var secondary_sun: Sprite3D

func _ready():
	Globals.planet_surface_prepared.connect(recalculate)
	Globals.tick.connect(recalculate)
	recalculate()

func recalculate():
	if player == null:
		return
	var sun_info = Globals.feltyrion.get_sun_info()
	_place_sun(self, sun_info, "sun")
	if secondary_sun != null:
		_place_sun(secondary_sun, sun_info, "secondary_sun")

## Places a sun sprite in the sky, given the engine's sun information. The sun is
## hidden when it is below the horizon (its Y coordinate is positive in the
## engine's down-pointing coordinate system).
func _place_sun(sprite: Sprite3D, sun_info: Dictionary, prefix: String):
	var direction = Vector3(sun_info[prefix + "_x"], -sun_info[prefix + "_y"], sun_info[prefix + "_z"])
	var ray = sun_info[prefix + "_ray"]
	var distance = sun_info[prefix + "_distance"]
	if ray <= 0.0 or distance <= 0.0 or direction.length() < 0.000001 or direction.y <= 0.0:
		sprite.hide()
		return
	sprite.show()
	sprite.global_position = player.global_position + direction.normalized() * SUN_RENDER_DISTANCE
	# Size the sprite so that its angular size matches the real sun's angular size.
	var angular_radius = atan(ray / distance)
	var world_radius = tan(angular_radius) * SUN_RENDER_DISTANCE
	sprite.pixel_size = 2.0 * world_radius / max(1, sprite.texture.get_width())
