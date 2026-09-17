extends Control
## First scene: starts the portal SDK and loads save data, then opens the main menu.


func _ready() -> void:
	await Portal.init()
	Save.load_data()
	Settings.apply()
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
