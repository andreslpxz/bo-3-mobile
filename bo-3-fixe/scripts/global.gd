extends Node

var fov: float = 90.0
var sensitivity: float = 0.002
var volume_db: float = 0.0
var graphics_quality: int = 1 # 0: Low, 1: Medium, 2: High

func apply_settings():
	# Aplicar volumen (asumiendo que el bus principal se llama "Master")
	var bus_index = AudioServer.get_bus_index("Master")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, volume_db)

	# Aplicar calidad gráfica
	if graphics_quality == 0:
		# Low
		get_viewport().scaling_3d_scale = 0.5
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	elif graphics_quality == 1:
		# Medium
		get_viewport().scaling_3d_scale = 0.75
		get_viewport().msaa_3d = Viewport.MSAA_2X
	else:
		# High
		get_viewport().scaling_3d_scale = 1.0
		get_viewport().msaa_3d = Viewport.MSAA_4X

func _ready():
	apply_settings()
