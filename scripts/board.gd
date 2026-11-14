class_name Board
extends Node2D
## 8x8 grid: logic, ghost preview, line-clear animation.

const N := 8
const CELL := 80.0
const PAD := 3.0

var grid: Array = [] # grid[y][x] -> color index or -1

# Preview state while dragging
var preview_cells: Array[Vector2i] = []
var preview_color := 0
var preview_lines_rows: Array[int] = []
var preview_lines_cols: Array[int] = []

# Animations
var _clearing: Array = [] # {c, color, t, delay}
var _pops := {} # Vector2i -> t (0..1)
var _gray := -1.0 # game over grey-out progress
var _time := 0.0


func _ready() -> void:
	reset()


func reset() -> void:
	grid.clear()
	for y in N:
		var row := []
		row.resize(N)
		row.fill(-1)
		grid.append(row)
	_clearing.clear()
	_pops.clear()
	_gray = -1.0
	clear_preview()


func size_px() -> float:
	return N * CELL


func is_empty() -> bool:
	for y in N:
		for x in N:
			if grid[y][x] != -1:
				return false
	return true


func can_place(cells: Array[Vector2i], at: Vector2i) -> bool:
	for c in cells:
		var p := c + at
		if p.x < 0 or p.y < 0 or p.x >= N or p.y >= N:
			return false
		if grid[p.y][p.x] != -1:
			return false
	return true


func fits_anywhere(cells: Array[Vector2i]) -> bool:
	var b := Shapes.bounds(cells)
	for y in N - b.y + 1:
		for x in N - b.x + 1:
			if can_place(cells, Vector2i(x, y)):
				return true
	return false


## Which rows/cols would be complete if `cells` were placed at `at`.
func lines_if_placed(cells: Array[Vector2i], at: Vector2i) -> Array:
	var filled := {}
	for c in cells:
		filled[c + at] = true
	var rows: Array[int] = []
	var cols: Array[int] = []
	for y in N:
		var full := true
		for x in N:
			if grid[y][x] == -1 and not filled.has(Vector2i(x, y)):
				full = false
				break
		if full:
			rows.append(y)
	for x in N:
		var full := true
		for y in N:
			if grid[y][x] == -1 and not filled.has(Vector2i(x, y)):
				full = false
				break
		if full:
			cols.append(x)
	return [rows, cols]


func set_preview(cells: Array[Vector2i], at: Vector2i, color: int) -> void:
	preview_cells.clear()
	for c in cells:
		preview_cells.append(c + at)
	preview_color = color
	var l := lines_if_placed(cells, at)
	preview_lines_rows = l[0]
	preview_lines_cols = l[1]
	queue_redraw()


func clear_preview() -> void:
	if preview_cells.is_empty() and preview_lines_rows.is_empty() and preview_lines_cols.is_empty():
		return
	preview_cells.clear()
	preview_lines_rows.clear()
	preview_lines_cols.clear()
	queue_redraw()


## Places the piece; returns {"rows": [...], "cols": [...], "cells": [Vector2i...cleared]}.
func place(cells: Array[Vector2i], at: Vector2i, color: int) -> Dictionary:
	for c in cells:
		var p := c + at
		grid[p.y][p.x] = color
		_pops[p] = 0.0
	var none: Array[Vector2i] = []
	var l := lines_if_placed(none, Vector2i.ZERO)
	var rows: Array[int] = l[0]
	var cols: Array[int] = l[1]
	var cleared := {}
	for y in rows:
		for x in N:
			cleared[Vector2i(x, y)] = true
	for x in cols:
		for y in N:
			cleared[Vector2i(x, y)] = true
	# Stagger the clear outward from the placed piece's centre.
	var centre := Vector2.ZERO
	for c in cells:
		centre += Vector2(c + at)
	centre /= cells.size()
	var out: Array[Vector2i] = []
	for p in cleared.keys():
		var d: float = Vector2(p).distance_to(centre)
		_clearing.append({"c": p, "color": grid[p.y][p.x], "t": 0.0, "delay": d * 0.035})
		grid[p.y][p.x] = -1
		out.append(p)
	clear_preview()
	return {"rows": rows, "cols": cols, "cells": out}


func cell_center(c: Vector2i) -> Vector2:
	return position + (Vector2(c) + Vector2(0.5, 0.5)) * CELL


func start_game_over_fade() -> void:
	_gray = 0.0


func _process(delta: float) -> void:
	_time += delta
	var dirty := false
	for k in _pops.keys():
		_pops[k] += delta * 5.0
		if _pops[k] >= 1.0:
			_pops.erase(k)
		dirty = true
	var i := _clearing.size() - 1
	while i >= 0:
		var e: Dictionary = _clearing[i]
		if e.delay > 0.0:
			e.delay -= delta
		else:
			e.t += delta * 2.6
		if e.t >= 1.0:
			_clearing.remove_at(i)
		i -= 1
		dirty = true
	if _gray >= 0.0 and _gray < 1.0:
		_gray = minf(1.0, _gray + delta * 1.2)
		dirty = true
	if not preview_lines_rows.is_empty() or not preview_lines_cols.is_empty():
		dirty = true # pulse
	if dirty:
		queue_redraw()


func _draw() -> void:
	var s := size_px()
	# Board frame
	Shapes.draw_round(self, Rect2(Vector2(-14, -14), Vector2(s + 28, s + 28)), Color("#0a0c1c"), 26)
	Shapes.draw_round(self, Rect2(Vector2(-10, -10), Vector2(s + 20, s + 20)), Color("#1a1f42"), 22)
	# Empty slots
	for y in N:
		for x in N:
			var r := Rect2(Vector2(x, y) * CELL + Vector2(PAD, PAD), Vector2(CELL - PAD * 2, CELL - PAD * 2))
			Shapes.draw_round(self, r, Color("#232a57"), 12)
			Shapes.draw_round(self, Rect2(r.position + Vector2(0, r.size.y * 0.55), Vector2(r.size.x, r.size.y * 0.45)), Color("#20274f"), 12)

	var hl := {}
	for y in preview_lines_rows:
		for x in N:
			hl[Vector2i(x, y)] = true
	for x in preview_lines_cols:
		for y in N:
			hl[Vector2i(x, y)] = true
	var pulse := 0.5 + 0.5 * sin(_time * 10.0)
	for p in hl.keys():
		_draw_glow(p, Shapes.COLORS[preview_color], 0.25 + 0.2 * pulse)

	# Placed blocks
	for y in N:
		for x in N:
			var v: int = grid[y][x]
			if v == -1:
				continue
			var p := Vector2i(x, y)
			var col: Color = Shapes.COLORS[v]
			if hl.has(p):
				col = Shapes.COLORS[preview_color].lightened(0.15 * pulse)
			if _gray >= 0.0:
				var order := float(y * N + x) / float(N * N)
				var g := clampf((_gray - order * 0.6) * 3.0, 0.0, 1.0)
				col = col.lerp(Color("#4a5078"), g)
			var sc := 1.0
			if _pops.has(p):
				var t: float = _pops[p]
				sc = 1.0 + sin(t * PI) * 0.12
			_draw_cell(p, col, sc, 1.0)

	# Ghost of the piece being dragged
	for p in preview_cells:
		if hl.has(p):
			_draw_cell(p, Shapes.COLORS[preview_color].lightened(0.15 * pulse), 1.0, 0.95)
		else:
			_draw_cell(p, Shapes.COLORS[preview_color], 1.0, 0.4)

	# Clearing blocks: flash white, swell, then shrink away
	for e in _clearing:
		if e.delay > 0.0:
			_draw_cell(e.c, Shapes.COLORS[e.color], 1.0, 1.0)
			continue
		var t: float = e.t
		var col: Color = Shapes.COLORS[e.color].lerp(Color.WHITE, clampf(1.0 - t * 2.0, 0.0, 1.0) * 0.8)
		var sc := (1.0 + 0.25 * sin(minf(t * 2.0, 1.0) * PI)) * (1.0 - ease(t, 2.4))
		_draw_cell(e.c, col, sc, 1.0 - t * 0.3)


func _draw_cell(p: Vector2i, col: Color, sc: float, alpha: float) -> void:
	var size := (CELL - PAD * 2) * sc
	var c := (Vector2(p) + Vector2(0.5, 0.5)) * CELL
	Shapes.draw_block(self, Rect2(c - Vector2(size, size) / 2.0, Vector2(size, size)), col, alpha)


func _draw_glow(p: Vector2i, col: Color, a: float) -> void:
	var c := (Vector2(p) + Vector2(0.5, 0.5)) * CELL
	var g := col
	g.a = a * 0.5
	Shapes.draw_round(self, Rect2(c - Vector2(48, 48), Vector2(96, 96)), g, 26)
