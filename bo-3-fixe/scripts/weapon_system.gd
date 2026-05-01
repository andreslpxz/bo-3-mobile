extends Node3D

# ─── Stats del arma ────────────────────────────────────────
@export var damage: float        = 25.0
@export var fire_rate: float     = 0.09
@export var mag_size: int        = 30
@export var reload_time: float   = 2.0
@export var bullet_spread: float = 0.015
@export var ads_spread: float    = 0.002

var ammo_in_mag: int    = 30
var ammo_reserve: int   = 210
var can_shoot: bool     = true
var is_reloading: bool  = false
var shoot_timer: float  = 0.0
var virtual_shoot: bool = false

# Rutas

@onready var shoot_sound: AudioStreamPlayer3D = $ShootSound
@onready var reload_sound: AudioStreamPlayer3D = $ReloadSound

@onready var camera: Camera3D        = $"../../../Camera3D"
@onready var player: CharacterBody3D = $"../../../../"

func _process(delta: float) -> void:
	shoot_timer = max(0.0, shoot_timer - delta)

	if (Input.is_action_pressed("shoot") or virtual_shoot) and can_shoot \
	and not is_reloading and ammo_in_mag > 0:
		_shoot()

	if Input.is_action_just_pressed("reload") \
	and not is_reloading and ammo_in_mag < mag_size and ammo_reserve > 0:
		_start_reload()

	if ammo_in_mag == 0 and ammo_reserve > 0 and not is_reloading:
		_start_reload()


func _shoot() -> void:
	if shoot_timer > 0.0:
		return

	shoot_timer = fire_rate
	ammo_in_mag -= 1
	shoot_sound.play()


	var spread: float = ads_spread if player.is_ads else bullet_spread

	var ray_dir: Vector3 = -camera.global_transform.basis.z
	ray_dir += Vector3(
		randf_range(-spread, spread),
		randf_range(-spread, spread),
		0.0
	)
	ray_dir = ray_dir.normalized()

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		camera.global_position,
		camera.global_position + ray_dir * 500.0
	)
	query.exclude = [player]

	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if not result.is_empty():
		var collider = result.get("collider")
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage)

	_play_shoot_effects()


func _start_reload() -> void:
	is_reloading = true
	can_shoot = false
	reload_sound.play()


	await get_tree().create_timer(reload_time).timeout

	var needed: int = mag_size - ammo_in_mag
	var loaded: int = min(needed, ammo_reserve)

	ammo_in_mag += loaded
	ammo_reserve -= loaded

	is_reloading = false
	can_shoot = true


func _play_shoot_effects() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:z", 0.05, 0.04)
	tween.tween_property(self, "position:z", 0.0,  0.08)