extends Node
## Global sound + haptics helper (autoload "Sfx").

const SOUNDS := {
	"pickup": preload("res://assets/sfx/pickup.wav"),
	"place": preload("res://assets/sfx/place.wav"),
	"back": preload("res://assets/sfx/back.wav"),
	"clear": preload("res://assets/sfx/clear.wav"),
	"combo": preload("res://assets/sfx/combo.wav"),
	"perfect": preload("res://assets/sfx/perfect.wav"),
	"gameover": preload("res://assets/sfx/gameover.wav"),
	"click": preload("res://assets/sfx/click.wav"),
	"best": preload("res://assets/sfx/best.wav"),
}

var sound_on := true
var vibration_on := true
var _pool: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)


func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not sound_on or not SOUNDS.has(sound):
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = SOUNDS[sound]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## Pitch for a musical step (semitones) on a pentatonic ladder - used for combos.
func step_pitch(step: int) -> float:
	var ladder := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
	return pow(2.0, ladder[clampi(step, 0, ladder.size() - 1)] / 12.0)


func buzz(ms: int) -> void:
	if vibration_on:
		Input.vibrate_handheld(ms)
