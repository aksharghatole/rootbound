extends Control
## GameScreen — Milestone 5
## Wires UI components to GameManager signals. Never mutates state directly.

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

	# If no run is active (e.g. someone opened GameScreen directly), start one
	# so the screen is never in a broken state. In real play, MainMenu already
	# started or resumed a run.
	if GameManager.get_state() == null:
		GameManager.start_new_run("oak")

	# Subscribe to GameManager signals.
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.event_fired.connect(_on_event_fired)
	GameManager.run_ended.connect(_on_run_ended)

	_refresh()


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

	# Can only advance when all points have been spent.
	advance_button.disabled = s.growth_points > 0

	tree_visual.set_stats(s.roots, s.trunk, s.leaves, s.hp, s.max_hp)


func _on_spend(stat_name: String) -> void:
	GameManager.spend_growth_point(stat_name)


func _on_minus(_stat_name: String) -> void:
	# No-op for MVP. Refund feature is future work.
	pass


func _on_advance_pressed() -> void:
	GameManager.advance_season()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_state_changed(_state: GameState) -> void:
	_refresh()


func _on_event_fired(event_name: String, damage: int) -> void:
	if event_log != null:
		event_log.add_line("%s (−%d HP)" % [event_name, damage])


func _on_run_ended(won: bool) -> void:
	var meta: Meta = GameManager.get_meta_data()
	var final_season: int = 0
	# current_state is null by the time run_ended fires; read from meta for best.
	if meta != null:
		final_season = meta.best_season
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


## Test helper
func press_advance_for_test() -> void:
	_on_advance_pressed()
