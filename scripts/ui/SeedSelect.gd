extends Control
## SeedSelect — Milestone 6
## Lists seeds. Unlocked seeds startable; locked seeds show a lock.
## Builds buttons dynamically from SeedLibrary — no scene authoring needed
## for each seed.

@onready var title_label: Label = $VBox/TitleLabel
@onready var seed_list: VBoxContainer = $VBox/SeedList
@onready var back_button: Button = $VBox/BackButton


func _ready() -> void:
	print("SeedSelect loaded.")
	back_button.pressed.connect(_on_back)
	_build_list()


func _build_list() -> void:
	for child in seed_list.get_children():
		child.queue_free()

	var lib: SeedLibrary = GameManager.get_seed_library()
	if lib == null:
		return

	var meta: Meta = GameManager.get_meta_data()
	var unlocked: Array = []
	if meta != null:
		unlocked = meta.unlocked_seeds

	for s in lib._seeds:
		var seed_obj: Seed = s as Seed
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 120)
		btn.add_theme_font_size_override("font_size", 24)

		var is_unlocked: bool = unlocked.has(seed_obj.id)
		if is_unlocked:
			btn.text = "%s\n%d/%d/%d  hp %d\n%s" % [
				seed_obj.display_name,
				seed_obj.starting_roots,
				seed_obj.starting_trunk,
				seed_obj.starting_leaves,
				seed_obj.starting_hp,
				seed_obj.passive_description,
			]
			btn.pressed.connect(_on_seed_chosen.bind(seed_obj.id))
		else:
			btn.text = "%s  (Locked)" % seed_obj.display_name
			btn.disabled = true

		seed_list.add_child(btn)


func _on_seed_chosen(seed_id: String) -> void:
	print("Seed chosen: %s" % seed_id)
	GameManager.start_new_run(seed_id)
	get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
