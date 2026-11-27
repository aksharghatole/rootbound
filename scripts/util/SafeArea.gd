extends RefCounted
## Converts physical Android cutout insets to the logical canvas.
## Vector4 order: left, top, right, bottom.

static func calculate(safe_rect: Rect2, window_rect: Rect2, logical_size: Vector2) -> Vector4:
	if logical_size.x <= 0 or logical_size.y <= 0 or not window_rect.has_area() or not safe_rect.has_area():
		return Vector4.ZERO
	# Match project.godot's aspect=keep: exclude letterboxing before computing margins.
	var factor: float = minf(window_rect.size.x / logical_size.x, window_rect.size.y / logical_size.y)
	var fitted_size: Vector2 = logical_size * factor
	var fitted := Rect2(window_rect.position + (window_rect.size - fitted_size) * 0.5, fitted_size)
	var visible: Rect2 = fitted.intersection(safe_rect)
	if not visible.has_area():
		return Vector4.ZERO
	return Vector4(
		ceilf((visible.position.x - fitted.position.x) / factor),
		ceilf((visible.position.y - fitted.position.y) / factor),
		ceilf((fitted.end.x - visible.end.x) / factor),
		ceilf((fitted.end.y - visible.end.y) / factor)
	)


static func margins(screen: Control) -> Vector4:
	if DisplayServer.get_name() == "headless" or not OS.has_feature("android"):
		return Vector4.ZERO
	var window: Window = screen.get_window()
	var bounds := Rect2(Vector2(window.position), Vector2(window.size))
	return calculate(Rect2(DisplayServer.get_display_safe_area()), bounds, screen.size)


static func shifted_offsets(original: Vector4, anchors: Vector4, insets: Vector4) -> Vector4:
	# Preserve every control's original anchor and spacing within the safe rectangle.
	return original + Vector4(
		lerpf(insets.x, -insets.z, anchors.x),
		lerpf(insets.y, -insets.w, anchors.y),
		lerpf(insets.x, -insets.z, anchors.z),
		lerpf(insets.y, -insets.w, anchors.w)
	)


static func attach(screen: Control, controls: Array) -> void:
	var originals: Array[Vector4] = []
	for control: Control in controls:
		originals.append(Vector4(control.offset_left, control.offset_top, control.offset_right, control.offset_bottom))
	var refresh := func() -> void:
		var insets: Vector4 = margins(screen)
		for i in range(controls.size()):
			var control: Control = controls[i]
			var anchors := Vector4(control.anchor_left, control.anchor_top, control.anchor_right, control.anchor_bottom)
			var offsets := shifted_offsets(originals[i], anchors, insets)
			control.offset_left = offsets.x
			control.offset_top = offsets.y
			control.offset_right = offsets.z
			control.offset_bottom = offsets.w
	screen.resized.connect(refresh)
	refresh.call()
