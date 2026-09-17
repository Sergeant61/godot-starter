extends Node
## Meta-progression kept between runs: soft currency and upgrade levels.

signal coins_changed(coins: int)


func get_coins() -> int:
	return int(Save.get_value("coins", 0))


func add_coins(amount: int) -> void:
	Save.set_value("coins", get_coins() + amount)
	coins_changed.emit(get_coins())


func try_spend(amount: int) -> bool:
	if get_coins() < amount:
		return false
	add_coins(-amount)
	return true


func get_upgrade_level(id: String) -> int:
	return int(Save.get_value("upgrade_" + id, 0))


func try_buy_upgrade(id: String, cost: int) -> bool:
	if not try_spend(cost):
		return false
	Save.set_value("upgrade_" + id, get_upgrade_level(id) + 1)
	return true
