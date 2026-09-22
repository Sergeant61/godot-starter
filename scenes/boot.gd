extends Control
## First scene: starts the portal SDK and loads save data, then opens the main menu.
##
## Nothing may write to the save before load_data: Save writes the whole file on every set, so a
## write from an autoload's _ready lands a file holding that one key over the player's progress.


func _ready() -> void:
	await Portal.init()
	Save.load_data()
	Ads.reload()
	Settings.apply()
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
