extends Node3D
@export var type: int
@export var seed: float
@export var planet_index: int
@export var planet_name: String
@export var planet_viewpoint: int
@export var planet_rotation: int
var mouseover = false
var clicking = false
signal clicked()
const orig_color = Color.LIGHT_CORAL
const highlight_color = Color.CORAL
const local_tgt_highlight_color = Color.ROYAL_BLUE

# Called when the node enters the scene tree for the first time.
func _ready():
	$PlanetNameLabel.text = planet_name
	$PlanetParent.rotate_y(((planet_viewpoint + planet_rotation + 89 + 35) % 360) * (PI / 180))
	generate()
	__mouse_exited()
	$Area3D.mouse_entered.connect(__mouse_entered)
	$Area3D.mouse_exited.connect(__mouse_exited)
	Globals.mouse_click_begin.connect(click_begin)
	Globals.mouse_clicked.connect(clicked_end)
	Globals.ui_mode_changed.connect(func (ui_mode): __mouse_exited() if ui_mode == Globals.UI_MODE.NONE else null)
	Globals._on_local_target_changed.connect(_on_local_target_changed)

func generate():
	Globals.feltyrion.load_planet(planet_index, type, seed, true, false)
	var img = Globals.feltyrion.return_image(true, false)
	var imageTexture = ImageTexture.create_from_image(img)
	$PlanetParent/Surface.mesh.material.albedo_texture = imageTexture
	
	var atmimg = Globals.feltyrion.return_atmosphere_image(true)
	var atmimageTexture = ImageTexture.create_from_image(atmimg)
	$PlanetParent/Atmosphere.mesh.material.albedo_texture = atmimageTexture


func click_begin():
	if mouseover && Globals.ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET:
		clicking = true

func clicked_end():
	if clicking:
		clicked.emit()
		if Globals.ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET:
			Globals.local_target_index = planet_index
			Globals.ui_mode = Globals.UI_MODE.NONE
		clicking = false
	

func __mouse_entered():
	mouseover = true
	$PlanetNameLabel.modulate = highlight_color
	$PlanetNameLabel.fixed_size = true
	$PlanetNameLabel.pixel_size = 0.003
	if Globals.ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET:
		$PlanetNameLabel.modulate = local_tgt_highlight_color
		$PlanetParent/SelectionSprite.show()

func __mouse_exited():
	mouseover = false
	clicking = false
	$PlanetNameLabel.modulate = orig_color
	$PlanetNameLabel.fixed_size = false
	$PlanetNameLabel.pixel_size = 0.0709
	$PlanetParent/SelectionSprite.hide()
	

func _on_local_target_changed(planet_index):
	$PlanetParent/SelectionSprite.hide()
	if self.planet_index == planet_index:
		$PlanetParent/CurrentLocalTargetSelectionSprite.show()
	else:
		$PlanetParent/CurrentLocalTargetSelectionSprite.hide()

