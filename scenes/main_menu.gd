extends Control


func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_pressed)
	%MuteButton.pressed.connect(_on_mute_pressed)
	_refresh()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_mute_pressed() -> void:
	Settings.set_muted(not Settings.is_muted())
	_refresh()


func _refresh() -> void:
	%CoinsLabel.text = "Coins: %d" % Progress.get_coins()
	%MuteButton.text = "Sound: Off" if Settings.is_muted() else "Sound: On"
