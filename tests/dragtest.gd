extends Node
## Dev-only: verifies real pointer drag & drop places a piece.
var main: Node

func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.5).timeout
	main._on_play()
	await get_tree().create_timer(0.8).timeout
	var p: Piece = main.tray[0]
	var xf: Transform2D = get_viewport().get_final_transform() * get_viewport().canvas_transform
	var start: Vector2 = xf * p.slot_pos
	# target: piece top-left at cell (0,0)
	var target_center: Vector2 = main.board.position + Vector2(p.dims) * Board.CELL / 2.0
	var lift: float = p.dims.y * Board.CELL / 2.0 + 110
	var finger: Vector2 = xf * (target_center + Vector2(0, lift))
	_send_btn(start, true)
	for i in 10:
		await get_tree().process_frame
		_send_motion(start.lerp(finger, (i + 1) / 10.0))
	await get_tree().process_frame
	var preview_ok: bool = not main.board.preview_cells.is_empty()
	_send_btn(finger, false)
	await get_tree().create_timer(0.3).timeout
	var placed := 0
	for y in Board.N:
		for x in Board.N:
			if main.board.grid[y][x] != -1: placed += 1
	print("DRAGTEST preview=", preview_ok, " placed_cells=", placed, " tray0=", main.tray[0], " score=", main.score)
	get_tree().quit()

func _send_btn(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)

func _send_motion(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)
