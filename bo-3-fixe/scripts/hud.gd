extends CanvasLayer

@onready var ammo_label:  Label       = $AmmoLabel
@onready var health_bar:  ProgressBar = $HealthBar
@onready var crosshair:   Control     = $Crosshair
@onready var hit_marker:  Control     = $HitMarker

# ─── Joystick Izquierdo (movimiento) ───────────────────────
@onready var joy_left:       Control = $JoystickLeft
@onready var joy_left_base:  Control = $JoystickLeft/JoystickLeftBase
@onready var joy_left_knob:  Control = $JoystickLeft/JoystickLeftKnob

# ─── Disparo ───────────────────────────────────────────────
@onready var btn_shoot: TextureButton = $ButtonsRight/ShootBtn

# ─── Botones ───────────────────────────────────────────────
@onready var btn_jump:   TextureButton = $ButtonsRight/JumpBtn
@onready var btn_sprint: TextureButton = $ButtonsRight/SprintBtn
@onready var btn_reload: TextureButton = $ButtonsRight/ReloadBtn

# Radio máximo del knob dentro del base
const JOY_RADIUS := 80.0
# Sensibilidad del joystick derecho para la cámara
var LOOK_SENS  := 3.5

var player: CharacterBody3D
var hit_marker_timer := 0.0

# Estado de los joysticks
var left_touch_index  := -1
var right_touch_index := -1
var left_value  := Vector2.ZERO
var right_value := Vector2.ZERO

# Estado de botones táctiles
var touch_jump   := false
var touch_sprint := false

func _ready() -> void:
	LOOK_SENS = Global.sensitivity * 1750.0 # Aproximación para que la sensibilidad táctil sea similar al ratón proporcionalmente

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	_draw_joysticks()
	_connect_buttons()

func _connect_buttons() -> void:
	btn_jump.button_down.connect(func(): touch_jump = true)
	btn_jump.button_up.connect(func(): touch_jump = false)
	btn_sprint.button_down.connect(func(): touch_sprint = true)
	btn_sprint.button_up.connect(func(): touch_sprint = false)
	btn_reload.pressed.connect(_on_reload_pressed)
	btn_shoot.button_down.connect(func(): _set_shooting(true))
	btn_shoot.button_up.connect(func(): _set_shooting(false))

func _set_shooting(shooting: bool) -> void:
	if not player: return
	var weapon = player.get_node_or_null("Head/Camera3D/WeaponHolder/Weapon")
	if weapon:
		weapon.virtual_shoot = shooting

func _on_reload_pressed() -> void:
	if not player: return
	var weapon = player.get_node_or_null("Head/Camera3D/WeaponHolder/Weapon")
	if weapon and weapon.has_method("reload"):
		weapon.reload()

func _draw_joysticks() -> void:
	# Dibuja los círculos de los joysticks via _draw() sobreescrito en los bases
	joy_left_base.draw.connect(_draw_base.bind(joy_left_base))
	joy_left_knob.draw.connect(_draw_knob.bind(joy_left_knob))

func _draw_base(node: Control) -> void:
	var c := node.size * 0.5
	node.draw_circle(c, node.size.x * 0.5, Color(1,1,1,0.12))
	node.draw_arc(c, node.size.x * 0.5, 0, TAU, 64, Color(1,1,1,0.4), 2.0)

func _draw_knob(node: Control) -> void:
	var c := node.size * 0.5
	node.draw_circle(c, node.size.x * 0.5, Color(1,1,1,0.55))

func _input(event: InputEvent) -> void:
	# Solo procesar táctil
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _is_position_on_button(pos: Vector2) -> bool:
	var buttons = [btn_jump, btn_sprint, btn_reload, btn_shoot]
	for btn in buttons:
		if is_instance_valid(btn):
			var rect = Rect2(btn.global_position, btn.size)
			if rect.has_point(pos):
				return true
	return false

func _handle_touch(event: InputEventScreenTouch) -> void:
	# Skip if pressing a button
	if _is_position_on_button(event.position):
		return

	var screen_mid := get_viewport().get_visible_rect().size.x * 0.5

	if event.pressed:
		if event.position.x < screen_mid and left_touch_index == -1:
			left_touch_index = event.index
			_update_left_knob(event.position)
		elif event.position.x >= screen_mid and right_touch_index == -1:
			right_touch_index = event.index
			right_value = Vector2.ZERO
	else:
		if event.index == left_touch_index:
			left_touch_index = -1
			left_value = Vector2.ZERO
			_reset_left_knob()
		elif event.index == right_touch_index:
			right_touch_index = -1
			right_value = Vector2.ZERO

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == left_touch_index:
		_update_left_knob(event.position)
	elif event.index == right_touch_index:
		_update_right_value(event.relative)


func _update_left_knob(screen_pos: Vector2) -> void:
	var base_center := joy_left.global_position + joy_left.size * 0.5
	var delta := screen_pos - base_center
	var clamped := delta.limit_length(JOY_RADIUS)
	left_value = clamped / JOY_RADIUS
	# Mover el knob visualmente
	var knob_center := joy_left.size * 0.5 + clamped - joy_left_knob.size * 0.5
	joy_left_knob.position = knob_center

func _reset_left_knob() -> void:
	joy_left_knob.position = joy_left.size * 0.5 - joy_left_knob.size * 0.5

func _update_right_value(relative: Vector2) -> void:
	right_value = relative



func _process(delta: float) -> void:
	if not player: return

	# Salud
	health_bar.value = player.health

	# Ammo
	var weapon = player.get_node_or_null("Head/Camera3D/WeaponHolder/Weapon")
	if weapon:
		ammo_label.text = "%d / %d" % [weapon.ammo_in_mag, weapon.ammo_reserve]
		if weapon.is_reloading:
			ammo_label.text = "RECARGANDO..."

	# Inyectar input virtual al player desde el joystick
	player.virtual_move    = left_value
	player.virtual_look    = right_value * LOOK_SENS * delta
	player.virtual_jump    = touch_jump
	player.virtual_sprint  = touch_sprint

	# Resetear right_value cada frame (se acumula solo en drag)
	right_value = Vector2.ZERO

	# Crosshair
	var target_size := 6.0
	if player.is_ads:
		target_size = 0.0
	elif player.velocity.length() > 7.0:
		target_size = 14.0
	crosshair.custom_minimum_size = Vector2.ONE * lerp(
		crosshair.custom_minimum_size.x, target_size, delta * 10.0
	)
	crosshair.queue_redraw()

	# Hit marker timer
	if hit_marker_timer > 0.0:
		hit_marker_timer -= delta
		hit_marker.modulate.a = hit_marker_timer / 0.3
	else:
		hit_marker.modulate.a = 0.0

func show_hit_marker() -> void:
	hit_marker_timer = 0.3
