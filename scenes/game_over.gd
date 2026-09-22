class_name GameOver
extends Control
## End-of-run panel: grants coins, offers a rewarded ad for x2, shows an interstitial before retry
## when Ads allows one. Ads decides and counts; this panel only asks.

signal retry_pressed
signal menu_pressed

var _score := 0


func _ready() -> void:
	%DoubleButton.pressed.connect(_on_double_pressed)
	%RetryButton.pressed.connect(_on_retry_pressed)
	%MenuButton.pressed.connect(menu_pressed.emit)


func show_result(score: int) -> void:
	_score = score
	Progress.add_coins(score)
	%ResultLabel.text = "Score: %d\n+%d coins" % [score, score]
	%DoubleButton.disabled = score == 0 or not Ads.can_offer(&"double")
	show()


func _on_double_pressed() -> void:
	%DoubleButton.disabled = true
	if await Ads.offer(&"double"):
		Progress.add_coins(_score)
		%ResultLabel.text = "Score: %d\n+%d coins (x2)" % [_score, _score * 2]
	else:
		%DoubleButton.disabled = false


func _on_retry_pressed() -> void:
	await Ads.run_finished()
	retry_pressed.emit()
