extends Node
## Dev-only: plays the game automatically and saves screenshots to user://shots.

var main: Node
var t := 0.0
var step := 0
var shots := 0

func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	DirAccess.make_dir_recursive_absolute("user://shots")

func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shots/%s.png" % name)
	print("shot ", name, " score=", main.score, " combo=", main.combo)

func _process(delta: float) -> void:
	t += delta
	if step == 0 and t > 1.0:
		_shot("00_menu")
		main._on_play()
		step = 1
		t = 0
	elif step >= 1 and t > 0.45 and not main.is_over:
		t = 0
		step += 1
		var moved := false
		# simple greedy bot: pick move that clears most lines
		var best_score := -1
		var best_move = null
		for p in main.tray:
			if p == null: continue
			for y in Board.N:
				for x in Board.N:
					var at := Vector2i(x, y)
					if main.board.can_place(p.cells, at):
						var l = main.board.lines_if_placed(p.cells, at)
						var s: int = (l[0].size() + l[1].size()) * 100 + y * 2 + randi() % 3
						if s > best_score:
							best_score = s
							best_move = [p, at]
		if best_move:
			if step == 6:
				# show a drag preview mid-air
				var p: Piece = best_move[0]
				main.dragging = p
				p.scale = Vector2.ONE
				p.position = main.board.position + (Vector2(best_move[1]) + Vector2(p.dims) / 2.0) * Board.CELL
				main.board.set_preview(p.cells, best_move[1], p.color_idx)
				await get_tree().create_timer(0.2).timeout
				_shot("01_drag_preview")
				main.dragging = null
			main._place(best_move[0], best_move[1])
			if best_score >= 100 and shots < 4:
				shots += 1
				await get_tree().create_timer(0.12).timeout
				_shot("02_clear_%d" % shots)
	elif main.is_over and step > 0 and step < 1000:
		step = 1000
		await get_tree().create_timer(2.5).timeout
		_shot("03_gameover")
		get_tree().quit()
	if step == 40:
		_shot("04_midgame")
		step += 1
