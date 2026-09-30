extends SceneTree
## Headless test: atomic write behavior — tmp file used, no partial writes,
## rapid successive saves do not corrupt.
## Run: godot --headless --script tests/test_save_atomic.gd

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

	sm.save_path = "user://test_atomic.json"
	sm.meta_path = "user://test_atomic_meta.json"
	sm.clear_all()

	# --- Save once, verify tmp does NOT linger ---
	var s: GameState = GameState.new()
	s.hp = 5
	if not sm.save_run(s):
		_fail("save_run failed")
		_finish()
		return

	var tmp_path: String = sm.save_path + ".tmp"
	if FileAccess.file_exists(tmp_path):
		_fail("tmp file should be gone after successful save: %s" % tmp_path)

	# --- Rapid successive saves ---
	for i in range(20):
		s.hp = 10 - i
		if not sm.save_run(s):
			_fail("save_run %d failed" % i)
			break

	var loaded: GameState = sm.load_run()
	if loaded == null:
		_fail("load_run returned null after rapid saves")
	else:
		# Last write wins: hp should be 10 - 19 = -9, clamped? no clamp here,
		# just verify it's the last value we wrote.
		if loaded.hp != -9:
			_fail("rapid saves did not preserve last write: got %d" % loaded.hp)

	# --- Overwrite with different state ---
	var s2: GameState = GameState.new()
	s2.season = 11
	s2.seed_name = "birch"
	if not sm.save_run(s2):
		_fail("second save_run failed")
	var reloaded: GameState = sm.load_run()
	if reloaded == null:
		_fail("reload returned null")
	elif reloaded.season != 11 or reloaded.seed_name != "birch":
		_fail("overwrite failed: season=%d seed=%s" % [reloaded.season, reloaded.seed_name])

	sm.clear_all()
	_finish()


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_save_atomic (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
