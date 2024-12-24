extends Node3D
class_name Planet
@export var type: int
@export var seed: float
@export var planet_index: int
@export var planet_name: String
@export var planet_viewpoint: int # this value seems to not match the one in Noctis IV at all - I suppose it relies on the player's ship position - so don't use this!
@export var planet_term_start: int
@export var planet_rotation: int
@export var planet_pos_relative_to_star_x: float
@export var planet_pos_relative_to_star_y: float
@export var planet_pos_relative_to_star_z: float
var mouseover = false
var clicking = false
signal clicked()
const orig_color = Color.LIGHT_CORAL
const highlight_color = Color.CORAL
const local_tgt_highlight_color = Color.ROYAL_BLUE

# Called when the node enters the scene tree for the first time.
func _ready():
	$PlanetNameLabel.text = planet_name
	generate()
	setSelected(false)
	Globals.mouse_click_begin.connect(click_begin)
	Globals.mouse_clicked.connect(clicked_end)
	Globals.ui_mode_changed.connect(func (ui_mode): setSelected(false) if ui_mode == Globals.UI_MODE.NONE else null)
	Globals._on_local_target_changed.connect(_on_local_target_changed)
	Globals.on_debug_tools_enabled_changed.connect(_on_debug_tools_enabled_changed)
	Globals.hud_mode_changed.connect(func (_a): updateSpriteVisibility())
	Globals._on_local_target_orbit_changed.connect(func (_a): updateSpriteVisibility())
	_on_debug_tools_enabled_changed(Globals.debug_tools_enabled)

func generate():
	Globals.feltyrion.load_planet_at_current_system(planet_index)
	var ipinfo = Globals.feltyrion.get_planet_info(planet_index)
	updateSpriteVisibility()
	var img = Globals.feltyrion.return_image(true, false, ipinfo["nearstar_p_owner"] > -1)
	var imageTexture = ImageTexture.create_from_image(img)
	$PlanetParent/Surface.mesh.material.albedo_texture = imageTexture
	
	var atmimg = Globals.feltyrion.return_atmosphere_image(true)
	var atmimageTexture = ImageTexture.create_from_image(atmimg)
	$PlanetParent/Atmosphere.mesh.material.albedo_texture = atmimageTexture
	

func _process(delta):
	# TODO: some of these operations probably don't have to be done every tick...
	$PlanetParent.transform.basis = Basis()
	$PlanetParent.rotate_y(atan2(planet_pos_relative_to_star_x, planet_pos_relative_to_star_z))
	$PlanetParent.rotate_y((to_positive((planet_term_start + 63)) % 360) * (PI / 180))
	%DebugRing.transform.basis = Basis()
	%DebugRing.rotate_x(PI / 2)
	%DebugRing.rotate_y(atan2(planet_pos_relative_to_star_x, planet_pos_relative_to_star_z))
	var dist = $PlanetParent.global_position.length()
	if dist > 5:
		$PlanetParent.hide()
		$Sprite3D.show()
		$Sprite3D.pixel_size = min(0.0012, max(0.0002, 0.006 / dist))
	else:
		$PlanetParent.show()
		$Sprite3D.hide()


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
		
func setSelected(selected):
	if selected:
		mouseover = true
		if Globals.ui_mode == Globals.UI_MODE.SET_LOCAL_TARGET:
			$PlanetNameLabel.modulate = local_tgt_highlight_color
			$SelectionSprite.show()
	else:
		mouseover = false
		clicking = false
		$SelectionSprite.hide()

func _showLabel():
	$PlanetNameLabel.show()
	$PlanetNameLabel.modulate = highlight_color
	$PlanetNameLabel.fixed_size = true
	$PlanetNameLabel.pixel_size = 0.0015
	
func _hideLabel():
	$PlanetNameLabel.hide()

func _on_local_target_changed(planet_index):
	set_current_local_target_sprite_visibility_for(planet_index)

func set_current_local_target_sprite_visibility_for(planet_index):
	$SelectionSprite.hide()
	if self.planet_index == planet_index:
		$CurrentLocalTargetSelectionSprite.show()
	else:
		$CurrentLocalTargetSelectionSprite.hide()

func updateSpriteVisibility():
	if Globals.hud_mode == Globals.HUD_MODE.HIDE:
		$CurrentLocalTargetSelectionSprite.hide()
		$SelectionSprite.hide()
	if Globals.hud_mode == Globals.HUD_MODE.SHOW:
		set_current_local_target_sprite_visibility_for(Globals.local_target_index)
		if Globals.local_target_orbit_index == planet_index:
			$CurrentLocalTargetSelectionSprite.hide()

func to_positive(val):
	while val < 0:
		val += 360
	return val
	
func _on_debug_tools_enabled_changed(enabled: bool):
	if enabled:
		$PlanetParent/Surface.mesh.material.backlight_enabled = true
		%DebugRing.show()
		_showLabel()
	else:
		$PlanetParent/Surface.mesh.material.backlight_enabled = false
		%DebugRing.hide()
		_hideLabel()
