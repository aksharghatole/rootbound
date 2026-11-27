extends Control

const WoodlandStyle = preload("res://scripts/ui/WoodlandStyle.gd")
const SafeArea = preload("res://scripts/util/SafeArea.gd")
## SeedSelect — Milestone 7
## Lists seeds. Unlocked seeds startable. Buttons play 'tap'.

@onready var title_label: Label = $VBox/TitleLabel
@onready var seed_list: VBoxContainer = $VBox/SeedList
@onready var back_button: Button = $VBox/BackButton


func _ready() -> void:
	SafeArea.attach(self, [$VBox])
	print("SeedSelect loaded.")
	WoodlandStyle.apply(back_button, false)
	back_button.pressed.connect(_on_back)
	_build_list()


func _build_list() -> void:
	for child in seed_list.get_children():
		seed_list.remove_child(child)
		child.queue_free()

	var lib: SeedLibrary = GameManager.get_seed_library()
	if lib == null:
		return

	var meta: Meta = GameManager.get_meta_data()
	var unlocked: Array = []
	if meta != null:
		unlocked = meta.unlocked_seeds

	for id in lib.all_ids():
		var seed_obj: Seed = lib.get_seed(str(id))
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 180)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_constant_override("icon_max_width", 96)
		btn.icon = load("res://assets/art/seed_%s.svg" % seed_obj.id) as Texture2D
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var is_unlocked: bool = unlocked.has(seed_obj.id)
		WoodlandStyle.apply(btn, is_unlocked)
		btn.name = "Seed_" + seed_obj.id
		var requirement: String = ""
		if not is_unlocked:
			for previous_id in lib.all_ids():
				var previous: Seed = lib.get_seed(str(previous_id))
				if previous.unlocks_on_win == seed_obj.id:
					requirement = "\nUnlock: survive with " + previous.display_name
					break
		btn.text = "%s%s\nRoots %d  ·  Trunk %d  ·  Leaves %d  ·  HP %d\n%s%s" % [
			seed_obj.display_name, "" if is_unlocked else " (Locked)",
			seed_obj.starting_roots, seed_obj.starting_trunk, seed_obj.starting_leaves,
			seed_obj.starting_hp, seed_obj.passive_description, requirement
		]
		btn.disabled = not is_unlocked
		if is_unlocked:
			btn.pressed.connect(_on_seed_chosen.bind(seed_obj.id))

		seed_list.add_child(btn)


func _on_seed_chosen(seed_id: String) -> void:
	AudioManager.play_sfx("tap")
	print("Seed chosen: %s" % seed_id)
	GameManager.start_new_run(seed_id)
	get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")


func _on_back() -> void:
	AudioManager.play_sfx("tap")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
