extends SceneTree
## Headless boot test for Milestone 1.
## Run with: godot --headless --script tests/test_boot.gd
## Exits 0 on success, 1 on failure.

func _init() -> void:
	var main_scene_path := "res://scenes/MainMenu.tscn"
	var packed := load(main_scene_path)
	if packed == null:
		push_error("FAILED: could not load %s" % main_scene_path)
		quit(1)
		return

	var instance := packed.instantiate()
	if instance == null:
		push_error("FAILED: could not instantiate MainMenu")
		quit(1)
		return

	print("PASS: MainMenu.tscn loaded and instantiated.")
	instance.free()
	quit(0)
