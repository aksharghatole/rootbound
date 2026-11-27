extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var gm: Node = root.get_node("GameManager")
	gm.meta = Meta.new()
	var packed: PackedScene = load("res://scenes/SeedSelect.tscn")
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	var list: VBoxContainer = screen.get_node("VBox/SeedList")
	var oak: Button = list.get_node("Seed_oak")
	var willow: Button = list.get_node("Seed_willow")
	var birch: Button = list.get_node("Seed_birch")
	var ok: bool = list.get_child_count() == 3 and not oak.disabled and willow.disabled and birch.disabled
	ok = ok and oak.icon != null and willow.icon != null and birch.icon != null
	ok = ok and willow.text.contains("Unlock:") and oak.text.contains("Roots")
	gm.meta.unlock_seed("willow")
	screen._build_list()
	willow = list.get_node("Seed_willow")
	ok = ok and list.get_child_count() == 3 and not willow.disabled
	screen.free()
	if ok:
		print("PASS: illustrated seed selection")
	else:
		push_error("FAIL: illustrated seed selection")
	quit(0 if ok else 1)
