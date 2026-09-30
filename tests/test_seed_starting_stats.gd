extends SceneTree
## Headless test: start_new_run(seed) applies starting stats.
## Run: godot --headless --script tests/test_seed_starting_stats.gd

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

	# Oak
	var oak: GameState = gm.start_new_run("oak")
	if oak == null:
		_fail("start_new_run('oak') returned null")
		_finish()
		return
	if oak.seed_name != "oak":
		_fail("seed_name should be 'oak', got '%s'" % oak.seed_name)
	if oak.hp != 10 or oak.max_hp != 10:
		_fail("oak hp should be 10/10, got %d/%d" % [oak.hp, oak.max_hp])
	if oak.roots != 1 or oak.trunk != 1 or oak.leaves != 1:
		_fail("oak stats wrong")

	# Willow
	var willow: GameState = gm.start_new_run("willow")
	if willow == null:
		_fail("start_new_run('willow') returned null")
		_finish()
		return
	if willow.seed_name != "willow":
		_fail("seed_name should be 'willow'")
	if willow.hp != 8:
		_fail("willow hp should be 8, got %d" % willow.hp)
	if willow.leaves != 3:
		_fail("willow leaves should be 3, got %d" % willow.leaves)

	# Birch
	var birch: GameState = gm.start_new_run("birch")
	if birch == null:
		_fail("start_new_run('birch') returned null")
		_finish()
		return
	if birch.seed_name != "birch":
		_fail("seed_name should be 'birch'")
	if birch.hp != 12:
		_fail("birch hp should be 12, got %d" % birch.hp)
	if birch.roots != 3 or birch.trunk != 2 or birch.leaves != 0:
		_fail("birch stats wrong: %d/%d/%d" % [birch.roots, birch.trunk, birch.leaves])
	if birch.passive_used:
		_fail("birch passive_used should start false")

	# Unknown seed falls back to default
	var fallback: GameState = gm.start_new_run("not_a_real_seed")
	if fallback == null:
		_fail("unknown seed should fall back, got null")
	elif fallback.seed_name != "oak":
		_fail("unknown seed should fall back to oak, got '%s'" % fallback.seed_name)

	gm.end_run(false)
	_finish()


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_seed_starting_stats (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
