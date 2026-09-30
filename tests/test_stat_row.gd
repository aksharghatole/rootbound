extends SceneTree
## Headless test: StatRow signals and enable/disable behavior.
## Run: godot --headless --script tests/test_stat_row.gd

var failures: int = 0


func _init() -> void:
	process_frame.connect(_on_first_frame, CONNECT_ONE_SHOT)


func _on_first_frame() -> void:
	_run_tests()


func _run_tests() -> void:
	var packed: PackedScene = load("res://scenes/components/StatRow.tscn") as PackedScene
	if packed == null:
		_fail("could not load StatRow.tscn")
		_finish()
		return

	var row: Node = packed.instantiate()
	# add_child triggers _ready()
	root.add_child(row)

	var observed: Dictionary = {"stat": "", "count": 0}
	row.plus_pressed.connect(func(name: String) -> void:
		observed["stat"] = name
		observed["count"] = int(observed["count"]) + 1
	)

	row.configure("Roots", "roots")
	if observed["count"] != 0:
		_fail("configure should not emit plus_pressed")

	row.press_plus_for_test()
	if observed["count"] != 1:
		_fail("press_plus_for_test should emit plus_pressed once")
	if observed["stat"] != "roots":
		_fail("plus_pressed should carry stat_name 'roots', got '%s'" % observed["stat"])

	# Disable plus — signal still fires (button disable only blocks UI input).
	row.set_plus_enabled(false)
	if row.is_plus_enabled():
		_fail("is_plus_enabled should be false after set_plus_enabled(false)")

	row.set_plus_enabled(true)
	if not row.is_plus_enabled():
		_fail("is_plus_enabled should be true after set_plus_enabled(true)")

	# Value label updates
	row.set_value(7)
	var value_label: Label = row.get_node("ValueLabel")
	if value_label.text != "7":
		_fail("set_value(7) did not update ValueLabel, got '%s'" % value_label.text)

	row.free()
	_finish()


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_stat_row (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
