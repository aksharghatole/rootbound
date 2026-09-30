extends RefCounted
class_name SeedLibrary
## SeedLibrary — Milestone 6
## Loads seeds.json. Provides lookups by id. Pure data, no state.

const SEEDS_PATH: String = "res://data/seeds.json"

var _seeds: Array = []


func _init() -> void:
	_load()


func _load() -> void:
	var f: FileAccess = FileAccess.open(SEEDS_PATH, FileAccess.READ)
	if f == null:
		push_error("SeedLibrary: could not open %s" % SEEDS_PATH)
		_seeds = []
		return
	var text: String = f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("SeedLibrary: invalid JSON")
		_seeds = []
		return

	var dict: Dictionary = parsed as Dictionary
	var raw: Variant = dict.get("seeds", [])
	if typeof(raw) != TYPE_ARRAY:
		push_error("SeedLibrary: 'seeds' must be an array")
		_seeds = []
		return

	for entry in (raw as Array):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		_seeds.append(Seed.from_dictionary(entry as Dictionary))


func count() -> int:
	return _seeds.size()


func all_ids() -> Array:
	var ids: Array = []
	for s in _seeds:
		ids.append((s as Seed).id)
	return ids


func get_seed(id: String) -> Seed:
	for s in _seeds:
		var seed_obj: Seed = s as Seed
		if seed_obj.id == id:
			return seed_obj
	return null


func default_seed() -> Seed:
	if _seeds.is_empty():
		return null
	return _seeds[0] as Seed
