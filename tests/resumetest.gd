extends Node
func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var pieces := 0
	for p in main.tray: if p: pieces += 1
	print("RESUME score=", main.score, " button=", main.menu_play.text, " tray=", pieces)
	get_tree().quit()
