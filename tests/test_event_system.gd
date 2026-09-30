extends SceneTree
## Headless test for EventSystem: load, damage formulas, weight shift, determinism.
## Run: godot --headless --script tests/test_event_system.gd

var failures: int = 0


func _init() -> void:
	_test_load()
	_test_damage_formulas()
	_test_weight_shift()
	_test_determinism()

	if failures == 0:
		print("PASS: test_event_system (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)


func _test_load() -> void:
	var es: EventSystem = EventSystem.new()
	if es.event_count() != 3:
		_fail("expected 3 events, got %d" % es.event_count())
	for id in ["drought", "pest", "frost"]:
		var e: Dictionary = es.get_event_by_id(id)
		if e.is_empty():
			_fail("missing event: %s" % id)


func _test_damage_formulas() -> void:
	var es: EventSystem = EventSystem.new()
	var drought: Dictionary = es.get_event_by_id("drought")
	var pest: Dictionary = es.get_event_by_id("pest")
	var frost: Dictionary = es.get_event_by_id("frost")

	# Roots 1 -> 5 - 1 = 4
	var s: GameState = GameState.new()
	if es.compute_damage(drought, s) != 4:
		_fail("drought @ roots=1 should be 4")

	# Roots 5 -> max(0, 0) = 0
	s.roots = 5
	if es.compute_damage(drought, s) != 0:
		_fail("drought @ roots=5 should be 0")

	# Roots 10 -> clamped 0
	s.roots = 10
	if es.compute_damage(drought, s) != 0:
		_fail("drought @ roots=10 should be 0")

	# Pest: leaves=1 -> 4 - 1 = 3
	s = GameState.new()
	if es.compute_damage(pest, s) != 3:
		_fail("pest @ leaves=1 should be 3")

	s.leaves = 4
	if es.compute_damage(pest, s) != 0:
		_fail("pest @ leaves=4 should be 0")

	# Frost: trunk=1 -> 5 - 1 = 4
	s = GameState.new()
	if es.compute_damage(frost, s) != 4:
		_fail("frost @ trunk=1 should be 4")

	s.trunk = 5
	if es.compute_damage(frost, s) != 0:
		_fail("frost @ trunk=5 should be 0")


func _test_weight_shift() -> void:
	var es: EventSystem = EventSystem.new()
	var w1: PackedInt32Array = es.weights_for_season(1)
	var w12: PackedInt32Array = es.weights_for_season(12)

	# Season 1: drought=10, pest=8, frost=6
	if w1[0] != 10 or w1[1] != 8 or w1[2] != 6:
		_fail("season 1 weights wrong: %s" % str(w1))

	# Season 12: drought=10+11=21, pest=8+11=19, frost=6+22=28
	if w12[0] != 21 or w12[1] != 19 or w12[2] != 28:
		_fail("season 12 weights wrong: %s" % str(w12))

	# Frost should grow faster than drought: 28-6 = 22 vs 21-10 = 11
	var frost_growth: int = w12[2] - w1[2]
	var drought_growth: int = w12[0] - w1[0]
	if frost_growth <= drought_growth:
		_fail("frost should escalate faster than drought")


func _test_determinism() -> void:
	var es: EventSystem = EventSystem.new()
	var rng_a: RNG = RNG.new(42)
	var rng_b: RNG = RNG.new(42)

	var seq_a: Array = []
	var seq_b: Array = []
	for i in range(20):
		var a: Dictionary = es.pick_event(1 + i, rng_a)
		var b: Dictionary = es.pick_event(1 + i, rng_b)
		seq_a.append(a.get("id", "?"))
		seq_b.append(b.get("id", "?"))

	if seq_a != seq_b:
		_fail("same seed must give same sequence")
	if seq_a.is_empty():
		_fail("sequence should not be empty")


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1
