extends Node
## Whether an ad may be shown right now. Every rule the plan sets for advertising lives here and
## nowhere else, so what the player is put through is one file you can read in a minute.
##
## The rules exist because an ad shown at the wrong moment costs more than it earns: a player who
## meets a full-screen ad in their first session does not come back, and the money in this kind of
## game is in the players who do. So interstitials are rationed hard - never in a first session,
## never in the day's first runs, never right after the player has already watched a rewarded one,
## and never twice in a few minutes. Rewarded ads have no such guards because the player asks for
## them; they are only capped per run so they cannot become the way the game is played.
##
## Showing the ad is somebody else's job: Portal on the web (CrazyGames), Admob on a phone. This
## node decides, counts and remembers. offer() is the one call a screen makes.
##
## The counting that must survive a restart lives in the save under "ads"; the rest is this run.
##
## The rewarded kinds and their allowances are the game's to set: "double" (double the run's
## coins) and "revive" are what the starter's game_over offers; add a kind to _left for every
## offer the game makes.

signal ad_free_changed ## The "remove ads" purchase went through, or was restored.

const DOUBLES_PER_RUN := 1
const REVIVES_PER_RUN := 1
## Interstitial guards, all from the plan's advertising table.
const FIRST_SESSION_FREE := true ## Nobody meets a full-screen ad on the day they install.
const FREE_RUNS_A_DAY := 2 ## The day's first runs end without one.
const RUNS_BETWEEN := 2 ## At most one interstitial per this many finished runs.
const SECONDS_BETWEEN := 180.0
const SECONDS_AFTER_REWARDED := 120.0 ## A player who just watched one is left alone.
const MOST_A_DAY := 6

var ad_free := false ## Bought "remove ads": no interstitials ever, rewarded ones still offered.

var _run := {} ## How many of each rewarded kind this run has already used.


## Reads the save. Called from boot once the save is loaded, and whenever the save is replaced.
##
## Not from _ready. Autoloads are ready before the boot scene loads the save, and Save writes the
## whole file on every set: called then, this wrote a file holding nothing but "ads" over the
## player's coins, ships and achievements, every launch. That shipped in 0.6.0.
func reload() -> void:
	ad_free = bool(_state().get("ad_free", false))
	var state := _state()
	var today := _today()
	if state.get("day", "") != today:
		state["day"] = today
		state["shown_today"] = 0
		state["runs_today"] = 0
	state["sessions"] = int(state.get("sessions", 0)) + 1
	_save(state)


## A new run: the per-run rewarded allowances start again.
func start_run() -> void:
	_run.clear()


## May this screen offer a rewarded ad of this kind, and has the run any left?
##
## On a phone it also asks whether an ad is actually loaded. Offering a reward the provider cannot
## deliver is worse than not offering one: the player taps "keep flying", nothing happens, and the
## run ends anyway.
func can_offer(kind: StringName) -> bool:
	if _left(kind) <= 0:
		return false
	return Admob.has("rewarded") if Admob.available() else true


## What the player gets for watching, or false if they did not. Counts the watch against the run
## and against the interstitial guard, because someone who just sat through an ad is owed a rest.
func offer(kind: StringName) -> bool:
	if not can_offer(kind):
		return false
	_run[kind] = int(_run.get(kind, 0)) + 1
	var watched: bool = await _show("rewarded")
	if watched:
		var state := _state()
		state["last_rewarded"] = Time.get_unix_time_from_system()
		_save(state)
	else:
		_run[kind] = int(_run[kind]) - 1 ## Not watched, not spent.
	return watched


## The run is over. Shows an interstitial if every guard allows one, and returns whether it did.
func run_finished() -> bool:
	var state := _state()
	state["runs_today"] = int(state.get("runs_today", 0)) + 1
	state["runs_since"] = int(state.get("runs_since", 0)) + 1
	_save(state)
	if not allowed(_state(), Time.get_unix_time_from_system(), ad_free):
		return false
	var shown: bool = await _show("midgame")
	if shown:
		state = _state()
		state["shown_today"] = int(state.get("shown_today", 0)) + 1
		state["runs_since"] = 0
		state["last_shown"] = Time.get_unix_time_from_system()
		_save(state)
	return shown


## Every interstitial guard in one place, as a pure function of the counters and the clock, so the
## rules can be read and tested without an ad network, a save file or a running game.
static func allowed(state: Dictionary, now: float, bought_out := false) -> bool:
	if bought_out:
		return false
	if FIRST_SESSION_FREE and int(state.get("sessions", 1)) <= 1:
		return false
	if int(state.get("runs_today", 0)) <= FREE_RUNS_A_DAY:
		return false
	if int(state.get("shown_today", 0)) >= MOST_A_DAY:
		return false
	if int(state.get("runs_since", 0)) < RUNS_BETWEEN:
		return false
	if now - float(state.get("last_shown", 0.0)) < SECONDS_BETWEEN:
		return false
	if now - float(state.get("last_rewarded", 0.0)) < SECONDS_AFTER_REWARDED:
		return false
	return true


## The purchase. Kept here rather than in Progress because it is an advertising fact, and the
## billing that sets it is the next thing to land.
func set_ad_free(bought: bool) -> void:
	ad_free = bought
	var state := _state()
	state["ad_free"] = bought
	_save(state)
	ad_free_changed.emit()


## Which network shows it: CrazyGames through Portal on the web, AdMob on a phone. This node
## decides whether an ad may be shown and never talks to a network itself.
func _show(type: String) -> bool:
	if Admob.available():
		return await Admob.show_ad(type)
	return await Portal.show_ad(type)


func _left(kind: StringName) -> int:
	var allowance := {&"double": DOUBLES_PER_RUN, &"revive": REVIVES_PER_RUN}
	return int(allowance.get(kind, 0)) - int(_run.get(kind, 0))


func _state() -> Dictionary:
	return Save.get_value("ads", {})


func _save(state: Dictionary) -> void:
	Save.set_value("ads", state)


static func _today() -> String:
	return Time.get_date_string_from_system()
