extends Control

const WoodlandStyle = preload("res://scripts/ui/WoodlandStyle.gd")
const SafeArea = preload("res://scripts/util/SafeArea.gd")
## GameOver — Milestone 7
## Result display. Buttons play 'tap'. Win/death SFX fired by GameScreen.

@onready var result_label: Label = $VBox/ResultLabel
@onready var detail_label: Label = $VBox/DetailLabel
@onready var retry_button: Button = $VBox/RetryButton
@onready var menu_button: Button = $VBox/MenuButton

var last_seed_name: String = "oak"


func _ready() -> void:
	SafeArea.attach(self, [$VBox])
	WoodlandStyle.apply(retry_button, true)
	WoodlandStyle.apply(menu_button, false)
	print("GameOver loaded.")
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)
	_refresh()


func set_last_seed(seed_id: String) -> void:
	last_seed_name = seed_id


func _refresh() -> void:
	var meta: Meta = GameManager.get_meta_data()
	if meta == null:
		result_label.text = "Run ended"
		retry_button.disabled = true
		detail_label.text = ""
		return

	var result: Dictionary = GameManager.get_last_run_result()
	if result.is_empty():
		result_label.text = "Run ended"
		retry_button.disabled = true
	else:
		last_seed_name = str(result["seed_id"])
		var won: bool = bool(result["won"])
		$VBox/Emblem.texture = load("res://assets/art/seed_%s.svg" % last_seed_name) as Texture2D
		$VBox/Emblem.modulate = Color.WHITE if won else Color("#9a9690")
		$VBox/ChapterLabel.text = "THE FOREST REMEMBERS" if won else "THE EARTH RECLAIMS"
		$VBox/MessageLabel.text = "Your roots endure. A new chapter awaits." if won else "Every fallen tree nourishes the next beginning."
		result_label.add_theme_color_override("font_color", Color("#e5d298") if won else Color("#d3b8a1"))
		if bool(result["won"]):
			result_label.text = "Survived 12 Seasons!"
		else:
			result_label.text = "Season %d — Tree Died" % int(result["season"])

	detail_label.text = "Best: Season %d   •   Runs: %d" % [
		meta.best_season, meta.total_runs
	]


func _on_retry() -> void:
	AudioManager.play_sfx("tap")
	GameManager.start_new_run(last_seed_name)
	get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")


func _on_menu() -> void:
	AudioManager.play_sfx("tap")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
