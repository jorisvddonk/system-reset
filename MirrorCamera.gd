extends Camera3D

func _ready():
	Globals.on_camera_rotation.connect(_on_camera_rotate)

func _on_camera_rotate(rotation):
	self.rotation = rotation
