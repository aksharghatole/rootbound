extends Node
## GameManager — Milestone 4
## Owns the current GameState and meta. Persists to disk on state changes.
## UI listens to these signals. UI never mutates GameState directly.

signal run_started(state: GameState)
signal run_ended(won: bool)
signal state_changed(state: GameState)
signal growth_spent(stat: String, new_value: int)
signal season_advanced(new_season: int)
signal event_fired(event_name: String, damage: int)
signal meta_changed(meta: Meta)

var current_state: GameState = null
var meta: Meta = null
var _rng: RNG = null
var _events: EventSystem = null


func _ready() -> void:
	_rng = RNG.new(0)
	_events = EventSystem.new()
	meta = SaveManager.load_meta()
	if meta == null:
		meta = Meta.new()
	print("GameManager ready. Events loaded: %d. Meta: %s" % [
		_events.event_count(), str(meta)
	])


func has_active_run() -> bool:
	return current_state != null and current_state.is_alive()


func start_new_run() -> GameState:
	current_state = GameState.new()
	current_state.rng_seed = randi()
	current_state.growth_points = 0
	_rng = RNG.new(current_state.rng_seed)
	print("Starting new run. Seed: %d" % current_state.rng_seed)
	SaveManager.save_run(current_state)
	run_started.emit(current_state)
	state_changed.emit(current_state)
	return current_state


func resume_run() -> GameState:
	## Load a saved run into current_state. Returns null if no save.
	var loaded: GameState = SaveManager.load_run()
	if loaded == null:
		return null
	current_state = loaded
	_rng = RNG.new(current_state.rng_seed)
	print("Resumed run. Season: %d, HP: %d" % [current_state.season, current_state.hp])
	run_started.emit(current_state)
	state_changed.emit(current_state)
	return current_state


func end_run(won: bool) -> void:
	if current_state == null:
		return
	print("Run ended. Won: %s" % str(won))

	# Meta update
	if meta == null:
		meta = Meta.new()
	meta.record_run(current_state.season, won)
	SaveManager.save_meta(meta)
	meta_changed.emit(meta)

	SaveManager.delete_run()

	run_ended.emit(won)
	current_state = null
	state_changed.emit(null)


func get_state() -> GameState:
	return current_state


func get_meta_data() -> Meta:
	return meta


func spend_growth_point(stat: String) -> void:
	if current_state == null:
		return
	var before: int = current_state.growth_points
	current_state = SeasonSystem.spend_growth_point(current_state, stat)
	if current_state.growth_points == before:
		return
	SaveManager.save_run(current_state)
	var new_value: int = 0
	match stat:
		"roots":
			new_value = current_state.roots
		"trunk":
			new_value = current_state.trunk
		"leaves":
			new_value = current_state.leaves
	growth_spent.emit(stat, new_value)
	state_changed.emit(current_state)


func advance_season() -> Dictionary:
	if current_state == null:
		return {}
	var result: Dictionary = SeasonSystem.advance_season(current_state, _rng, _events)
	current_state = result.get("state", current_state) as GameState

	var event: Dictionary = result.get("event", {}) as Dictionary
	var damage: int = int(result.get("damage", 0))
	if not event.is_empty():
		var name: String = String(event.get("name", "?"))
		print("Season event: %s (-%d HP)" % [name, damage])
		event_fired.emit(name, damage)

	var won: bool = bool(result.get("won", false))
	var lost: bool = bool(result.get("lost", false))

	if won or lost:
		season_advanced.emit(current_state.season)
		state_changed.emit(current_state)
		end_run(won)
		return result

	SaveManager.save_run(current_state)
	season_advanced.emit(current_state.season)
	state_changed.emit(current_state)
	return result
