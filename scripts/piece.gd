class_name Piece
extends Node2D
## A draggable piece sitting in the tray. Node position = visual centre.

const TRAY_SCALE := 0.55

var cells: Array[Vector2i] = []
var def_index := 0
var color_idx := 0
var dims := Vector2i.ONE
var slot_pos := Vector2.ZERO
var playable := true:
	set(v):
		playable = v
		queue_redraw()


func setup(idx: int, col: int) -> void:
	def_index = idx
	cells = Shapes.cells_of(idx)
	color_idx = col
	dims = Shapes.bounds(cells)
	queue_redraw()


## Top-left corner of the piece in parent space (at current scale).
func top_left() -> Vector2:
	return position - Vector2(dims) * Board.CELL * scale.x / 2.0


func _draw() -> void:
	var off := -Vector2(dims) * Board.CELL / 2.0
	var col: Color = Shapes.COLORS[color_idx] if playable else Color("#3b4170")
	for c in cells:
		var r := Rect2(off + Vector2(c) * Board.CELL + Vector2(Board.PAD, Board.PAD), Vector2(Board.CELL - Board.PAD * 2, Board.CELL - Board.PAD * 2))
		Shapes.draw_block(self, r, col, 1.0)
