extends SceneTree
## Headless test: SeedLibrary loads seeds.json correctly.
## Run: godot --headless --script tests/test_seed_library.gd

var failures: int = 0


func _init() -> void:
	var lib: SeedLibrary = SeedLibrary.new()

	if lib.count() != 3:
		_fail("expected 3 seeds, got %d" % lib.count())

	var ids: Array = lib.all_ids()
	for expected in ["oak", "willow", "birch"]:
		if not ids.has(expected):
			_fail("missing seed id: %s" % expected)

	# Oak
	var oak: Seed = lib.get_seed("oak")
	if oak == null:
		_fail("oak not found")
	else:
		if oak.starting_roots != 1 or oak.starting_trunk != 1 or oak.starting_leaves != 1:
			_fail("oak starting stats wrong: %d/%d/%d" % [oak.starting_roots, oak.starting_trunk, oak.starting_leaves])
		if oak.starting_hp != 10:
			_fail("oak hp should be 10, got %d" % oak.starting_hp)
		if oak.unlocks_on_win != "willow":
			_fail("oak should unlock willow, got '%s'" % oak.unlocks_on_win)

	# Willow
	var willow: Seed = lib.get_seed("willow")
	if willow == null:
		_fail("willow not found")
	else:
		if willow.starting_leaves != 3:
			_fail("willow leaves should be 3, got %d" % willow.starting_leaves)
		if willow.unlocks_on_win != "birch":
			_fail("willow should unlock birch, got '%s'" % willow.unlocks_on_win)

	# Birch
	var birch: Seed = lib.get_seed("birch")
	if birch == null:
		_fail("birch not found")
	else:
		if birch.starting_roots != 3 or birch.starting_trunk != 2 or birch.starting_leaves != 0:
			_fail("birch starting stats wrong: %d/%d/%d" % [birch.starting_roots, birch.starting_trunk, birch.starting_leaves])
		if birch.unlocks_on_win != "":
			_fail("birch should not unlock anything, got '%s'" % birch.unlocks_on_win)

	# Missing seed returns null
	if lib.get_seed("nonexistent") != null:
		_fail("get_seed for unknown id should return null")

	if failures == 0:
		print("PASS: test_seed_library (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1
