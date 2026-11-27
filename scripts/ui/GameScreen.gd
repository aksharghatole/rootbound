extends Control

const WoodlandStyle = preload("res://scripts/ui/WoodlandStyle.gd")
const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]
const SafeArea = preload("res://scripts/util/SafeArea.gd")
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
	SafeArea.attach(self, [$TopBar, $Body])
	WoodlandStyle.apply(advance_button, true)
	WoodlandStyle.apply(menu_button, false)
	_setup_progress()
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

	season_label.text = "Season %d / 12 · %s" % [mini(s.season, 12), SEASON_NAMES[(clampi(s.season, 1, 12) - 1) % 4]]
	$Body/SeasonProgress.value = mini(s.season, 12)
	hp_label.add_theme_color_override("font_color", Color("#d58c76").lerp(Color("#c5dc9b"), clampf(float(s.hp) / maxf(1.0, float(s.max_hp)), 0.0, 1.0)))
	hp_label.text = "HP %d / %d" % [s.hp, s.max_hp]

	roots_row.set_value(s.roots)
	trunk_row.set_value(s.trunk)
	leaves_row.set_value(s.leaves)

	points_label.text = "Growth points: %d" % s.growth_points
	points_label.add_theme_color_override("font_color", Color("#e4cc89") if s.growth_points > 0 else Color("#a5b6a5"))
	$Body/GrowthHint.text = "Choose where your tree grows." if s.growth_points > 0 else "Your tree is ready for the next season."

	var can_spend: bool = s.growth_points > 0
	roots_row.set_plus_enabled(can_spend)
	trunk_row.set_plus_enabled(can_spend)
	leaves_row.set_plus_enabled(can_spend)

	advance_button.disabled = s.growth_points > 0
	advance_button.text = "Allocate growth first" if advance_button.disabled else ("Finish final season" if s.season >= 12 else "Advance to " + SEASON_NAMES[s.season % 4])

	tree_visual.set_species(s.seed_name)
	tree_visual.set_season(s.season)
	tree_visual.set_stats(s.roots, s.trunk, s.leaves, s.hp, s.max_hp)


func _setup_progress() -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#20382f")
	background.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#bfa96c")
	fill.set_corner_radius_all(5)
	$Body/SeasonProgress.add_theme_stylebox_override("background", background)
	$Body/SeasonProgress.add_theme_stylebox_override("fill", fill)


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
		event_log.add_line("%s · %s" % [event_name, "No damage" if damage <= 0 else "−%d HP" % damage])


func _on_run_ended(won: bool) -> void:
	if won:
		AudioManager.play_sfx("win")
	else:
		AudioManager.play_sfx("death")
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


func press_advance_for_test() -> void:
	_on_advance_pressed()
