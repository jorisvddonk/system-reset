extends Node3D

func _ready():
	%SurfaceContainer.connect("child_entered_tree", func(c): c.connect("meshUpdated", surfaceMeshUpdated))
	if %ScatteringContainer.get_meta("enabled"):
		Globals.feltyrion.prepare_surface_scattering(%ScatteringContainer, "res://scenes/surface/util/ScatteringObject.tscn", %ScatteringContainer.get_meta("generateSingleMesh"))
	if %SurfaceContainer.get_meta("enabled"):
		Globals.feltyrion.prepare_surface_mesh(%SurfaceContainer, "res://scenes/surface/util/SurfaceMesh.tscn")
		
func initialize():
	var grav = Globals.get_gravity() * 9.8
	%PlayerCharacterController.gravity = grav
	if Globals.feltyrion.get_planet_info(Globals.feltyrion.ip_targetted).nearstar_p_type == 3:
		$Water.show()
	else:
		$Water.hide()

func surfaceMeshUpdated():
	var rc = RayCast3D.new()
	var space_state = %PlayerCharacterController.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(Vector3(0,1000,0), Vector3(0,-1000,0))
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_back_faces = true
	query.hit_from_inside = true
	var result = space_state.intersect_ray(query)
	if result:
		%PlayerCharacterController.position = result.position + Vector3(0,4,0)
