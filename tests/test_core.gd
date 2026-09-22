extends GutTest
## The shared layer's rules. Run them with:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd \
##       -gdir=res://tests -gexit
## They run against the real user:// save, so anything they change they put back.


func test_music_and_sounds_switch_off_separately_and_stay_off() -> void:
	var was_on := [Settings.is_music_on(), Settings.is_sfx_on()]
	if not Settings.is_music_on():
		Settings.toggle_music()
	if not Settings.is_sfx_on():
		Settings.toggle_sfx()
	Settings.toggle_music()
	assert_false(Settings.is_music_on(), "music off")
	assert_true(Settings.is_sfx_on(), "sounds untouched")
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index(Settings.MUSIC_BUS)))
	assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index(Settings.SFX_BUS)))
	Settings.toggle_music()
	Settings.toggle_sfx()
	assert_true(Settings.is_music_on())
	assert_false(Settings.is_sfx_on(), "sounds off")
	if not was_on[1]:
		Settings.toggle_sfx()
	if Settings.is_sfx_on() != was_on[1]:
		Settings.toggle_sfx()
	if Settings.is_music_on() != was_on[0]:
		Settings.toggle_music()


func test_rumble_and_shake_switch_off_and_stay_off() -> void:
	var was_on := [Settings.is_rumble_on(), Settings.is_shake_on()]
	if not Settings.is_rumble_on():
		Settings.toggle_rumble()
	if not Settings.is_shake_on():
		Settings.toggle_shake()
	Settings.toggle_rumble()
	Settings.toggle_shake()
	assert_false(Settings.is_rumble_on(), "off once they are switched off")
	assert_false(Settings.is_shake_on())
	Settings.rumble(40) ## Does nothing now, and must not throw on the way to doing nothing.
	if not was_on[0]:
		Settings.toggle_rumble()
	Settings.toggle_rumble()
	if Settings.is_rumble_on() != was_on[0]:
		Settings.toggle_rumble()
	if Settings.is_shake_on() != was_on[1]:
		Settings.toggle_shake()


## A state where every interstitial guard is satisfied, so each test can break exactly one.
func _ad_state() -> Dictionary:
	return {"sessions": 5, "runs_today": 9, "shown_today": 0, "runs_since": 9,
		"last_shown": 0.0, "last_rewarded": 0.0}


func test_an_interstitial_needs_every_guard_to_pass() -> void:
	var now := 100000.0
	assert_true(Ads.allowed(_ad_state(), now), "a settled player between runs sees one")
	var first := _ad_state()
	first["sessions"] = 1
	assert_false(Ads.allowed(first, now), "never in a first session")
	var early := _ad_state()
	early["runs_today"] = Ads.FREE_RUNS_A_DAY
	assert_false(Ads.allowed(early, now), "never in the day's first runs")
	var spent := _ad_state()
	spent["shown_today"] = Ads.MOST_A_DAY
	assert_false(Ads.allowed(spent, now), "never past the day's cap")
	var soon := _ad_state()
	soon["runs_since"] = Ads.RUNS_BETWEEN - 1
	assert_false(Ads.allowed(soon, now), "never twice in too few runs")
	var recent := _ad_state()
	recent["last_shown"] = now - Ads.SECONDS_BETWEEN * 0.5
	assert_false(Ads.allowed(recent, now), "never twice in a few minutes")
	var rewarded := _ad_state()
	rewarded["last_rewarded"] = now - Ads.SECONDS_AFTER_REWARDED * 0.5
	assert_false(Ads.allowed(rewarded, now),
		"never right after the player already sat through one")


func test_buying_out_of_ads_stops_every_interstitial() -> void:
	var now := 100000.0
	assert_true(Ads.allowed(_ad_state(), now), "shown to a player who has not bought out")
	assert_false(Ads.allowed(_ad_state(), now, true), "and never to one who has")


func test_a_rewarded_offer_runs_out_within_a_run_and_comes_back_with_the_next() -> void:
	Ads.start_run()
	for i in Ads.DOUBLES_PER_RUN:
		assert_true(Ads.can_offer(&"double"), "double %d of %d" % [i + 1, Ads.DOUBLES_PER_RUN])
		Ads._run[&"double"] = i + 1 ## What a watched ad records.
	assert_false(Ads.can_offer(&"double"), "and then the run has had its share")
	assert_true(Ads.can_offer(&"revive"), "without touching the others")
	assert_false(Ads.can_offer(&"reroll"), "a kind the game never declared is never offered")
	Ads.start_run()
	assert_true(Ads.can_offer(&"double"), "the next run starts fresh")


func test_reloading_the_ad_state_counts_the_session_and_keeps_the_days_counters() -> void:
	var kept: Dictionary = Save.get_value("ads", {})
	Save.set_value("ads", {"day": Ads._today(), "sessions": 4, "runs_today": 3, "shown_today": 1})
	Ads.reload()
	var state: Dictionary = Save.get_value("ads", {})
	assert_eq(int(state["sessions"]), 5, "one more session on the count the save already held")
	assert_eq(int(state["runs_today"]), 3, "and the day's counters kept, because the day is today")
	assert_eq(int(state["shown_today"]), 1)
	Save.set_value("ads", kept)


## The menu and the placeholder game, with its game-over panel, build with no window: a scene that
## refers to a node or an autoload call that is gone fails here, not on the phone.
func test_every_scene_builds() -> void:
	for path: String in ["res://scenes/main_menu.tscn", "res://scenes/game.tscn"]:
		var scene: Node = load(path).instantiate()
		add_child_autofree(scene)
		await wait_frames(2)
		assert_not_null(scene, path)
