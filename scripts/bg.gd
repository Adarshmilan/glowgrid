extends Node2D
## Calm animated backdrop: vertical gradient + slowly drifting glowing orbs.

var _orbs: Array = []
var _size := Vector2(720, 1280)
var _grad_tex: GradientTexture2D


func _ready() -> void:
	var g := Gradient.new()
	g.set_color(0, Color("#1b1f4a"))
	g.set_color(1, Color("#0b0c1e"))
	_grad_tex = GradientTexture2D.new()
	_grad_tex.gradient = g
	_grad_tex.fill_from = Vector2(0.5, 0)
	_grad_tex.fill_to = Vector2(0.5, 1)
	_grad_tex.width = 8
	_grad_tex.height = 256
	for i in 14:
		_orbs.append({
			"p": Vector2(randf() * 720, randf() * 1600),
			"r": randf_range(30, 120),
			"v": randf_range(8, 25),
			"col": Shapes.COLORS[randi() % Shapes.COLORS.size()],
			"ph": randf() * TAU,
		})


func set_area(s: Vector2) -> void:
	_size = s
	queue_redraw()


func _process(delta: float) -> void:
	for o in _orbs:
		o.p.y -= o.v * delta
		o.ph += delta * 0.6
		if o.p.y < -o.r * 2:
			o.p.y = _size.y + o.r * 2
			o.p.x = randf() * _size.x
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(_grad_tex, Rect2(Vector2(-40, -40), _size + Vector2(80, 80)), false)
	for o in _orbs:
		var c: Color = o.col
		var x: float = o.p.x + sin(o.ph) * 20.0
		for k in 4:
			c.a = 0.018 + k * 0.008
			draw_circle(Vector2(x, o.p.y), o.r * (1.0 - k * 0.22), c)
