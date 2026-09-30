extends SceneTree
## Headless scene + GameManager integration test.
## Run with: godot --headless --script tests/test_scene_transition.gd
## Exits 0 on success, 1 on failure.
##
## Note 1: SceneTree._init() runs BEFORE autoloads are attached, so we defer
##         the actual test to _on_first_frame() via process_frame.
## Note 2: GDScript lambdas capture local vars BY VALUE. To observe a signal
##         firing, we mutate a Dictionary (by reference), not a bool.

var failures: int = 0


func _init() -> void:
	# Defer — autoloads aren't in the tree yet during _init().
	process_frame.connect(_on_first_frame, CONNECT_ONE_SHOT)


func _on_first_frame() -> void:
	_run_tests()


func _run_tests() -> void:
	# --- GameManager is registered as an autoload ---
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		push_error("FAIL: GameManager autoload not found")
		quit(1)
		return

	# --- No run active initially ---
	if gm.has_active_run():
		push_error("FAIL: expected no active run at startup")
		failures += 1

	# --- Start a run ---
	var state: GameState = gm.start_new_run()
	if state == null:
		push_error("FAIL: start_new_run returned null")
		quit(1)
		return
	if not gm.has_active_run():
		push_error("FAIL: has_active_run should be true after start_new_run")
		failures += 1
	if state.season != 1:
		push_error("FAIL: new run should begin at season 1")
		failures += 1

	# --- Signal fires on state change ---
	# Dictionary is passed by reference, so the lambda CAN mutate it.
	var observed: Dictionary = {"value": false}
	gm.state_changed.connect(func(_s: GameState) -> void: observed["value"] = true)
	gm.end_run(false)
	if not observed["value"]:
		push_error("FAIL: state_changed signal did not fire on end_run")
		failures += 1
	if gm.has_active_run():
		push_error("FAIL: has_active_run should be false after end_run")
		failures += 1

	# --- MainMenu scene loads ---
	var menu_packed: PackedScene = load("res://scenes/MainMenu.tscn") as PackedScene
	if menu_packed == null:
		push_error("FAIL: could not load MainMenu.tscn")
		quit(1)
		return
	var menu: Node = menu_packed.instantiate()
	if menu == null:
		push_error("FAIL: could not instantiate MainMenu")
		quit(1)
		return
	menu.free()

	# --- GameScreen scene loads ---
	var game_packed: PackedScene = load("res://scenes/GameScreen.tscn") as PackedScene
	if game_packed == null:
		push_error("FAIL: could not load GameScreen.tscn")
		quit(1)
		return
	var game: Node = game_packed.instantiate()
	if game == null:
		push_error("FAIL: could not instantiate GameScreen")
		quit(1)
		return
	game.free()

	if failures == 0:
		print("PASS: test_scene_transition (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
