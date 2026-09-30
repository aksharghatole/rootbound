extends Node
## SaveManager — Milestone 1 stub.
## Real save/load lands in Milestone 6.

const SAVE_PATH := "user://save.json"

func _ready() -> void:
	print("SaveManager ready. Save path: ", SAVE_PATH)
