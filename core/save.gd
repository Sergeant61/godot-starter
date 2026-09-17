extends Node
## Key-value save shared by every game, stored as one JSON blob:
## the CrazyGames data module when available (required there), otherwise user://save.json.
## JSON has no int type: numbers come back as float, so wrap reads in int() where needed.

const FILE_PATH := "user://save.json"
const PORTAL_KEY := "save"

var _data: Dictionary = {}


## Call once after Portal.init().
func load_data() -> void:
	var text := ""
	if Portal.has_data_module():
		text = Portal.data_get(PORTAL_KEY)
	elif FileAccess.file_exists(FILE_PATH):
		text = FileAccess.get_file_as_string(FILE_PATH)
	var parsed = JSON.parse_string(text) if text != "" else null
	_data = parsed if parsed is Dictionary else {}


func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


func set_value(key: String, value: Variant) -> void:
	_data[key] = value
	var text := JSON.stringify(_data)
	if Portal.has_data_module():
		Portal.data_set(PORTAL_KEY, text)
	else:
		FileAccess.open(FILE_PATH, FileAccess.WRITE).store_string(text)
