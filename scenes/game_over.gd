class_name GameOver
extends Control
## End-of-run panel: grants coins, offers a rewarded ad for x2, shows a midgame ad before retry.

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
	%DoubleButton.disabled = score == 0
	show()


func _on_double_pressed() -> void:
	%DoubleButton.disabled = true
	if await Portal.show_ad("rewarded"):
		Progress.add_coins(_score)
		%ResultLabel.text = "Score: %d\n+%d coins (x2)" % [_score, _score * 2]
	else:
		%DoubleButton.disabled = false


func _on_retry_pressed() -> void:
	await Portal.show_ad("midgame")
	retry_pressed.emit()
