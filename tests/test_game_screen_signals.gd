extends SceneTree
## Headless test: GameScreen responds to GameManager signals.
## Run: godot --headless --script tests/test_game_screen_signals.gd

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

	# Start a fresh run so GameScreen finds active state.
	gm.start_new_run()

	var packed: PackedScene = load("res://scenes/GameScreen.tscn") as PackedScene
	if packed == null:
		_fail("could not load GameScreen.tscn")
		_finish()
		return

	var screen: Node = packed.instantiate()
	root.add_child(screen)

	# --- Labels reflect current state ---
	var season_label: Label = screen.get_node("TopBar/SeasonLabel")
	var hp_label: Label = screen.get_node("TopBar/HpLabel")
	var points_label: Label = screen.get_node("Body/PointsLabel")

	if not season_label.text.begins_with("Season 1"):
		_fail("season label wrong: '%s'" % season_label.text)
	if not hp_label.text.begins_with("HP 10"):
		_fail("hp label wrong: '%s'" % hp_label.text)

	# --- Advance disabled while points available (fresh run starts at 0 here) ---
	var advance_button: Button = screen.get_node("Body/AdvanceButton")
	# After start_new_run, growth_points = 0, so advance should be enabled.
	if advance_button.disabled:
		_fail("advance button should be enabled when growth_points == 0")

	# --- Spend a point programmatically via GameManager ---
	# Give the state a point to spend.
	var s: GameState = gm.get_state()
	s.growth_points = 1
	gm.state_changed.emit(s)

	var roots_row: Node = screen.get_node("Body/StatRows/RootsRow")
	if not roots_row.is_plus_enabled():
		_fail("roots + button should be enabled when points > 0")

	# Now disable advance because points > 0
	if not advance_button.disabled:
		_fail("advance button should be disabled when growth_points > 0")

	# --- Spend on roots and verify ---
	var before_roots: int = s.roots
	gm.spend_growth_point("roots")
	var after: GameState = gm.get_state()
	if after.roots != before_roots + 1:
		_fail("roots should increase after spend: %d -> %d" % [before_roots, after.roots])

	var roots_value_label: Label = roots_row.get_node("ValueLabel")
	if roots_value_label.text != str(after.roots):
		_fail("roots ValueLabel should update, got '%s'" % roots_value_label.text)

	# --- Event fired signal updates EventLog ---
	gm.event_fired.emit("Drought", 3)
	var event_log: Node = screen.get_node("Body/EventLog")
	var lines: Array = event_log.get_lines()
	if lines.size() != 1:
		_fail("event log should have 1 line, has %d" % lines.size())
	elif not str(lines[0]).begins_with("Drought"):
		_fail("event log line wrong: '%s'" % str(lines[0]))

	screen.free()
	_finish()


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_game_screen_signals (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
