extends Control

const WoodlandStyle = preload("res://scripts/ui/WoodlandStyle.gd")
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
	WoodlandStyle.apply(new_run_button, true)
	WoodlandStyle.apply(continue_button, false)
	WoodlandStyle.apply(quit_button, false)
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
