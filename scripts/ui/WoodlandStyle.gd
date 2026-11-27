extends RefCounted
## Shared accessible woodland controls.

static func _button_style(fill: Color, rim: Color) -> StyleBoxFlat:
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


static func apply(button: Button, primary: bool) -> void:
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


