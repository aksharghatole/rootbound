extends SceneTree
## Headless test: save -> load -> identical state.
## Run: godot --headless --script tests/test_save_round_trip.gd

var failures: int = 0


func _init() -> void:
	process_frame.connect(_on_first_frame, CONNECT_ONE_SHOT)


func _on_first_frame() -> void:
	_run_tests()


func _run_tests() -> void:
	var sm: Node = root.get_node_or_null("SaveManager")
	if sm == null:
		_fail("SaveManager autoload not found")
		_finish()
		return

	# Point at a test-specific path.
	sm.save_path = "user://test_round_trip.json"
	sm.meta_path = "user://test_round_trip_meta.json"
	sm.clear_all()

	# --- No save initially ---
	if sm.has_save():
		_fail("expected no save after clear_all")

	# --- Build a state with non-default values ---
	var s: GameState = GameState.new()
	s.season = 7
	s.hp = 3
	s.max_hp = 14
	s.roots = 4
	s.trunk = 2
	s.leaves = 5
	s.growth_points = 3
	s.rng_seed = 987654
	s.seed_name = "willow"

	# --- Save ---
	if not sm.save_run(s):
		_fail("save_run returned false")
		_finish()
		return
	if not sm.has_save():
		_fail("has_save still false after save_run")

	# --- Load ---
	var loaded: GameState = sm.load_run()
	if loaded == null:
		_fail("load_run returned null")
		_finish()
		return

	# --- Compare field by field ---
	_eq(loaded.season, 7, "season")
	_eq(loaded.hp, 3, "hp")
	_eq(loaded.max_hp, 14, "max_hp")
	_eq(loaded.roots, 4, "roots")
	_eq(loaded.trunk, 2, "trunk")
	_eq(loaded.leaves, 5, "leaves")
	_eq(loaded.growth_points, 3, "growth_points")
	_eq(loaded.rng_seed, 987654, "rng_seed")
	_eq(loaded.seed_name, "willow", "seed_name")

	# --- Delete ---
	sm.delete_run()
	if sm.has_save():
		_fail("has_save true after delete_run")

	# --- Cleanup ---
	sm.clear_all()
	_finish()


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_save_round_trip (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
