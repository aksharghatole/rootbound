extends SceneTree
## Headless test: simulate a 12-season run with a fixed seed and a simple policy.
## Run: godot --headless --script tests/test_full_run.gd

var failures: int = 0


func _init() -> void:
	_test_survivable_run()
	_test_unwinnable_run()

	if failures == 0:
		print("PASS: test_full_run (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)


func _test_survivable_run() -> void:
	# Policy: always spend on roots first (drought is most common early).
	# With balanced spend, a 12-season run with these numbers should survive.
	var s: GameState = GameState.new()
	s.hp = 40
	s.max_hp = 40
	s.roots = 3
	s.trunk = 3
	s.leaves = 4
	s.growth_points = 0
	s.season = 1
	s.rng_seed = 7

	var rng: RNG = RNG.new(s.rng_seed)
	var es: EventSystem = EventSystem.new()

	var seasons_played: int = 0
	var won: bool = false
	var lost: bool = false

	for i in range(40):  # safety cap
		var r: Dictionary = SeasonSystem.advance_season(s, rng, es)
		s = r["state"] as GameState
		seasons_played += 1
		won = bool(r.get("won", false))
		lost = bool(r.get("lost", false))
		if won or lost:
			break
		# Policy: spend all points evenly across roots/trunk/leaves
		while s.growth_points > 0:
			var pick: String = _weakest_stat(s)
			s = SeasonSystem.spend_growth_point(s, pick)

	if lost:
		_fail("survivable run unexpectedly lost at season %d" % s.season)
	if not won:
		_fail("survivable run did not win within 40 seasons (season=%d)" % s.season)


func _test_unwinnable_run() -> void:
	# Policy: never spend. hp=10, leaves=1. Should die quickly.
	var s: GameState = GameState.new()
	s.hp = 5
	s.max_hp = 5
	s.roots = 0
	s.trunk = 0
	s.leaves = 0
	s.growth_points = 0
	s.season = 1
	s.rng_seed = 99

	var rng: RNG = RNG.new(s.rng_seed)
	var es: EventSystem = EventSystem.new()

	var lost: bool = false
	for i in range(40):
		var r: Dictionary = SeasonSystem.advance_season(s, rng, es)
		s = r["state"] as GameState
		if bool(r.get("lost", false)):
			lost = true
			break
		if bool(r.get("won", false)):
			break

	if not lost:
		_fail("unwinnable run should have lost")


func _weakest_stat(s: GameState) -> String:
	var lowest: int = s.roots
	var pick: String = "roots"
	if s.trunk < lowest:
		lowest = s.trunk
		pick = "trunk"
	if s.leaves < lowest:
		pick = "leaves"
	return pick


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1
