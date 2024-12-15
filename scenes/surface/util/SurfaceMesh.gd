extends MeshInstance3D
var hasFixedBackfaceCollisions: bool = false

signal meshUpdated

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !hasFixedBackfaceCollisions and self.get_child_count() > 0:
		if self.get_child(0) is StaticBody3D:
			self.get_child(0).get_child(0).shape.backface_collision = true
			hasFixedBackfaceCollisions = true
			self.meshUpdated.emit()
