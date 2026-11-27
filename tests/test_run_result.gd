extends SceneTree

var failures: int = 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _expect(ok: bool, message: String) -> void:
	if not ok:
		push_error("FAIL: " + message)
		failures += 1

func _run() -> void:
	var gm: Node = root.get_node("GameManager")
	var sm: Node = root.get_node("SaveManager")
	sm.save_path = "user://test_result_run.json"
	sm.meta_path = "user://test_result_meta.json"
	sm.clear_all()
	gm.meta = Meta.new()
	var state: GameState = gm.start_new_run("oak")
	state.season = 12
	gm.end_run(true)
	var packed: PackedScene = load("res://scenes/GameOver.tscn")
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	_expect(screen.get_node("VBox/ResultLabel").text == "Survived 12 Seasons!", "winning result")
	screen.free()

	state = gm.start_new_run("willow")
	state.season = 3
	state.hp = 0
	gm.end_run(false)
	screen = packed.instantiate()
	root.add_child(screen)
	_expect(screen.get_node("VBox/ResultLabel").text == "Season 3 — Tree Died", "loss after earlier win")
	_expect(screen.last_seed_name == "willow", "retry preserves the actual seed")
	_expect(screen.get_node("VBox/DetailLabel").text.contains("Best: Season 12"), "best season remains separate")
	screen.free()
	sm.clear_all()

	var log_scene: PackedScene = load("res://scenes/components/EventLog.tscn")
	var log: VBoxContainer = log_scene.instantiate()
	root.add_child(log)
	for i in range(5):
		log.add_line("Event %d" % i)
	_expect(log.get_child_count() == 3, "no duplicate pending labels")
	_expect(log.get_lines() == ["Event 2", "Event 3", "Event 4"], "only recent events")
	log.clear_log()
	_expect(log.get_child_count() == 0, "clearing removes all labels immediately")
	log.free()
	if failures == 0:
		print("PASS: run results and event log")
	quit(0 if failures == 0 else 1)
