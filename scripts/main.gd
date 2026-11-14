extends Node2D
## Glow Grid - game controller: layout, input, scoring, UI screens, save/resume.

const SAVE_PATH := "user://glowgrid.json"
const PRAISE := ["", "Nice!", "Great!", "Excellent!", "Amazing!", "Incredible!", "LEGENDARY!"]
const PRAISE_COLORS := [Color.WHITE, Color("#5ee07a"), Color("#3ec8ff"), Color("#ffe156"), Color("#ffb347"), Color("#ff5e7e"), Color("#c46bff")]
const COMBO_KEEP := 3 # moves you may make without clearing before the combo breaks

var font: Font = Shapes.font()
var rng := RandomNumberGenerator.new()

# Scene parts
var bg: Node2D
var world: Node2D
var board: Board
var fx: Fx
var tray: Array = [null, null, null] # Piece or null
var slot_centers: Array[Vector2] = []

# UI
var ui: CanvasLayer
var score_label: Label
var best_label: Label
var hint_label: Label
var flash: ColorRect
var menu: Control
var menu_best: Label
var menu_play: Button
var over: Control
var over_score: Label
var over_best: Label
var over_new: Label
var pause: Control
var sound_btn: Button
var vibe_btn: Button
var pause_btn: Button

# State
var score := 0
var shown_score := 0.0
var best := 0
var best_at_start := 0
var combo := 0
var moves_since_clear := 0
var games_played := 0
var playing := false
var is_over := false
var dragging: Piece = null
var drag_lift := 0.0
var shake := 0.0
var view := Vector2(720, 1280)


func _ready() -> void:
	rng.randomize()
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)

	bg = preload("res://scripts/bg.gd").new()
	add_child(bg)
	world = Node2D.new()
	add_child(world)
	board = Board.new()
	world.add_child(board)
	fx = Fx.new()
	fx.z_index = 10

	_build_ui()
	world.add_child(fx)
	_layout()
	get_viewport().size_changed.connect(_layout)

	_load()
	if not _has_resumable():
		_new_state()
	_show_menu()


# ---------------------------------------------------------------- layout

func _layout() -> void:
	view = get_viewport_rect().size
	bg.set_area(view)
	var extra := maxf(0.0, view.y - 1280.0)
	var top := extra * 0.4
	var bx := (view.x - board.size_px()) / 2.0
	board.position = Vector2(bx, top + 250)
	var ty := board.position.y + board.size_px() + 165
	slot_centers = [Vector2(view.x * 0.18, ty), Vector2(view.x * 0.5, ty), Vector2(view.x * 0.82, ty)]
	for i in 3:
		var p: Piece = tray[i]
		if p and p != dragging:
			p.slot_pos = slot_centers[i]
			p.position = p.slot_pos
	if score_label:
		score_label.position = Vector2(0, top + 95)
		score_label.size = Vector2(view.x, 110)
		best_label.position = Vector2(30, top + 40)
		hint_label.position = Vector2(0, ty - 150)
		hint_label.size = Vector2(view.x, 60)
		pause_btn.position = Vector2(view.x - 114, top + 30)


# ---------------------------------------------------------------- UI

func _ls(size: int, col := Color.WHITE, outline := 0) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = outline
	ls.outline_color = Color("#0d0f22")
	return ls


func _label(text: String, size: int, col := Color.WHITE, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.label_settings = _ls(size, col, outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, col: Color, size := Vector2(360, 110), font_size := 48) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", font_size)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col if st != "pressed" else col.darkened(0.2)
		sb.set_corner_radius_all(int(size.y * 0.4))
		sb.border_width_bottom = 8 if st != "pressed" else 3
		sb.border_color = col.darkened(0.4)
		sb.anti_aliasing = true
		if st == "focus":
			sb.draw_center = false
			sb.border_width_bottom = 0
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_color_override("font_outline_color", col.darkened(0.5))
	b.add_theme_constant_override("outline_size", 6)
	b.pressed.connect(func(): Sfx.play("click"); Sfx.buzz(10))
	return b


func _overlay(alpha := 0.82) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.035, 0.09, alpha)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(dim)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	c.add_child(box)
	ui.add_child(c)
	c.visible = false
	return c


func _center(n: Control) -> Control:
	n.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return n


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)

	score_label = _label("0", 96, Color.WHITE, 18)
	score_label.pivot_offset = Vector2(360, 55)
	ui.add_child(score_label)
	best_label = _label("BEST 0", 32, Color("#ffe156"), 8)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui.add_child(best_label)

	hint_label = _label("Drag blocks onto the grid.\nFill a row or column to clear it!", 30, Color(1, 1, 1, 0.75), 6)
	hint_label.visible = false
	ui.add_child(hint_label)

	pause_btn = _button("II", Color("#2c3470"), Vector2(84, 84), 40)
	pause_btn.pressed.connect(_open_pause)
	ui.add_child(pause_btn)

	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)

	# --- Main menu
	menu = _overlay(0.55)
	var mb: VBoxContainer = menu.get_node("Box")
	var title := _label("GLOW\nGRID", 150, Color.WHITE, 26)
	title.label_settings.line_spacing = -40
	mb.add_child(title)
	mb.add_child(_label("the satisfying block puzzle", 34, Color(1, 1, 1, 0.7)))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 80)
	mb.add_child(sp)
	menu_play = _center(_button("PLAY", Color("#5ee07a"), Vector2(380, 130), 60))
	menu_play.pressed.connect(_on_play)
	mb.add_child(menu_play)
	menu_best = _label("BEST 0", 40, Color("#ffe156"), 8)
	mb.add_child(menu_best)

	# --- Game over
	over = _overlay(0.8)
	var ob: VBoxContainer = over.get_node("Box")
	ob.add_child(_label("Out of space!", 64, Color("#ff5e7e"), 14))
	ob.add_child(_label("SCORE", 36, Color(1, 1, 1, 0.6)))
	over_score = _label("0", 130, Color.WHITE, 20)
	ob.add_child(over_score)
	over_new = _label("NEW BEST!", 52, Color("#ffe156"), 12)
	over_new.pivot_offset = Vector2(360, 30)
	ob.add_child(over_new)
	over_best = _label("BEST 0", 40, Color("#ffe156"), 8)
	ob.add_child(over_best)
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 40)
	ob.add_child(sp2)
	var again := _center(_button("PLAY AGAIN", Color("#5ee07a"), Vector2(420, 130), 54))
	again.pressed.connect(func(): over.visible = false; _restart())
	ob.add_child(again)

	# --- Pause
	pause = _overlay(0.85)
	var pb: VBoxContainer = pause.get_node("Box")
	pb.add_child(_label("Paused", 90, Color.WHITE, 16))
	var resume := _center(_button("RESUME", Color("#5ee07a")))
	resume.pressed.connect(func(): pause.visible = false)
	pb.add_child(resume)
	var restart := _center(_button("RESTART", Color("#ffb347")))
	restart.pressed.connect(func(): pause.visible = false; _restart())
	pb.add_child(restart)
	sound_btn = _center(_button("SOUND: ON", Color("#6c7bff")))
	sound_btn.pressed.connect(func(): Sfx.sound_on = not Sfx.sound_on; _refresh_toggles(); _save())
	pb.add_child(sound_btn)
	vibe_btn = _center(_button("VIBRATION: ON", Color("#6c7bff")))
	vibe_btn.pressed.connect(func(): Sfx.vibration_on = not Sfx.vibration_on; _refresh_toggles(); _save())
	pb.add_child(vibe_btn)


func _refresh_toggles() -> void:
	sound_btn.text = "SOUND: " + ("ON" if Sfx.sound_on else "OFF")
	vibe_btn.text = "VIBRATION: " + ("ON" if Sfx.vibration_on else "OFF")


func _show_menu() -> void:
	menu.visible = true
	playing = false
	menu_best.text = "BEST  %d" % best
	menu_play.text = "CONTINUE" if score > 0 else "PLAY"
	var tw := menu_play.create_tween().set_loops()
	menu_play.pivot_offset = menu_play.custom_minimum_size / 2.0
	tw.tween_property(menu_play, "scale", Vector2(1.06, 1.06), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(menu_play, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


func _on_play() -> void:
	menu.visible = false
	playing = true
	best_at_start = best
	hint_label.visible = games_played == 0 and score == 0
	if _tray_empty():
		_deal()
	_update_playable()
	_check_game_over()


func _open_pause() -> void:
	if menu.visible or over.visible:
		return
	_refresh_toggles()
	pause.visible = true


# ---------------------------------------------------------------- game flow

func _new_state() -> void:
	score = 0
	shown_score = 0
	combo = 0
	moves_since_clear = 0
	is_over = false
	board.reset()
	for i in 3:
		if tray[i]:
			tray[i].queue_free()
		tray[i] = null
	_update_score_label(false)


func _restart() -> void:
	_new_state()
	playing = true
	best_at_start = best
	_deal()
	_save()


func _tray_empty() -> bool:
	for p in tray:
		if p:
			return false
	return true


func _deal() -> void:
	var idxs: Array[int] = []
	for attempt in 40:
		idxs.clear()
		for i in 3:
			var idx := Shapes.random_def_index(rng)
			# Gentle mercy: when it doesn't fit, usually try another shape.
			for retry in 6:
				if board.fits_anywhere(Shapes.cells_of(idx)) or rng.randf() < 0.25:
					break
				idx = Shapes.random_def_index(rng)
			idxs.append(idx)
		var any := false
		for idx in idxs:
			if board.fits_anywhere(Shapes.cells_of(idx)):
				any = true
		if any:
			break
	var colors := range(Shapes.COLORS.size())
	colors.shuffle()
	for i in 3:
		_spawn_piece(i, idxs[i], colors[i], true)
	_update_playable()


func _spawn_piece(slot: int, idx: int, col: int, animate: bool) -> void:
	var p := Piece.new()
	p.setup(idx, col)
	p.slot_pos = slot_centers[slot]
	p.scale = Vector2.ONE * Piece.TRAY_SCALE
	world.add_child(p)
	tray[slot] = p
	if animate:
		p.position = p.slot_pos + Vector2(view.x, 0)
		var tw := p.create_tween()
		tw.tween_interval(slot * 0.07)
		tw.tween_property(p, "position", p.slot_pos, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		p.position = p.slot_pos


func _update_playable() -> void:
	for p in tray:
		if p:
			p.playable = board.fits_anywhere(p.cells)


func _check_game_over() -> void:
	if _tray_empty() or is_over:
		return
	for p in tray:
		if p and board.fits_anywhere(p.cells):
			return
	is_over = true
	playing = false
	get_tree().create_timer(0.5).timeout.connect(_game_over)


func _game_over() -> void:
	Sfx.play("gameover")
	Sfx.buzz(120)
	board.start_game_over_fade()
	games_played += 1
	var new_best := score > best_at_start and score > 0
	best = maxi(best, score)
	_clear_game_save()
	await get_tree().create_timer(1.3).timeout
	over_score.text = str(score)
	over_best.text = "BEST  %d" % best
	over_new.visible = new_best
	over.visible = true
	over.modulate.a = 0
	over.create_tween().tween_property(over, "modulate:a", 1.0, 0.3)
	if new_best:
		Sfx.play("best")
		var tw := over_new.create_tween().set_loops()
		tw.tween_property(over_new, "scale", Vector2(1.12, 1.12), 0.4).set_trans(Tween.TRANS_SINE)
		tw.tween_property(over_new, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
		for i in 6:
			fx.sparkle_ring(Vector2(rng.randf_range(100, view.x - 100), rng.randf_range(300, 900)), Shapes.COLORS[i], 20)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if not playing or is_over or pause.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := _to_world(event)
		if event.pressed:
			_try_pick(pos)
		elif dragging:
			_drop()
	elif event is InputEventMouseMotion and dragging:
		_move_drag(_to_world(event))


func _to_world(event: InputEvent) -> Vector2:
	var local: InputEvent = make_input_local(event)
	return local.position - world.position


func _try_pick(pos: Vector2) -> void:
	var best_i := -1
	var best_d := 1e9
	for i in 3:
		var p: Piece = tray[i]
		if p == null:
			continue
		var d := pos.distance_to(p.slot_pos)
		if absf(pos.x - p.slot_pos.x) < view.x / 6.0 and absf(pos.y - p.slot_pos.y) < 140 and d < best_d:
			best_d = d
			best_i = i
	if best_i == -1:
		return
	dragging = tray[best_i]
	drag_lift = dragging.dims.y * Board.CELL / 2.0 + 110
	dragging.z_index = 5
	var tw := dragging.create_tween()
	tw.tween_property(dragging, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)
	Sfx.play("pickup")
	Sfx.buzz(8)
	hint_label.visible = false
	_move_drag(pos)


func _snap_cell(p: Piece) -> Vector2i:
	var tl := p.position - Vector2(p.dims) * Board.CELL / 2.0
	var g := (tl - board.position) / Board.CELL
	return Vector2i(roundi(g.x), roundi(g.y))


func _move_drag(pos: Vector2) -> void:
	dragging.position = pos + Vector2(0, -drag_lift)
	var at := _snap_cell(dragging)
	if board.can_place(dragging.cells, at):
		board.set_preview(dragging.cells, at, dragging.color_idx)
	else:
		board.clear_preview()


func _drop() -> void:
	var p := dragging
	dragging = null
	p.z_index = 0
	var at := _snap_cell(p)
	if board.can_place(p.cells, at):
		_place(p, at)
	else:
		board.clear_preview()
		Sfx.play("back", 1.0, -4.0)
		var tw := p.create_tween().set_parallel(true)
		tw.tween_property(p, "position", p.slot_pos, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "scale", Vector2.ONE * Piece.TRAY_SCALE, 0.22)


# ---------------------------------------------------------------- scoring

func _place(p: Piece, at: Vector2i) -> void:
	var slot := tray.find(p)
	tray[slot] = null
	var centre := board.position + (Vector2(at) + Vector2(p.dims) / 2.0) * Board.CELL
	var result := board.place(p.cells, at, p.color_idx)
	var col: Color = Shapes.COLORS[p.color_idx]
	p.queue_free()

	var lines: int = result.rows.size() + result.cols.size()
	var gained := p.cells.size()
	Sfx.play("place", rng.randf_range(0.95, 1.05))
	Sfx.buzz(15)

	if lines > 0:
		combo += 1
		moves_since_clear = 0
		var line_pts := 10 * lines * (lines + 1) / 2
		gained += line_pts * maxi(1, combo)
		_celebrate(result, lines, col, centre)
	else:
		moves_since_clear += 1
		if moves_since_clear >= COMBO_KEEP:
			combo = 0

	var perfect := lines > 0 and board.is_empty()
	if perfect:
		gained += 300
		get_tree().create_timer(0.35).timeout.connect(_perfect_fx)

	score += gained
	fx.float_text("+%d" % gained, centre + Vector2(0, -40), Color.WHITE, 44 if lines == 0 else 56, 0.2)
	_update_score_label(true)

	if _tray_empty():
		_deal()
	_update_playable()
	_check_game_over()
	if not is_over:
		_save()


func _celebrate(result: Dictionary, lines: int, col: Color, centre: Vector2) -> void:
	Sfx.play("clear", Sfx.step_pitch(combo - 1))
	if lines >= 2:
		Sfx.play("combo", Sfx.step_pitch(lines - 2), -3.0)
	Sfx.buzz(30 + lines * 15)
	shake = minf(6.0 + lines * 5.0 + combo * 1.5, 28.0)
	if lines >= 3:
		_flash(0.18)

	for c in result.cells:
		var d: float = Vector2(c).distance_to((centre - board.position) / Board.CELL)
		var at := board.cell_center(c)
		var cc := col
		get_tree().create_timer(d * 0.035 + 0.05).timeout.connect(func(): fx.burst(at, cc, 5 + lines, 380 + lines * 60))

	var praise_i := mini(lines + (1 if combo >= 3 else 0), PRAISE.size() - 1)
	var mid := board.position + Vector2(board.size_px() / 2.0, board.size_px() * 0.38)
	fx.float_text(PRAISE[praise_i], mid, PRAISE_COLORS[praise_i], 72 + lines * 8, 0.5)
	if combo >= 2:
		fx.float_text("COMBO x%d" % combo, mid + Vector2(0, 100), Color("#ffb347"), 50, 0.5)


func _perfect_fx() -> void:
	Sfx.play("perfect")
	fx.float_text("PERFECT!", board.position + Vector2(320, 260), Color("#ffe156"), 96, 0.9)
	for i in 7:
		fx.sparkle_ring(board.position + Vector2(rng.randf_range(80, 560), rng.randf_range(80, 560)), Shapes.COLORS[i], 22)
	_flash(0.35)
	shake = 22.0


func _flash(a: float) -> void:
	flash.color.a = a
	flash.create_tween().tween_property(flash, "color:a", 0.0, 0.35)


func _update_score_label(punch: bool) -> void:
	best_label.text = "BEST  %d" % maxi(best, score)
	if punch:
		var tw := score_label.create_tween()
		tw.tween_property(score_label, "scale", Vector2(1.18, 1.18), 0.08)
		tw.tween_property(score_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		shown_score = score
		score_label.text = str(score)


func _process(delta: float) -> void:
	if absf(shown_score - score) > 0.01:
		shown_score = move_toward(shown_score, score, maxf(1.0, absf(score - shown_score)) * delta * 8.0)
		score_label.text = str(int(round(shown_score)))
	if shake > 0.1:
		world.position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake
		shake = lerpf(shake, 0.0, delta * 12.0)
	elif world.position != Vector2.ZERO:
		world.position = Vector2.ZERO


# ---------------------------------------------------------------- save / load

func _save() -> void:
	var t := []
	for p in tray:
		t.append([p.def_index, p.color_idx] if p else null)
	var data := {
		"best": maxi(best, score), "games": games_played,
		"sound": Sfx.sound_on, "vibe": Sfx.vibration_on,
		"game": {"score": score, "combo": combo, "since": moves_since_clear, "grid": board.grid, "tray": t},
	}
	if is_over:
		data.erase("game")
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func _clear_game_save() -> void:
	_save() # is_over is true here, so the in-progress game is dropped


var _loaded_game: Dictionary = {}


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	best = int(data.get("best", 0))
	games_played = int(data.get("games", 0))
	Sfx.sound_on = bool(data.get("sound", true))
	Sfx.vibration_on = bool(data.get("vibe", true))
	_loaded_game = data.get("game", {})
	_update_score_label(false)


func _has_resumable() -> bool:
	var g := _loaded_game
	if g.is_empty() or not g.has("grid") or g.grid.size() != Board.N:
		return false
	board.reset()
	for y in Board.N:
		for x in Board.N:
			board.grid[y][x] = int(g.grid[y][x])
	score = int(g.score)
	shown_score = score
	combo = int(g.combo)
	moves_since_clear = int(g.since)
	for i in 3:
		var e = g.tray[i] if i < g.tray.size() else null
		if e != null and int(e[0]) < Shapes.DEFS.size():
			_spawn_piece(i, int(e[0]), int(e[1]) % Shapes.COLORS.size(), false)
	board.queue_redraw()
	_update_score_label(false)
	return true


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if playing:
				_save()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if pause.visible:
				pause.visible = false
			elif menu.visible:
				_save()
				get_tree().quit()
			elif over.visible:
				over.visible = false
				_restart()
			else:
				_open_pause()
		NOTIFICATION_WM_CLOSE_REQUEST:
			if playing:
				_save()
			get_tree().quit()
