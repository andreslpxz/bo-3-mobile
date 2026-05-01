extends CharacterBody3D

# ─── Velocidades ───────────────────────────────────────────
const WALK_SPEED         := 6.0
const SPRINT_SPEED       := 10.0
const SLIDE_SPEED        := 14.0
const JUMP_VELOCITY      := 6.5
const GRAVITY            := 20.0
const MOUSE_SENS         := 0.002

# ─── Doble salto ───────────────────────────────────────────
const MAX_JUMPS          := 2
var jumps_left           := MAX_JUMPS

# ─── Slide ─────────────────────────────────────────────────
var is_sliding           := false
var slide_timer          := 0.0
const SLIDE_DURATION     := 0.9
const SLIDE_COOLDOWN     := 0.5
var slide_cooldown_timer := 0.0

# ─── Wall run ──────────────────────────────────────────────
var is_wall_running      := false
var wall_run_timer       := 0.0
const WALL_RUN_DURATION  := 1.8
const WALL_RUN_SPEED     := 9.0

# ─── ADS ───────────────────────────────────────────────────
var is_ads               := false
const ADS_FOV            := 60.0
const HIP_FOV            := 90.0
const ADS_SPEED_MULT     := 0.6

# ─── Cámara ────────────────────────────────────────────────
var camera_tilt          := 0.0
const CAMERA_TILT_SPEED  := 8.0
const SLIDE_TILT_AMOUNT  := 6.0
const WALL_TILT_AMOUNT   := 5.0

# ─── Salud ─────────────────────────────────────────────────
var health               := 100.0
const MAX_HEALTH         := 100.0
const REGEN_DELAY        := 4.0
const REGEN_RATE         := 25.0
var regen_timer          := 0.0

# ─── Input virtual (joystick táctil) ──────────────────────
var virtual_move   := Vector2.ZERO
var virtual_look   := Vector2.ZERO
var virtual_jump   := false
var virtual_sprint := false

@onready var head: Node3D                  = $Head
@onready var camera: Camera3D              = $Head/Camera3D
@onready var collision: CollisionShape3D   = $CollisionShape3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.fov = HIP_FOV
	add_to_group("player")
	# Posición correcta del head (altura de ojos)
	head.position.y = 0.7

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	# Liberar mouse con Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _apply_virtual_look() -> void:
	if virtual_look == Vector2.ZERO: return
	rotate_y(-virtual_look.x * MOUSE_SENS * 60.0)
	head.rotate_x(-virtual_look.y * MOUSE_SENS * 60.0)
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	_apply_virtual_look()
	_handle_gravity(delta)
	_handle_wall_run(delta)
	_handle_movement(delta)
	_handle_jump()
	_handle_slide(delta)
	_handle_ads(delta)
	_handle_camera_tilt(delta)
	_handle_health_regen(delta)
	move_and_slide()

# ─── Gravedad ──────────────────────────────────────────────
func _handle_gravity(delta: float) -> void:
	if is_wall_running:
		velocity.y = lerp(velocity.y, -1.0, delta * 3.0)
	elif not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		jumps_left = MAX_JUMPS

# ─── Movimiento ────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	if is_sliding: return
	var dir := Vector3.ZERO
	# Input teclado
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	# Input joystick virtual (se combina con teclado)
	if virtual_move.length() > 0.1:
		dir += transform.basis.z * virtual_move.y
		dir += transform.basis.x * virtual_move.x
	dir = dir.normalized()
	var speed := WALK_SPEED
	if Input.is_action_pressed("sprint") or virtual_sprint: speed = SPRINT_SPEED
	if is_ads:                                               speed *= ADS_SPEED_MULT
	velocity.x = lerp(velocity.x, dir.x * speed, delta * 12.0)
	velocity.z = lerp(velocity.z, dir.z * speed, delta * 12.0)

# ─── Doble salto ───────────────────────────────────────────
func _handle_jump() -> void:
	if (Input.is_action_just_pressed("jump") or virtual_jump) and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		is_sliding = false
		virtual_jump = false  # consumir el tap

# ─── Slide ─────────────────────────────────────────────────
func _handle_slide(delta: float) -> void:
	slide_cooldown_timer = max(0.0, slide_cooldown_timer - delta)
	if is_sliding:
		slide_timer -= delta
		var slide_dir := -transform.basis.z
		velocity.x = lerp(velocity.x, slide_dir.x * SLIDE_SPEED, delta * 5.0)
		velocity.z = lerp(velocity.z, slide_dir.z * SLIDE_SPEED, delta * 5.0)
		if slide_timer <= 0.0 or not Input.is_action_pressed("crouch"):
			_end_slide()
		return
	if Input.is_action_just_pressed("crouch") \
	and Input.is_action_pressed("sprint") \
	and is_on_floor() \
	and slide_cooldown_timer <= 0.0:
		_start_slide()

func _start_slide() -> void:
	is_sliding = true
	slide_timer = SLIDE_DURATION
	var tween := create_tween()
	tween.tween_property(head, "position:y", 0.2, 0.15)

func _end_slide() -> void:
	is_sliding = false
	slide_cooldown_timer = SLIDE_COOLDOWN
	var tween := create_tween()
	tween.tween_property(head, "position:y", 0.7, 0.2)

# ─── Wall Run ──────────────────────────────────────────────
func _handle_wall_run(delta: float) -> void:
	if is_on_floor():
		is_wall_running = false
		return
	var left_normal  := _cast_wall(-transform.basis.x)
	var right_normal := _cast_wall(transform.basis.x)
	if (left_normal != Vector3.ZERO or right_normal != Vector3.ZERO) \
	and Input.is_action_pressed("move_forward"):
		if not is_wall_running:
			is_wall_running = true
			wall_run_timer = WALL_RUN_DURATION
			jumps_left = MAX_JUMPS
		wall_run_timer -= delta
		if wall_run_timer <= 0.0:
			is_wall_running = false
			return
		velocity.x = lerp(velocity.x, -transform.basis.z.x * WALL_RUN_SPEED, delta * 10.0)
		velocity.z = lerp(velocity.z, -transform.basis.z.z * WALL_RUN_SPEED, delta * 10.0)
		if Input.is_action_just_pressed("jump"):
			var wall_n := left_normal if left_normal != Vector3.ZERO else right_normal
			velocity = wall_n * 5.0 + Vector3.UP * JUMP_VELOCITY
			is_wall_running = false
	else:
		is_wall_running = false

func _cast_wall(dir: Vector3) -> Vector3:
	var space  := get_world_3d().direct_space_state
	var origin := global_position
	var query  := PhysicsRayQueryParameters3D.create(origin, origin + dir * 0.65)
	query.exclude = [self]
	var result := space.intersect_ray(query)
	if result and result.normal.y < 0.3:
		return result.normal
	return Vector3.ZERO

# ─── ADS ───────────────────────────────────────────────────
func _handle_ads(delta: float) -> void:
	is_ads = Input.is_action_pressed("ads")
	var target_fov := ADS_FOV if is_ads else HIP_FOV
	camera.fov = lerp(camera.fov, target_fov, delta * 12.0)

# ─── Camera tilt ───────────────────────────────────────────
func _handle_camera_tilt(delta: float) -> void:
	var target_tilt := 0.0
	if is_sliding:
		target_tilt = -SLIDE_TILT_AMOUNT
	elif is_wall_running:
		var left := _cast_wall(-transform.basis.x)
		target_tilt = WALL_TILT_AMOUNT if left != Vector3.ZERO else -WALL_TILT_AMOUNT
	camera_tilt = lerp(camera_tilt, target_tilt, delta * CAMERA_TILT_SPEED)
	camera.rotation.z = deg_to_rad(camera_tilt)

# ─── Regen salud ───────────────────────────────────────────
func _handle_health_regen(delta: float) -> void:
	if health >= MAX_HEALTH: return
	regen_timer += delta
	if regen_timer >= REGEN_DELAY:
		health = min(health + REGEN_RATE * delta, MAX_HEALTH)

func take_damage(amount: float) -> void:
	health -= amount
	regen_timer = 0.0
	if health <= 0.0:
		_die()

func _die() -> void:
	health = MAX_HEALTH
	global_position = Vector3(0, 2, 0)
