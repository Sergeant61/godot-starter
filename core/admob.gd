extends Node
## The ad network on a phone. Ads decides whether an ad may be shown; this shows it.
##
## On the web that job belongs to Portal, because CrazyGames serves its own ads and forbids any
## other network. So there are two providers and Ads picks between them by platform; this one is
## inert everywhere but Android and iOS, and says so rather than pretending.
##
## Consent comes first and is not optional. A player in the EEA or the UK must be asked before a
## personalised ad is served, and Google's own UMP form is what asks them. The SDK is initialised
## only once that form has been answered or found unnecessary. The form itself is written in the
## AdMob console (Privacy & messaging); until one is published there, update() fails and the SDK
## starts without consent - the game still runs, the ads just cannot be personalised.
##
## An ad that has not been loaded cannot be shown, and loading takes seconds over a phone network.
## So one of each is kept ready and the next is loaded the moment one is spent. When none is ready
## has() says so, and the screen never makes an offer it cannot keep: a player told "watch an ad to
## keep flying" who then gets nothing has been lied to.
##
## The API here is the plugin's own, taken from its sample scenes (addons/admob/gdscript/sample).
## Its skills/ documentation describes listener classes for consent that the shipped code does not
## have; where the two disagree, the code wins.

## The real ad units, from the AdMob console. Only a build that ships asks for these: a developer's
## own device loading the account's own live ads is the fastest way to have that account closed,
## and there is no way to take an impression back.
##
## In the starter these are Google's test units, the same as TEST_UNITS below, so a game that
## ships before anyone edits this file serves ads that earn nothing rather than ads that get the
## account closed. Replace them with the console's ids for the game, and put the app id in
## project.godot under [admob] general/android/app_id (the plugin reads it from there).
const UNITS := {
	"Android": {"rewarded": "ca-app-pub-3940256099942544/5224354917",
		"interstitial": "ca-app-pub-3940256099942544/1033173712"},
	"iOS": {"rewarded": "ca-app-pub-3940256099942544/1712485313",
		"interstitial": "ca-app-pub-3940256099942544/4411468910"},
}

## Google's own, for every build that is not a release. They always fill and they never pay, which
## is exactly what testing wants.
const TEST_UNITS := {
	"Android": {"rewarded": "ca-app-pub-3940256099942544/5224354917",
		"interstitial": "ca-app-pub-3940256099942544/1033173712"},
	"iOS": {"rewarded": "ca-app-pub-3940256099942544/1712485313",
		"interstitial": "ca-app-pub-3940256099942544/4411468910"},
}

## Emitted when a full-screen ad closes, carrying whether it got on screen at all.
signal _closed(shown: bool)

var _started := false ## The SDK is up and the first loads have gone out.
var _showing := false
var _rewarded: RewardedAd = null
var _interstitial: InterstitialAd = null
## Loaders and their callbacks are reference counted, and a load takes seconds to come back. Held
## here rather than made inside _load, where they would go out of scope the moment the call
## returned, taking with them the callbacks the answer was going to arrive on: the ad loads and
## nothing hears about it. The plugin's own sample keeps them as members for the same reason.
var _loaders := {
	"rewarded": RewardedAdLoader.new(), "interstitial": InterstitialAdLoader.new(),
}
var _callbacks := {
	"rewarded": RewardedAdLoadCallback.new(), "interstitial": InterstitialAdLoadCallback.new(),
}


func _ready() -> void:
	if not available():
		return
	_trace("ready")
	## Consent first, ads after. Asking for an ad before consent is settled is what gets an
	## AdMob account suspended, so nothing here loads until _start runs.
	UserMessagingPlatform.consent_information.update(
		ConsentRequestParameters.new(), _on_consent_known, _on_consent_unknown)


## Every step of a flow whose failures are silent: the plugin's own update() does nothing at all
## when its singleton is missing, and a callback that never comes looks exactly like one that has
## not come yet. Debug builds only - a release build logs nothing on Android anyway.
func _trace(line: String) -> void:
	if OS.is_debug_build():
		print("Admob: ", line)


## Whether this provider is the one in charge here. The web build has Portal instead, and a
## desktop build has no network at all.
func available() -> bool:
	return UNITS.has(OS.get_name())


## True when an ad of this kind could be shown right now, so a screen can hide an offer it cannot
## keep rather than make it and fail.
func has(type: String) -> bool:
	if not _started or _showing:
		return false
	return _rewarded != null if type == "rewarded" else _interstitial != null


## Shows one and answers what the player is owed: for a rewarded ad, whether they watched enough of
## it to earn the reward; for an interstitial, whether it was shown at all.
func show_ad(type: String) -> bool:
	if not has(type):
		return false
	_showing = true
	var earned := [false] ## In an array so the listener's lambda can write to it.
	if type == "rewarded":
		var listener := OnUserEarnedRewardListener.new()
		## The only thing that counts. Closing an ad early dismisses it but never fires this.
		listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
			earned[0] = true
		_rewarded.show(listener)
	else:
		_interstitial.show()
	var shown: bool = await _closed
	_showing = false
	return bool(earned[0]) if type == "rewarded" else shown


## A consent check that fails is not a reason to have no game: the SDK starts anyway and serves
## whatever it is allowed to serve without an answer.
func _on_consent_unknown(error: FormError) -> void:
	_trace("consent failed - %s" % error.message)
	_start()


func _on_consent_known() -> void:
	_trace("consent known")
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_form_ready, _on_consent_unknown)
	else:
		_start()


func _on_form_ready(form: ConsentForm) -> void:
	_trace("consent form ready")
	if (UserMessagingPlatform.consent_information.get_consent_status()
			== ConsentInformation.ConsentStatus.REQUIRED):
		form.show(func(_error: FormError) -> void: _start())
	else:
		_start() ## Already answered, or this player was never in scope.


func _start() -> void:
	if _started:
		return ## Consent can arrive by more than one path; the SDK starts once.
	_trace("initialising")
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_trace("initialised")
		_started = true
		_load("rewarded")
		_load("interstitial")
	MobileAds.set_request_configuration(RequestConfiguration.new())
	MobileAds.initialize(listener)


func _load(type: String) -> void:
	var callback: Variant = _callbacks[type]
	_trace("loading %s" % type)
	callback.on_ad_loaded = func(ad: Variant) -> void:
		_trace("%s loaded" % type)
		if type == "rewarded":
			_rewarded = ad
		else:
			_interstitial = ad
		ad.full_screen_content_callback = _when_closed(type, ad)
	## No retry. A failed load means no signal, no network or no fill, and asking again and again
	## is how an app empties a battery. The next spent ad tries once more.
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_trace("no %s ad - %s" % [type, error.message])
	_loaders[type].load(_unit(type), AdRequest.new(), callback)


## Which id to ask for. The only build that asks for the real one is the one players get.
func _unit(type: String) -> String:
	var table: Dictionary = TEST_UNITS if OS.is_debug_build() else UNITS
	return table[OS.get_name()][type]


## Both ads end the same two ways: the player dismissed it, or it never reached the screen. Either
## way the native ad must be destroyed or its memory is never given back, the slot has to be
## emptied and refilled, and show_ad has to be told - it is awaiting this and would wait for ever.
func _when_closed(type: String, ad: Variant) -> FullScreenContentCallback:
	var callback := FullScreenContentCallback.new()
	var spend := func(shown: bool) -> void:
		ad.destroy()
		if type == "rewarded":
			_rewarded = null
		else:
			_interstitial = null
		_closed.emit(shown)
		_load(type) ## Straight back in the queue: the next death must not wait for a download.
	callback.on_ad_dismissed_full_screen_content = func() -> void:
		spend.call(true)
	callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		push_warning("AdMob: ad would not show - %s" % error.message)
		spend.call(false)
	return callback
