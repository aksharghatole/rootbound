extends SceneTree
## Headless test: meta save/load round-trip and record_run semantics.
## Run: godot --headless --script tests/test_meta_persistence.gd

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

	sm.save_path = "user://test_meta_run.json"
	sm.meta_path = "user://test_meta.json"
	sm.clear_all()

	# --- Fresh meta when file missing ---
	var m0: Meta = sm.load_meta()
	if m0 == null:
		_fail("load_meta returned null on missing file")
		_finish()
		return
	if m0.total_runs != 0 or m0.best_season != 0:
		_fail("fresh Meta should be zeros")
	if not m0.unlocked_seeds.has("oak"):
		_fail("fresh Meta should include 'oak'")

	# --- record_run semantics ---
	m0.record_run(5, false)
	if m0.total_runs != 1:
		_fail("total_runs should increment to 1")
	if m0.best_season != 5:
		_fail("best_season should be 5 after first run")

	m0.record_run(3, false)
	if m0.best_season != 5:
		_fail("best_season should not regress: got %d" % m0.best_season)

	m0.record_run(12, true)
	if m0.best_season != 12:
		_fail("best_season should be 12 after win")
	if m0.total_runs != 3:
		_fail("total_runs should be 3")

	# --- unlock_seed is idempotent ---
	if not m0.unlock_seed("willow"):
		_fail("first unlock_seed should return true")
	if m0.unlock_seed("willow"):
		_fail("second unlock_seed should return false")
	if m0.unlocked_seeds.size() != 2:
		_fail("expected 2 unlocked seeds, got %d" % m0.unlocked_seeds.size())

	# --- Save/load round-trip ---
	if not sm.save_meta(m0):
		_fail("save_meta failed")
		_finish()
		return

	var m1: Meta = sm.load_meta()
	if m1 == null:
		_fail("load_meta returned null after save")
		_finish()
		return

	if m1.total_runs != 3:
		_fail("meta round-trip lost total_runs: got %d" % m1.total_runs)
	if m1.best_season != 12:
		_fail("meta round-trip lost best_season: got %d" % m1.best_season)
	if not m1.unlocked_seeds.has("willow"):
		_fail("meta round-trip lost 'willow'")
	if not m1.unlocked_seeds.has("oak"):
		_fail("meta round-trip lost 'oak'")

	sm.clear_all()
	_finish()


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_meta_persistence (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
