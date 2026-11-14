class_name Shapes
## Piece definitions, palette and block drawing shared by board + pieces.

const COLORS: Array[Color] = [
	Color("#ff5e7e"), # pink
	Color("#ffb347"), # orange
	Color("#ffe156"), # yellow
	Color("#5ee07a"), # green
	Color("#3ec8ff"), # cyan
	Color("#6c7bff"), # blue
	Color("#c46bff"), # purple
]

# [weight, cells]
const DEFS := [
	[3, [Vector2i(0, 0)]],
	[4, [Vector2i(0, 0), Vector2i(1, 0)]],
	[4, [Vector2i(0, 0), Vector2i(0, 1)]],
	[5, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]],
	[5, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]],
	[4, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]],
	[4, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]],
	[2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]],
	[2, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)]],
	[6, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]],
	[2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]],
	[3, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]],
	[3, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]],
	# small corners
	[3, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]],
	[3, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]],
	[3, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]],
	[3, [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]],
	# L shapes
	[2, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]],
	[2, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)]],
	[2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1)]],
	[2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]],
	[2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2)]],
	[2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]],
	[2, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]],
	[2, [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]],
	# big corners
	[1, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(0, 2)]],
	[1, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]],
	[1, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]],
	[1, [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(1, 2), Vector2i(0, 2)]],
	# T shapes
	[2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]],
	[2, [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]],
	[2, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1)]],
	[2, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 1)]],
	# S / Z
	[2, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]],
	[2, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]],
	[2, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]],
	[2, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(0, 2)]],
]

static var _style_cache := {}
static var _font: FontVariation


## Fredoka at a chunky weight (the bundled file is a variable font).
static func font() -> Font:
	if _font == null:
		_font = FontVariation.new()
		_font.base_font = load("res://assets/fonts/Fredoka.ttf")
		var ts := TextServerManager.get_primary_interface()
		_font.variation_opentype = {ts.name_to_tag("wght"): 620}
	return _font


static func random_def_index(rng: RandomNumberGenerator) -> int:
	var total := 0
	for d in DEFS:
		total += d[0]
	var r := rng.randi_range(0, total - 1)
	for i in DEFS.size():
		r -= DEFS[i][0]
		if r < 0:
			return i
	return 0


static func cells_of(idx: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in DEFS[idx][1]:
		out.append(c)
	return out


static func bounds(cells: Array[Vector2i]) -> Vector2i:
	var b := Vector2i.ZERO
	for c in cells:
		b.x = maxi(b.x, c.x + 1)
		b.y = maxi(b.y, c.y + 1)
	return b


## Draws one glossy block filling `r`. Alpha is quantised so style boxes cache well.
static func draw_block(ci: CanvasItem, r: Rect2, color: Color, alpha := 1.0) -> void:
	if r.size.x < 2.0 or alpha <= 0.01:
		return
	var a := snappedf(clampf(alpha, 0.0, 1.0), 0.05)
	var rad := r.size.x * 0.18
	_draw_flat(ci, r, color.darkened(0.35), rad, a)
	_draw_flat(ci, Rect2(r.position, Vector2(r.size.x, r.size.y * 0.88)), color, rad, a)
	_draw_flat(ci, Rect2(r.position + Vector2(r.size.x * 0.12, r.size.y * 0.08), Vector2(r.size.x * 0.76, r.size.y * 0.22)), Color(1, 1, 1, 0.28), rad * 0.6, a)


static func _draw_flat(ci: CanvasItem, r: Rect2, color: Color, rad: float, alpha: float) -> void:
	var c := color
	c.a *= alpha
	var key := "%s_%d" % [c.to_html(), int(rad)]
	var sb: StyleBoxFlat = _style_cache.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = c
		sb.set_corner_radius_all(int(rad))
		sb.anti_aliasing = true
		if _style_cache.size() > 3000:
			_style_cache.clear()
		_style_cache[key] = sb
	sb.draw(ci.get_canvas_item(), r)


## Plain rounded rectangle helper.
static func draw_round(ci: CanvasItem, r: Rect2, color: Color, rad: float) -> void:
	_draw_flat(ci, r, color, rad, 1.0)
