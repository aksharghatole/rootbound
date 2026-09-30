extends SceneTree
## Headless logic test for GameState.
## Run with: godot --headless --script tests/test_game_state.gd
## Exits 0 on success, 1 on failure.

func _init() -> void:
	var failures: int = 0

	# --- Fresh state defaults ---
	var s: GameState = GameState.new()
	if s.season != 1:
		push_error("FAIL: default season should be 1, got %d" % s.season)
		failures += 1
	if s.hp != GameState.STARTING_HP:
		push_error("FAIL: default hp should be %d, got %d" % [GameState.STARTING_HP, s.hp])
		failures += 1
	if s.roots != 1 or s.trunk != 1 or s.leaves != 1:
		push_error("FAIL: default stats should all be 1")
		failures += 1
	if s.growth_points != 2:
		push_error("FAIL: default growth_points should be 2, got %d" % s.growth_points)
		failures += 1

	# --- Alive / won semantics ---
	if not s.is_alive():
		push_error("FAIL: fresh state should be alive")
		failures += 1
	if s.has_won():
		push_error("FAIL: fresh state should not have won")
		failures += 1

	s.hp = 0
	if s.is_alive():
		push_error("FAIL: hp=0 should not be alive")
		failures += 1

	s.hp = 10
	s.season = 12
	if not s.has_won():
		push_error("FAIL: season=12, hp=10 should be a win")
		failures += 1

	# --- Dictionary round-trip ---
	var d: Dictionary = s.to_dictionary()
	if d.get("season", -1) != 12:
		push_error("FAIL: to_dictionary lost season")
		failures += 1
	if d.get("seed_name", "") != "oak":
		push_error("FAIL: to_dictionary lost seed_name")
		failures += 1

	if failures == 0:
		print("PASS: test_game_state (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
