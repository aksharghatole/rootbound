extends HBoxContainer
## StatRow — Milestone 5
## One row: [−] [Label: value] [+]
## Emits signals for plus/minus. Does not talk to GameManager directly —
## GameScreen wires us up. This keeps the row unit-testable headless.

signal plus_pressed(stat_name: String)
signal minus_pressed(stat_name: String)

@onready var minus_button: Button = $MinusButton
@onready var name_label: Label = $NameLabel
@onready var value_label: Label = $ValueLabel
@onready var plus_button: Button = $PlusButton

var stat_name: String = "roots"


func _ready() -> void:
	minus_button.pressed.connect(_on_minus)
	plus_button.pressed.connect(_on_plus)
	_refresh_labels()


func configure(display_name: String, internal_name: String) -> void:
	stat_name = internal_name
	if name_label != null:
		name_label.text = display_name


func set_value(v: int) -> void:
	if value_label != null:
		value_label.text = str(v)


func set_plus_enabled(can_spend: bool) -> void:
	if plus_button != null:
		plus_button.disabled = not can_spend


func is_plus_enabled() -> bool:
	return plus_button != null and not plus_button.disabled


func _refresh_labels() -> void:
	if name_label != null and name_label.text == "":
		name_label.text = stat_name


func _on_plus() -> void:
	plus_pressed.emit(stat_name)


func _on_minus() -> void:
	minus_pressed.emit(stat_name)


## Test helper: simulate a press without needing input events.
func press_plus_for_test() -> void:
	_on_plus()


func press_minus_for_test() -> void:
	_on_minus()
