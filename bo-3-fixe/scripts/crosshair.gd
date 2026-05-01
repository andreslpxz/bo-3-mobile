extends Control

# Crosshair dinámico estilo BO3
# Se dibuja en código, no necesita imágenes

var gap    := 6.0   # espacio en el centro
var length := 10.0  # largo de cada línea
var thick  := 2.0   # grosor

func _draw() -> void:
	var c  := size / 2.0
	var g  := gap
	var l  := length
	var col := Color(1, 1, 1, 0.9)

	# Línea superior
	draw_line(Vector2(c.x, c.y - g), Vector2(c.x, c.y - g - l), col, thick)
	# Línea inferior
	draw_line(Vector2(c.x, c.y + g), Vector2(c.x, c.y + g + l), col, thick)
	# Línea izquierda
	draw_line(Vector2(c.x - g, c.y), Vector2(c.x - g - l, c.y), col, thick)
	# Línea derecha
	draw_line(Vector2(c.x + g, c.y), Vector2(c.x + g + l, c.y), col, thick)
	# Punto central
	draw_circle(c, 1.5, col)
