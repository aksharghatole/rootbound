extends VBoxContainer
## EventLog — Milestone 5
## Rolling list of recent events. Keeps last N.

const MAX_LINES: int = 3

var _lines: Array = []


func _ready() -> void:
	pass


func add_line(text: String) -> void:
	_lines.append(text)
	while _lines.size() > MAX_LINES:
		_lines.pop_front()
	_refresh()


func clear_log() -> void:
	_lines.clear()
	_refresh()


func get_lines() -> Array:
	return _lines.duplicate()


func _refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for line in _lines:
		var lbl: Label = Label.new()
		lbl.text = str(line)
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.add_theme_color_override("font_color", Color("#e0a690") if str(line).contains("−") else Color("#b8c7a9"))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(lbl)
