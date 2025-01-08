extends Node3D

var gravity
func _ready():
	%SurfaceContainer.connect("child_entered_tree", func(c): c.connect("meshUpdated", surfaceMeshUpdated))
	if %ScatteringContainer.get_meta("enabled"):
		Globals.feltyrion.prepare_surface_scattering(%ScatteringContainer, "res://scenes/surface/util/ScatteringObject.tscn", %ScatteringContainer.get_meta("generateSingleMesh"))
	if %SurfaceContainer.get_meta("enabled"):
		Globals.feltyrion.prepare_surface_mesh(%SurfaceContainer, "res://scenes/surface/util/SurfaceMesh.tscn")
		
func initialize():
	gravity = Globals.get_gravity() * 9.8
	%PlayerCharacterController.gravity = gravity
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, gravity)
	if Globals.feltyrion.get_planet_info(Globals.feltyrion.ip_targetted).nearstar_p_type == 3:
		var paletteimg = Globals.feltyrion.get_surface_palette_as_image()
		$Water.mesh.material.albedo_color = paletteimg.get_pixel(99, 0)
		$Water.show()
		if Globals.feltyrion.rainy < 0.01:
			%Rain.queue_free()
		else:
			%Rain.amount = 1000 + (9000 * Globals.feltyrion.rainy) # rainy variable is beteween 0.0 and 5.0
	else:
		%Rain.queue_free()
		$Water.hide()
	if not Globals.debug_tools_enabled:
		%PlayerCharacterController.lock_to($CupolaRigidBody)
		Globals.update_fcs_status_text("INITIALIZING LANDING SEQUENCE")

func _getCollisionPoint(x, z):
	var rc = RayCast3D.new()
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(Vector3(x,2000,z), Vector3(x,-2000,z))
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_back_faces = true
	query.hit_from_inside = true
	var result = space_state.intersect_ray(query)
	return result

func surfaceMeshUpdated():
	var point = _getCollisionPoint(0.5, 0.5)
	if point:
		$CupolaRigidBody.position.y = point.position.y + 400
	else:
		printt("Could not find collision point - setting static y coordinate for Cupola as fallback")
		$CupolaRigidBody.position.y = 1800
	if %PlayerCharacterController.lockedTo == null: # if debugging or something and the player wasn't captured, move them as well!
		%PlayerCharacterController.position = point.position + Vector3(0,4,0)

var cupolaCaptureTimeout
enum CUPOLA_STATE { DESCENDING, IDLE, RISING }
var cupolaState: CUPOLA_STATE = CUPOLA_STATE.DESCENDING
func _physics_process(delta):
	if $CupolaRigidBody.sleeping and cupolaState == CUPOLA_STATE.DESCENDING:
		cupolaCaptureTimeout = 5
		%PlayerCharacterController.unlock()
		Globals.update_fcs_status_text("")
		cupolaState = CUPOLA_STATE.IDLE
	if cupolaState == CUPOLA_STATE.IDLE:
		if cupolaCaptureTimeout > 0:
			cupolaCaptureTimeout -= delta
		else:
			if (%PlayerCharacterController.position - $CupolaRigidBody.position).length() < 5:
				Globals.update_fcs_status_text("INITIALIZING RETURN SEQUENCE")
				printt("Returning to Stardrifter")
				cupolaState = CUPOLA_STATE.RISING
				%PlayerCharacterController.lock_to($CupolaRigidBody)
				$CupolaRigidBody.add_constant_force(Vector3.UP * gravity * 1000 * 2.5)
				$CupolaRigidBody.apply_force(Vector3.UP * gravity * 1000 * 2.5)
	if cupolaState == CUPOLA_STATE.RISING:
		if $CupolaRigidBody.position.y > 2000:
			Globals.update_fcs_status_text("")
			Globals.initiate_return_sequence.emit()
