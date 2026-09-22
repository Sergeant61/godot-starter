extends Control
## Placeholder game: tap as often as you can in 10 seconds.
## Replace this scene with the real game; keep the Portal.gameplay_start/stop and Ads.start_run
## calls and hand the result to GameOver.

const ROUND_SECONDS := 10.0

var _score := 0
var _time_left := 0.0
var _running := false

@onready var _game_over: GameOver = %GameOver


func _ready() -> void:
	%TapButton.pressed.connect(_on_tap_pressed)
	_game_over.retry_pressed.connect(_start)
	_game_over.menu_pressed.connect(_on_menu_pressed)
	_start()


func _process(delta: float) -> void:
	if not _running:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_finish()
	_update_label()


func _start() -> void:
	_score = 0
	_time_left = ROUND_SECONDS
	_running = true
	%TapButton.disabled = false
	_game_over.hide()
	Ads.start_run()
	Portal.gameplay_start()


func _finish() -> void:
	_running = false
	_time_left = 0.0
	%TapButton.disabled = true
	Portal.gameplay_stop()
	_game_over.show_result(_score)


func _on_tap_pressed() -> void:
	_score += 1


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _update_label() -> void:
	%InfoLabel.text = "Time: %.1f   Score: %d" % [_time_left, _score]
