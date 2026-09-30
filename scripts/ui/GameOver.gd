extends Control
## GameOver — Milestone 5
## Reads meta for best_season. Buttons: Retry, Main Menu.

@onready var result_label: Label = $VBox/ResultLabel
@onready var detail_label: Label = $VBox/DetailLabel
@onready var retry_button: Button = $VBox/RetryButton
@onready var menu_button: Button = $VBox/MenuButton


func _ready() -> void:
	print("GameOver loaded.")
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)
	_refresh()


func _refresh() -> void:
	var meta: Meta = GameManager.get_meta()
	if meta == null:
		result_label.text = "Run ended"
		detail_label.text = ""
		return

	# We don't know win/lose directly here — GameManager cleared state.
	# Use a simple heuristic: if best_season >= 12, assume win.
	if meta.best_season >= 12:
		result_label.text = "Survived 12 Seasons!"
	else:
		result_label.text = "Season %d — Tree Died" % meta.best_season

	detail_label.text = "Best: Season %d   •   Runs: %d" % [
		meta.best_season, meta.total_runs
	]


func _on_retry() -> void:
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
