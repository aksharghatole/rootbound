extends Node
## SaveManager — Milestone 4
## Real disk I/O. Atomic writes. Corrupt-file recovery. Never crashes.
##
## Gotcha reminders (Godot 4.3):
##   - FileAccess.open() returns null on failure, not an error code.
##   - DirAccess.rename() is the atomic rename primitive.
##   - user:// maps to platform-specific paths (see README/M4 issue).

const SAVE_VERSION: int = 1

## Settable so tests can point elsewhere without touching the real save.
var save_path: String = "user://save.json"
var meta_path: String = "user://meta.json"


func _ready() -> void:
	print("SaveManager ready. Save path: ", save_path)


# ---------------------------------------------------------------- existence

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func has_meta_save() -> bool:
	return FileAccess.file_exists(meta_path)


# ---------------------------------------------------------------- serialization (pure)

func serialize(state: GameState) -> Dictionary:
	if state == null:
		return {}
	return {
		"version": SAVE_VERSION,
		"state": state.to_dictionary(),
	}


func deserialize(data: Dictionary) -> GameState:
	if data.is_empty():
		return null
	var raw: Variant = data.get("state", null)
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var d: Dictionary = raw as Dictionary

	# Required keys — refuse to build a half-populated state.
	var required: Array = [
		"season", "hp", "max_hp", "roots", "trunk", "leaves",
		"growth_points", "rng_seed", "seed_name"
	]
	for key in required:
		if not d.has(key):
			push_warning("SaveManager.deserialize: missing key '%s'" % key)
			return null

	var s: GameState = GameState.new()
	s.season = int(d["season"])
	s.hp = int(d["hp"])
	s.max_hp = int(d["max_hp"])
	s.roots = int(d["roots"])
	s.trunk = int(d["trunk"])
	s.leaves = int(d["leaves"])
	s.growth_points = int(d["growth_points"])
	s.rng_seed = int(d["rng_seed"])
	s.seed_name = String(d["seed_name"])
	s.passive_used = bool(d.get("passive_used", false))
	return s


# ---------------------------------------------------------------- atomic write helper

func _atomic_write_text(path: String, text: String) -> bool:
	var tmp_path: String = path + ".tmp"
	var f: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: could not open %s for write" % tmp_path)
		return false
	f.store_string(text)
	f.close()

	var dir: DirAccess = DirAccess.open(path.get_base_dir())
	if dir == null:
		# For user:// paths, get_base_dir() may be "user://" which DirAccess
		# can still open via the singleton. Fall back to a relative rename.
		var err_fallback: int = DirAccess.rename_absolute(tmp_path, path)
		if err_fallback != OK:
			push_warning("SaveManager: rename failed (%d)" % err_fallback)
			_cleanup_tmp(tmp_path)
			return false
		return true

	var err: int = dir.rename(tmp_path, path.get_file())
	if err != OK:
		push_warning("SaveManager: DirAccess.rename failed (%d)" % err)
		_cleanup_tmp(tmp_path)
		return false
	return true


func _cleanup_tmp(tmp_path: String) -> void:
	if FileAccess.file_exists(tmp_path):
		var dir: DirAccess = DirAccess.open(tmp_path.get_base_dir())
		if dir != null:
			dir.remove(tmp_path.get_file())
		else:
			DirAccess.remove_absolute(tmp_path)


# ---------------------------------------------------------------- run save/load

func save_run(state: GameState) -> bool:
	if state == null:
		return false
	var payload: Dictionary = serialize(state)
	if payload.is_empty():
		return false
	var text: String = JSON.stringify(payload, "  ")
	return _atomic_write_text(save_path, text)


func load_run() -> GameState:
	if not has_save():
		return null

	var f: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		push_warning("SaveManager.load_run: could not open %s" % save_path)
		return null
	var text: String = f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager.load_run: corrupt JSON in %s" % save_path)
		return null

	return deserialize(parsed as Dictionary)


func delete_run() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var dir: DirAccess = DirAccess.open(save_path.get_base_dir())
	if dir != null:
		dir.remove(save_path.get_file())
	else:
		DirAccess.remove_absolute(save_path)


# ---------------------------------------------------------------- meta save/load

func serialize_meta(meta: Meta) -> Dictionary:
	if meta == null:
		return {}
	return {
		"version": SAVE_VERSION,
		"meta": meta.to_dictionary(),
	}


func deserialize_meta(data: Dictionary) -> Meta:
	if data.is_empty():
		return null
	var raw: Variant = data.get("meta", null)
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var d: Dictionary = raw as Dictionary

	var m: Meta = Meta.new()

	var seeds_raw: Variant = d.get("unlocked_seeds", ["oak"])
	if typeof(seeds_raw) == TYPE_ARRAY:
		var seeds_arr: Array = seeds_raw as Array
		m.unlocked_seeds = seeds_arr.duplicate()
	else:
		m.unlocked_seeds = ["oak"]

	m.best_season = int(d.get("best_season", 0))
	m.total_runs = int(d.get("total_runs", 0))
	return m


func save_meta(meta: Meta) -> bool:
	if meta == null:
		return false
	var payload: Dictionary = serialize_meta(meta)
	if payload.is_empty():
		return false
	var text: String = JSON.stringify(payload, "  ")
	return _atomic_write_text(meta_path, text)


func load_meta() -> Meta:
	if not has_meta_save():
		return Meta.new()

	var f: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
	if f == null:
		push_warning("SaveManager.load_meta: could not open %s" % meta_path)
		return Meta.new()
	var text: String = f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager.load_meta: corrupt JSON in %s" % meta_path)
		return Meta.new()

	var m: Meta = deserialize_meta(parsed as Dictionary)
	if m == null:
		push_warning("SaveManager.load_meta: deserialize failed")
		return Meta.new()
	return m


# ---------------------------------------------------------------- test helpers

func clear_all() -> void:
	delete_run()
	if FileAccess.file_exists(meta_path):
		var dir: DirAccess = DirAccess.open(meta_path.get_base_dir())
		if dir != null:
			dir.remove(meta_path.get_file())
		else:
			DirAccess.remove_absolute(meta_path)
