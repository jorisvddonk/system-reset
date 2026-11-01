extends MeshInstance3D
class_name CompanionStar

## The index of this body within the current star system.
@export var planet_index: int = -1
## The name of this body, as stored in the starmap (if any).
@export var star_name: String = ""
## The radius of this star, as reported by the engine.
@export var ray: float = 1.0

## Configures this node to render a companion star of the current system.
## Uses the primary star's mesh and material, so that the companion star looks
## like the other star in the system.
func configure(index: int, body_name: String, star_ray: float, source_mesh: Mesh, source_material: Material):
	planet_index = index
	star_name = body_name
	ray = star_ray
	mesh = source_mesh
	material_override = source_material.duplicate()
	scale = Vector3.ONE * (star_ray / 13.0)
