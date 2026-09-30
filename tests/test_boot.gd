extends SceneTree
## Headless boot test for Milestone 1.
## Run with: godot --headless --script tests/test_boot.gd
## Exits 0 on success, 1 on failure.

func _init() -> void:
	var main_scene_path: String = "res://scenes/MainMenu.tscn"
	var packed: PackedScene = load(main_scene_path) as PackedScene
	if packed == null:
		push_error("FAILED: could not load %s" % main_scene_path)
		quit(1)
		return

	var instance: Node = packed.instantiate()
	if instance == null:
		push_error("FAILED: could not instantiate MainMenu")
		quit(1)
		return

	print("PASS: MainMenu.tscn loaded and instantiated.")
	instance.free()
	quit(0)
