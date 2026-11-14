class_name Fx
extends Node2D
## Lightweight particle bursts + floating text.

var _parts: Array = [] # {p, v, life, max, col, size, spin, rot}
var _font: Font = Shapes.font()


func burst(at: Vector2, col: Color, count := 10, power := 420.0) -> void:
	for i in count:
		var ang := randf() * TAU
		var spd := randf_range(0.3, 1.0) * power
		var life := randf_range(0.45, 0.9)
		_parts.append({
			"p": at + Vector2(randf_range(-20, 20), randf_range(-20, 20)),
			"v": Vector2(cos(ang), sin(ang)) * spd + Vector2(0, -160),
			"life": life, "max": life,
			"col": col.lerp(Color.WHITE, randf() * 0.4),
			"size": randf_range(8, 20),
			"rot": randf() * TAU, "spin": randf_range(-10, 10),
		})


func sparkle_ring(at: Vector2, col: Color, count := 24, radius := 60.0) -> void:
	for i in count:
		var ang := TAU * i / count
		_parts.append({
			"p": at + Vector2(cos(ang), sin(ang)) * radius * 0.3,
			"v": Vector2(cos(ang), sin(ang)) * randf_range(500, 750),
			"life": 0.6, "max": 0.6, "col": col.lerp(Color.WHITE, 0.3),
			"size": randf_range(6, 12), "rot": ang, "spin": 0.0,
		})


## Floating text that pops in, drifts up and fades.
func float_text(text: String, at: Vector2, col: Color, size := 56, hold := 0.6) -> void:
	var lbl := Label.new()
	var ls := LabelSettings.new()
	ls.font = _font
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = int(size * 0.22)
	ls.outline_color = Color("#0d0f22")
	ls.shadow_size = 0
	ls.shadow_color = Color(0, 0, 0, 0.35)
	ls.shadow_offset = Vector2(0, 6)
	lbl.label_settings = ls
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	lbl.reset_size()
	lbl.pivot_offset = lbl.size / 2.0
	lbl.position = at - lbl.size / 2.0
	lbl.scale = Vector2(0.2, 0.2)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 90, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(lbl.queue_free)


func _process(delta: float) -> void:
	if _parts.is_empty():
		return
	var i := _parts.size() - 1
	while i >= 0:
		var e: Dictionary = _parts[i]
		e.life -= delta
		if e.life <= 0.0:
			_parts.remove_at(i)
		else:
			e.v += Vector2(0, 1100) * delta
			e.v *= 1.0 - 1.5 * delta
			e.p += e.v * delta
			e.rot += e.spin * delta
		i -= 1
	queue_redraw()


func _draw() -> void:
	for e in _parts:
		var k: float = e.life / e.max
		var s: float = e.size * (0.4 + 0.6 * k)
		var c: Color = e.col
		c.a = clampf(k * 1.6, 0.0, 1.0)
		draw_set_transform(e.p, e.rot)
		draw_rect(Rect2(-s / 2, -s / 2, s, s), c)
	draw_set_transform(Vector2.ZERO)
