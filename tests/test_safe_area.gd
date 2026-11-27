extends SceneTree

const SafeArea = preload("res://scripts/util/SafeArea.gd")
var failures: int = 0

func _init() -> void:
	process_frame.connect(_run_tests, CONNECT_ONE_SHOT)

func _expect(actual: Vector4, expected: Vector4, name: String) -> void:
	if not actual.is_equal_approx(expected):
		push_error("%s: got %s, expected %s" % [name, actual, expected])
		failures += 1

func _run_tests() -> void:
	var logical := Vector2(720, 1280)
	var window := Rect2(0, 0, 1080, 1920)
	_expect(SafeArea.calculate(window, window, logical), Vector4.ZERO, "no cutout")
	_expect(SafeArea.calculate(Rect2(30, 90, 1020, 1770), window, logical), Vector4(20, 60, 20, 40), "all four insets")
	_expect(SafeArea.calculate(Rect2(0, 100, 1080, 2080), Rect2(0, 0, 1080, 2280), logical), Vector4.ZERO, "cutout entirely in letterbox")
	_expect(SafeArea.calculate(Rect2(), window, logical), Vector4.ZERO, "invalid safe rectangle")
	_expect(SafeArea.calculate(Rect2(110, 290, 1020, 1770), Rect2(80, 200, 1080, 1920), logical), Vector4(20, 60, 20, 40), "offset window")
	var insets := Vector4(20, 60, 10, 40)
	_expect(SafeArea.shifted_offsets(Vector4(20, 80, -20, -20), Vector4(0, 0, 1, 1), insets), Vector4(40, 140, -30, -60), "body offsets")
	_expect(SafeArea.shifted_offsets(Vector4(-200, -140, 200, 140), Vector4(0.5, 0.5, 0.5, 0.5), insets), Vector4(-195, -130, 205, 150), "centered controls")
	var screen := Control.new()
	root.add_child(screen)
	_expect(SafeArea.margins(screen), Vector4.ZERO, "headless fallback")
	screen.free()
	if failures == 0:
		print("PASS: safe area")
	quit(0 if failures == 0 else 1)
