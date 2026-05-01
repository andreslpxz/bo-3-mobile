extends CharacterBody3D

@onready var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")

@export var hp: float = 150.0
@export var speed: float = 4.0
@export var gravity: float = 20.0

var player: CharacterBody3D

func _ready() -> void:
	add_to_group("enemy")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player:
		var dir = (player.global_position - global_position).normalized()
		# only move horizontally
		dir.y = 0
		dir = dir.normalized()

		velocity.x = dir.x * speed
		velocity.z = dir.z * speed

		# Look at player
		if dir.length_squared() > 0.001:
			var target_pos = player.global_position
			target_pos.y = global_position.y
			look_at(target_pos, Vector3.UP)

	move_and_slide()

func take_damage(amount: float) -> void:
	if hud and hud.has_method("show_hit_marker"):
		hud.show_hit_marker()
	hp -= amount
	# Change color briefly as feedback (optional, but good for testing)
	var mesh = $MeshInstance3D
	if mesh and mesh.get_surface_override_material(0) == null:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.RED
		mesh.set_surface_override_material(0, mat)

	if hp <= 0:
		queue_free()
	if hud and hud.has_method("show_hit_marker"):
		hud.show_hit_marker()
