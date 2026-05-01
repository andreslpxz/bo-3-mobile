extends Control

func _draw() -> void:
	var c   := size / 2.0
	var col := Color(1, 0.2, 0.2, modulate.a)
	var s   := 8.0
	# X roja al hacer daño
	draw_line(c - Vector2(s, s), c + Vector2(s, s), col, 2.0)
	draw_line(c + Vector2(-s, s), c + Vector2(s, -s), col, 2.0)

func _process(_delta: float) -> void:
	queue_redraw()
