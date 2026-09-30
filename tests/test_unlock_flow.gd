extends SceneTree
## Headless test: winning with a seed unlocks the next.
## Run: godot --headless --script tests/test_unlock_flow.gd
##
## Note: SceneTree scripts can't reference autoloads by global name at
## compile time. Always resolve via root.get_node_or_null("<Name>").

var failures: int = 0


func _init() -> void:
	process_frame.connect(_on_first_frame, CONNECT_ONE_SHOT)


func _on_first_frame() -> void:
	_run_tests()


func _run_tests() -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_fail("GameManager autoload not found")
		_finish()
		return
	var sm: Node = root.get_node_or_null("SaveManager")
	if sm == null:
		_fail("SaveManager autoload not found")
		_finish()
		return

	sm.save_path = "user://test_unlock_run.json"
	sm.meta_path = "user://test_unlock_meta.json"
	sm.clear_all()

	# Force meta to start clean
	gm.meta = Meta.new()
	sm.save_meta(gm.meta)

	if gm.meta.unlocked_seeds.has("willow"):
		_fail("willow should not be unlocked initially")

	# Watch seed_unlocked signal
	var observed_unlock: Dictionary = {"id": ""}
	gm.seed_unlocked.connect(func(seed_id: String) -> void:
		observed_unlock["id"] = seed_id
	)

	# Win as oak -> unlock willow
	var oak: GameState = gm.start_new_run("oak")
	oak.season = 13
	gm.end_run(true)

	if not gm.meta.unlocked_seeds.has("willow"):
		_fail("winning as oak should unlock willow")
	if observed_unlock["id"] != "willow":
		_fail("seed_unlocked should fire with 'willow', got '%s'" % observed_unlock["id"])

	# Win as willow -> unlock birch
	var willow: GameState = gm.start_new_run("willow")
	willow.season = 13
	gm.end_run(true)
	if not gm.meta.unlocked_seeds.has("birch"):
		_fail("winning as willow should unlock birch")

	# Win as birch -> nothing new
	var before_count: int = gm.meta.unlocked_seeds.size()
	var birch: GameState = gm.start_new_run("birch")
	birch.season = 13
	gm.end_run(true)
	if gm.meta.unlocked_seeds.size() != before_count:
		_fail("winning as birch should not unlock anything new")

	# Loss as oak does NOT unlock
	gm.meta = Meta.new()
	sm.save_meta(gm.meta)
	var oak2: GameState = gm.start_new_run("oak")
	oak2.season = 5
	gm.end_run(false)
	if gm.meta.unlocked_seeds.has("willow"):
		_fail("losing as oak should NOT unlock willow")

	sm.clear_all()
	_finish()


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_unlock_flow (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
