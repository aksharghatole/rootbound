extends SceneTree
## Headless test: corrupt and malformed saves must recover gracefully.
## Run: godot --headless --script tests/test_save_corrupt.gd

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

	sm.save_path = "user://test_corrupt.json"
	sm.meta_path = "user://test_corrupt_meta.json"
	sm.clear_all()

	# --- Case 1: file exists but is not valid JSON ---
	_write_text(sm.save_path, "{ not json ][")
	var s1: GameState = sm.load_run()
	if s1 != null:
		_fail("corrupt JSON should return null, got %s" % str(s1))

	# --- Case 2: valid JSON but missing 'state' key ---
	_write_text(sm.save_path, JSON.stringify({"version": 1}))
	var s2: GameState = sm.load_run()
	if s2 != null:
		_fail("missing 'state' key should return null")

	# --- Case 3: 'state' present but missing required fields ---
	_write_text(sm.save_path, JSON.stringify({
		"version": 1,
		"state": {"season": 1, "hp": 10}
	}))
	var s3: GameState = sm.load_run()
	if s3 != null:
		_fail("partial state should return null")

	# --- Case 4: file simply missing ---
	sm.clear_all()
	if sm.has_save():
		_fail("has_save true after clear_all")
	var s4: GameState = sm.load_run()
	if s4 != null:
		_fail("missing file should return null")

	# --- Case 5: meta file corrupt — should return fresh Meta, not null ---
	_write_text(sm.meta_path, "garbage")
	var m: Meta = sm.load_meta()
	if m == null:
		_fail("load_meta on corrupt file should return fresh Meta, not null")
	else:
		if m.total_runs != 0 or m.best_season != 0:
			_fail("fresh Meta should have zero stats")

	sm.clear_all()
	_finish()


func _write_text(path: String, text: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_fail("could not open %s for write" % path)
		return
	f.store_string(text)
	f.close()


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_save_corrupt (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
