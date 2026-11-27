extends SceneTree
## Verify the actual main menu after autoloads are registered.

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	var packed: PackedScene = load("res://scenes/MainMenu.tscn") as PackedScene
	if packed == null:
		push_error("FAILED: could not load MainMenu")
		quit(1)
		return
	var instance: Control = packed.instantiate() as Control
	if instance == null or instance.get_script() == null:
		push_error("FAILED: MainMenu did not instantiate with its script")
		if instance != null:
			instance.free()
		quit(1)
		return
	root.add_child(instance)
	var new_run: Button = instance.get_node_or_null("ButtonBox/NewRunButton")
	var version: Label = instance.get_node_or_null("VersionLabel")
	if new_run == null or new_run.pressed.get_connections().is_empty() or version == null or version.text != "v%s" % ProjectSettings.get_setting("application/config/version"):
		push_error("FAILED: MainMenu ready logic did not initialize")
		instance.free()
		quit(1)
		return
	instance.free()
	print("PASS: MainMenu loaded, ready and connected.")
	quit(0)
