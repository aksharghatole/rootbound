extends Control

const SafeArea = preload("res://scripts/util/SafeArea.gd")
## MainMenu — Milestone 7
## New Run -> SeedSelect. Continue resumes save. All buttons play 'tap'.

@onready var new_run_button: Button = $ButtonBox/NewRunButton
@onready var continue_button: Button = $ButtonBox/ContinueButton
@onready var quit_button: Button = $ButtonBox/QuitButton
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	SafeArea.attach(self, [$TitleLabel, $Subtitle, $ButtonBox, $StatusLabel, $VersionLabel])
	$VersionLabel.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	_style_button(new_run_button, true)
	_style_button(continue_button, false)
	_style_button(quit_button, false)
	print("Rootbound booted.")
	print("MainMenu scene loaded.")

	new_run_button.pressed.connect(_on_new_run_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	continue_button.disabled = not SaveManager.has_save()

	var meta: Meta = SaveManager.load_meta()
	if meta != null and meta.best_season > 0:
		status_label.text = "Best: Season %d" % meta.best_season
	else:
		status_label.text = ""


func _button_style(fill: Color, rim: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = rim
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _style_button(button: Button, primary: bool) -> void:
	var fill := Color("#526c43") if primary else Color("#20382f")
	var rim := Color("#c1ad72") if primary else Color("#627960")
	button.add_theme_stylebox_override("normal", _button_style(fill, rim))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.12), Color("#e3ca84")))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.18), rim))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#182723"), Color("#3a5044")))
	var focus := _button_style(Color.TRANSPARENT, Color("#f0d98f"))
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color("#f5efda"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("#f5efda"))
	button.add_theme_color_override("font_disabled_color", Color("#88978b"))


func _on_new_run_pressed() -> void:
	AudioManager.play_sfx("tap")
	print("New Run — going to seed select")
	get_tree().change_scene_to_file("res://scenes/SeedSelect.tscn")


func _on_continue_pressed() -> void:
	AudioManager.play_sfx("tap")
	print("Continue pressed")
	var s: GameState = GameManager.resume_run()
	if s == null:
		print("Continue: no valid save. Starting fresh with oak.")
		GameManager.start_new_run("oak")
	get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")


func _on_quit_pressed() -> void:
	AudioManager.play_sfx("tap")
	print("Quit pressed")
	get_tree().quit()
