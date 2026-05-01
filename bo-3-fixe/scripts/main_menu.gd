extends Control

@onready var main_panel = $MainPanel
@onready var settings_panel = $SettingsPanel

# Settings UI
@onready var fov_slider = $SettingsPanel/VBox/FovSlider
@onready var fov_label = $SettingsPanel/VBox/FovLabel
@onready var sens_slider = $SettingsPanel/VBox/SensSlider
@onready var sens_label = $SettingsPanel/VBox/SensLabel
@onready var vol_slider = $SettingsPanel/VBox/VolSlider
@onready var vol_label = $SettingsPanel/VBox/VolLabel
@onready var graphics_option = $SettingsPanel/VBox/GraphicsOption

func _ready():
	settings_panel.hide()
	main_panel.show()

	# Inicializar UI con los valores de Global
	fov_slider.value = Global.fov
	fov_label.text = "FOV: " + str(int(Global.fov))

	sens_slider.value = Global.sensitivity * 1000.0 # Multiplicado para que sea legible (ej 0.002 -> 2.0)
	sens_label.text = "Sensibilidad: " + str(Global.sensitivity)

	vol_slider.value = Global.volume_db
	vol_label.text = "Volumen (dB): " + str(int(Global.volume_db))

	graphics_option.selected = Global.graphics_quality

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_pressed():
	main_panel.hide()
	settings_panel.show()

func _on_back_pressed():
	settings_panel.hide()
	main_panel.show()
	Global.apply_settings()

func _on_fov_slider_value_changed(value):
	Global.fov = value
	fov_label.text = "FOV: " + str(int(value))

func _on_sens_slider_value_changed(value):
	Global.sensitivity = value / 1000.0
	sens_label.text = "Sensibilidad: " + str(Global.sensitivity)

func _on_vol_slider_value_changed(value):
	Global.volume_db = value
	vol_label.text = "Volumen (dB): " + str(int(value))
	Global.apply_settings()

func _on_graphics_option_item_selected(index):
	Global.graphics_quality = index
	Global.apply_settings()
