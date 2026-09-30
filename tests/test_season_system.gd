extends SceneTree
## Headless test for SeasonSystem growth-point math and season advance.
## Run: godot --headless --script tests/test_season_system.gd

var failures: int = 0


func _init() -> void:
	_test_growth_points()
	_test_spend()
	_test_advance_pure()

	if failures == 0:
		print("PASS: test_season_system (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)


func _test_growth_points() -> void:
	# 1 + floor(leaves / 3)
	if SeasonSystem.growth_points_for(0) != 1:
		_fail("leaves=0 should give 1")
	if SeasonSystem.growth_points_for(1) != 1:
		_fail("leaves=1 should give 1")
	if SeasonSystem.growth_points_for(2) != 1:
		_fail("leaves=2 should give 1")
	if SeasonSystem.growth_points_for(3) != 2:
		_fail("leaves=3 should give 2")
	if SeasonSystem.growth_points_for(5) != 2:
		_fail("leaves=5 should give 2")
	if SeasonSystem.growth_points_for(6) != 3:
		_fail("leaves=6 should give 3")
	if SeasonSystem.growth_points_for(9) != 4:
		_fail("leaves=9 should give 4")


func _test_spend() -> void:
	var s: GameState = GameState.new()
	s.growth_points = 2

	var s1: GameState = SeasonSystem.spend_growth_point(s, "roots")
	if s1.roots != 2 or s1.growth_points != 1:
		_fail("spend on roots should give roots=2, gp=1")
	if s.roots != 1 or s.growth_points != 2:
		_fail("spend_growth_point must not mutate caller state")

	var s2: GameState = SeasonSystem.spend_growth_point(s, "bogus")
	if s2.growth_points != 2:
		_fail("spending on unknown stat should not decrement")

	var s3: GameState = GameState.new()
	s3.growth_points = 0
	var s4: GameState = SeasonSystem.spend_growth_point(s3, "roots")
	if s4.roots != 1 or s4.growth_points != 0:
		_fail("spending with 0 points should be a no-op")


func _test_advance_pure() -> void:
	# Set up a high-stat state so no event can damage it much.
	var s: GameState = GameState.new()
	s.roots = 10
	s.trunk = 10
	s.leaves = 10
	s.hp = 10
	s.season = 1
	s.growth_points = 0

	var rng: RNG = RNG.new(12345)
	var events: EventSystem = EventSystem.new()

	var result: Dictionary = SeasonSystem.advance_season(s, rng, events)
	var ns: GameState = result["state"] as GameState

	if ns == null:
		_fail("advance_season returned null state")
		return
	if ns.season != 2:
		_fail("season should advance 1 -> 2, got %d" % ns.season)
	if s.season != 1:
		_fail("advance_season must not mutate caller state")
	# leaves=10 -> growth = 1 + 3 = 4
	if ns.growth_points != 4:
		_fail("expected 4 growth points after season 2 start, got %d" % ns.growth_points)


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1
