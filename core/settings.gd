extends Node
## Player settings, persisted through Save. Call apply() once after Save.load_data().
##
## Music and sound effects switch off separately - plenty of players keep the game's sounds and put
## their own music on. The phone's rumble and the screen shake switch off too: shake this heavy is
## a real problem for some people, and rumble eats battery. Everything is on by default. Each has its own audio bus, made here at startup so no scene needs a bus
## layout file: Music takes the song, SFX every effect. The master bus is only muted while a portal
## ad plays or the portal asks for silence.

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"


func _ready() -> void:
	for bus: StringName in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")


func is_music_on() -> bool:
	return not Save.get_value("music_off", false)


func is_sfx_on() -> bool:
	return not Save.get_value("sfx_off", false)


func toggle_music() -> void:
	Save.set_value("music_off", is_music_on())
	apply()


func toggle_sfx() -> void:
	Save.set_value("sfx_off", is_sfx_on())
	apply()


func is_rumble_on() -> bool:
	return not Save.get_value("rumble_off", false)


func toggle_rumble() -> void:
	Save.set_value("rumble_off", is_rumble_on())


func is_shake_on() -> bool:
	return not Save.get_value("shake_off", false)


func toggle_shake() -> void:
	Save.set_value("shake_off", is_shake_on())


## A short buzz, if the player wants one and the device has one. Desktop and the web build have no
## handheld motor, and Godot simply ignores it there.
func rumble(msec: int) -> void:
	if is_rumble_on():
		Input.vibrate_handheld(msec)


func music_label() -> String:
	return "Music: On" if is_music_on() else "Music: Off"


func sfx_label() -> String:
	return "Sounds: On" if is_sfx_on() else "Sounds: Off"


func rumble_label() -> String:
	return "Rumble: On" if is_rumble_on() else "Rumble: Off"


func shake_label() -> String:
	return "Screen shake: On" if is_shake_on() else "Screen shake: Off"


func apply() -> void:
	AudioServer.set_bus_mute(0, Portal.is_audio_blocked())
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS), not is_music_on())
	AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS), not is_sfx_on())
