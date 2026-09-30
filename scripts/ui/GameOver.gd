extends Control
## GameOver — Milestone 6
## Shows result. Retry restarts with the last-used seed (fallback: oak).

@onready var result_label: Label = $VBox/ResultLabel
@onready var detail_label: Label = $VBox/DetailLabel
@onready var retry_button: Button = $VBox/RetryButton
@onready var menu_button: Button = $VBox/MenuButton

var last_seed_name: String = "oak"


func _ready() -> void:
	print("GameOver loaded.")

	# SeedSelect passes the last seed via a static-ish mechanism: we read it
	# from the meta history OR default. For MVP, use oak. Retry resets.
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)
	_refresh()


func set_last_seed(seed_id: String) -> void:
	last_seed_name = seed_id


func _refresh() -> void:
	var meta: Meta = GameManager.get_meta_data()
	if meta == null:
		result_label.text = "Run ended"
		detail_label.text = ""
		return

	if meta.best_season >= 12:
		result_label.text = "Survived 12 Seasons!"
	else:
		result_label.text = "Season %d — Tree Died" % meta.best_season

	detail_label.text = "Best: Season %d   •   Runs: %d" % [
		meta.best_season, meta.total_runs
	]


func _on_retry() -> void:
	GameManager.start_new_run(last_seed_name)
	get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
