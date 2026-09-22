extends Control


func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_pressed)
	%MusicButton.pressed.connect(_on_music_pressed)
	%SfxButton.pressed.connect(_on_sfx_pressed)
	_refresh()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_music_pressed() -> void:
	Settings.toggle_music()
	_refresh()


func _on_sfx_pressed() -> void:
	Settings.toggle_sfx()
	_refresh()


func _refresh() -> void:
	%CoinsLabel.text = "Coins: %d" % Progress.get_coins()
	%MusicButton.text = Settings.music_label()
	%SfxButton.text = Settings.sfx_label()
