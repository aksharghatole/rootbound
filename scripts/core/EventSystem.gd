extends RefCounted
class_name EventSystem
## EventSystem — Milestone 3
## Loads events from data/events.json. Pure functions. No mutation of caller state.
##
## Gotcha reminder (Godot 4.3): no := when RHS returns Variant.

const EVENTS_PATH: String = "res://data/events.json"

var _events: Array = []


func _init() -> void:
	_load_events()


func _load_events() -> void:
	var file: FileAccess = FileAccess.open(EVENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("EventSystem: could not open %s" % EVENTS_PATH)
		_events = []
		return
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("EventSystem: invalid JSON in %s" % EVENTS_PATH)
		_events = []
		return

	var dict: Dictionary = parsed as Dictionary
	var raw_events: Variant = dict.get("events", [])
	if typeof(raw_events) != TYPE_ARRAY:
		push_error("EventSystem: 'events' must be an array")
		_events = []
		return

	_events = raw_events as Array


func event_count() -> int:
	return _events.size()


func get_event_by_id(id: String) -> Dictionary:
	for e in _events:
		if typeof(e) == TYPE_DICTIONARY:
			var ed: Dictionary = e as Dictionary
			if ed.get("id", "") == id:
				return ed
	return {}


func weights_for_season(season: int) -> PackedInt32Array:
	## weight = base_weight + (season - 1) * weight_escalation
	var weights: PackedInt32Array = PackedInt32Array()
	var s: int = max(1, season)
	for e in _events:
		var ed: Dictionary = e as Dictionary
		var base: int = int(ed.get("base_weight", 0))
		var esc: int = int(ed.get("weight_escalation", 0))
		weights.append(base + (s - 1) * esc)
	return weights


func pick_event(season: int, rng: RNG) -> Dictionary:
	## Returns the chosen event dictionary, or {} if none available.
	if _events.is_empty():
		return {}
	var weights: PackedInt32Array = weights_for_season(season)
	var index: int = rng.pick_weighted(weights)
	return _events[index] as Dictionary


func compute_damage(event: Dictionary, state: GameState) -> int:
	## Exact formulas from the M3 contract:
	##   Drought: max(0, 5 - roots)
	##   Pest:    max(0, 4 - leaves)
	##   Frost:   max(0, 5 - trunk)
	## Generalised: max(0, base_damage - stat_value)
	var stat: String = String(event.get("stat", ""))
	var base: int = int(event.get("base_damage", 0))
	var value: int = _stat_value(state, stat)
	return max(0, base - value)


func _stat_value(state: GameState, stat: String) -> int:
	match stat:
		"roots":
			return state.roots
		"trunk":
			return state.trunk
		"leaves":
			return state.leaves
		_:
			return 0
