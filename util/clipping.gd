extends Node

const SURFACE_USABLE_XZ_MAX = 3259
const surfaceClipMin = Vector3(-SURFACE_USABLE_XZ_MAX, 0, -SURFACE_USABLE_XZ_MAX)
const surfaceClipMax = Vector3(SURFACE_USABLE_XZ_MAX, 2000, SURFACE_USABLE_XZ_MAX)

func surfaceClip(position: Vector3):
	return position.clamp(surfaceClipMin, surfaceClipMax) # technically we have a few more centimeters leftover room on X/Z, but this is fine
