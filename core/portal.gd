extends Node
## Bridge to the web game portal (CrazyGames SDK v3).
## Outside a CrazyGames page (editor, desktop, other hosts) every call is a safe no-op,
## so game code never has to check where it runs.

signal _promise_settled
signal _ad_done(watched: bool)

var _sdk: JavaScriptObject
var _in_gameplay := false
var _ad_showing := false
var _portal_muted := false
# JavaScript callbacks must stay referenced while JavaScript can still call them.
var _settings_listener: JavaScriptObject
var _ad_callbacks: Array[JavaScriptObject] = []


## Call once at startup. The SDK script is added to the page by the Web export preset.
func init() -> void:
	if not OS.has_feature("web") or not JavaScriptBridge.eval("typeof window.CrazyGames !== 'undefined'", true):
		return
	var sdk: JavaScriptObject = JavaScriptBridge.get_interface("CrazyGames").SDK
	var on_settled := JavaScriptBridge.create_callback(func(_args: Array) -> void: _promise_settled.emit())
	sdk.init().then(on_settled, on_settled)
	await _promise_settled
	# "local" on localhost (demo ads), "crazygames" on their site, "disabled" anywhere else.
	if sdk.environment == "disabled":
		return
	_sdk = sdk
	_portal_muted = bool(sdk.game.settings.muteAudio)
	_settings_listener = JavaScriptBridge.create_callback(_on_portal_settings_changed)
	sdk.game.addSettingsChangeListener(_settings_listener)


## Call when the player starts or resumes playing (level start, unpause, revive).
func gameplay_start() -> void:
	if _in_gameplay:
		return
	_in_gameplay = true
	if _sdk:
		_sdk.game.gameplayStart()


## Call on any break in play (menu, pause, level end).
func gameplay_stop() -> void:
	if not _in_gameplay:
		return
	_in_gameplay = false
	if _sdk:
		_sdk.game.gameplayStop()


## Shows a "midgame" or "rewarded" ad and returns true if it played to the end.
## The game is paused and muted while the ad is on screen.
## Without the SDK, debug builds pretend the ad was watched so reward flows can be tested.
func show_ad(type: String) -> bool:
	if _sdk == null:
		return OS.is_debug_build()
	if _ad_showing:
		return false
	_ad_showing = true
	_ad_callbacks = [
		JavaScriptBridge.create_callback(_on_ad_started),
		JavaScriptBridge.create_callback(_on_ad_finished),
		JavaScriptBridge.create_callback(_on_ad_error),
	]
	var callbacks: JavaScriptObject = JavaScriptBridge.create_object("Object")
	callbacks.adStarted = _ad_callbacks[0]
	callbacks.adFinished = _ad_callbacks[1]
	callbacks.adError = _ad_callbacks[2]
	var was_paused := get_tree().paused
	_sdk.ad.requestAd(type, callbacks)
	var watched: bool = await _ad_done
	get_tree().paused = was_paused
	_ad_showing = false
	Settings.apply()
	return watched


## True while an ad plays or the portal asks for silence; Settings folds this into the mute state.
func is_audio_blocked() -> bool:
	return _ad_showing or _portal_muted


func has_data_module() -> bool:
	return _sdk != null


func data_get(key: String) -> String:
	var value = _sdk.data.getItem(key)
	return value if value is String else ""


func data_set(key: String, value: String) -> void:
	_sdk.data.setItem(key, value)


func _on_ad_started(_args: Array) -> void:
	get_tree().paused = true
	Settings.apply()


func _on_ad_finished(_args: Array) -> void:
	_ad_done.emit(true)


func _on_ad_error(args: Array) -> void:
	push_warning("Ad not shown: %s" % JavaScriptBridge.get_interface("JSON").stringify(args[0]))
	_ad_done.emit(false)


func _on_portal_settings_changed(args: Array) -> void:
	_portal_muted = bool(args[0].muteAudio)
	Settings.apply()
