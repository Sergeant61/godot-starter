extends Node
## Player settings, persisted through Save. Call apply() once after Save.load_data().


func is_muted() -> bool:
	return Save.get_value("muted", false)


func set_muted(value: bool) -> void:
	Save.set_value("muted", value)
	apply()


func apply() -> void:
	AudioServer.set_bus_mute(0, is_muted() or Portal.is_audio_blocked())
