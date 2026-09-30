extends Control
## GameScreen — Milestone 7
## Wires UI to GameManager signals. Plays tap/event SFX. Starts ambient music.

@onready var season_label: Label = $TopBar/SeasonLabel
@onready var hp_label: Label = $TopBar/HpLabel
@onready var tree_visual: Control = $Body/TreeVisual
@onready var stat_rows: VBoxContainer = $Body/StatRows
@onready var roots_row: HBoxContainer = $Body/StatRows/RootsRow
@onready var trunk_row: HBoxContainer = $Body/StatRows/TrunkRow
@onready var leaves_row: HBoxContainer = $Body/StatRows/LeavesRow
@onready var points_label: Label = $Body/PointsLabel
@onready var event_log: VBoxContainer = $Body/EventLog
@onready var advance_button: Button = $Body/AdvanceButton
@onready var menu_button: Button = $Body/MenuButton


func _ready() -> void:
	print("GameScreen loaded.")

	roots_row.configure("Roots", "roots")
	trunk_row.configure("Trunk", "trunk")
	leaves_row.configure("Leaves", "leaves")

	roots_row.plus_pressed.connect(_on_spend)
	trunk_row.plus_pressed.connect(_on_spend)
	leaves_row.plus_pressed.connect(_on_spend)
	roots_row.minus_pressed.connect(_on_minus)
	trunk_row.minus_pressed.connect(_on_minus)
	leaves_row.minus_pressed.connect(_on_minus)

	advance_button.pressed.connect(_on_advance_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	if GameManager.get_state() == null:
		GameManager.start_new_run("oak")

	GameManager.state_changed.connect(_on_state_changed)
	GameManager.event_fired.connect(_on_event_fired)
	GameManager.run_ended.connect(_on_run_ended)

	AudioManager.play_music("ambient")

	_refresh()


func _exit_tree() -> void:
	# Stop ambient when we leave this screen.
	AudioManager.stop_music()


func _refresh() -> void:
	var s: GameState = GameManager.get_state()
	if s == null:
		return

	season_label.text = "Season %d / 12" % s.season
	hp_label.text = "HP %d / %d" % [s.hp, s.max_hp]

	roots_row.set_value(s.roots)
	trunk_row.set_value(s.trunk)
	leaves_row.set_value(s.leaves)

	points_label.text = "Points: %d" % s.growth_points

	var can_spend: bool = s.growth_points > 0
	roots_row.set_plus_enabled(can_spend)
	trunk_row.set_plus_enabled(can_spend)
	leaves_row.set_plus_enabled(can_spend)

	advance_button.disabled = s.growth_points > 0

	tree_visual.set_stats(s.roots, s.trunk, s.leaves, s.hp, s.max_hp)


func _on_spend(stat_name: String) -> void:
	AudioManager.play_sfx("tap")
	GameManager.spend_growth_point(stat_name)


func _on_minus(_stat_name: String) -> void:
	pass


func _on_advance_pressed() -> void:
	AudioManager.play_sfx("tap")
	GameManager.advance_season()


func _on_menu_pressed() -> void:
	AudioManager.play_sfx("tap")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_state_changed(_state: GameState) -> void:
	_refresh()


func _on_event_fired(event_name: String, damage: int) -> void:
	AudioManager.play_sfx("event")
	if event_log != null:
		event_log.add_line("%s (−%d HP)" % [event_name, damage])


func _on_run_ended(won: bool) -> void:
	if won:
		AudioManager.play_sfx("win")
	else:
		AudioManager.play_sfx("death")
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


func press_advance_for_test() -> void:
	_on_advance_pressed()
