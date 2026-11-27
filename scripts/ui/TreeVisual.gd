extends Control
## Procedural seasonal tree illustration. Redraws only during short transitions.

const PALETTES: Array[Color] = [
	Color("#a8c77a"), Color("#669c59"), Color("#d8a257"), Color("#91aab2")
]
const SKIES: Array[Color] = [
	Color("#34564c"), Color("#264c52"), Color("#67483d"), Color("#384c60")
]
var roots: int = 1
var trunk: int = 1
var leaves: int = 1
var hp: int = 10
var max_hp: int = 10
var season: int = 1
var _display: Vector3 = Vector3.ONE
var _from: Vector3 = Vector3.ONE
var _elapsed: float = 1.0
var _damage: float = 0.0
var _initialized: bool = false

func _ready() -> void:
	clip_contents = true
	resized.connect(queue_redraw)
	set_process(false)

func set_season(value: int) -> void:
	season = clampi(value, 1, 12)
	queue_redraw()

func set_stats(r: int, t: int, l: int, h: int, mh: int) -> void:
	var next := Vector3(r, t, l)
	if not _initialized:
		_display = next
		_initialized = true
	elif next != Vector3(roots, trunk, leaves):
		_from = _display
		_elapsed = 0.0
		set_process(true)
	if h < hp:
		_damage = 1.0
		set_process(true)
	roots = r
	trunk = t
	leaves = l
	hp = h
	max_hp = mh
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed = minf(1.0, _elapsed + delta / 0.38)
	_damage = maxf(0.0, _damage - delta / 0.45)
	var ease_out: float = 1.0 - pow(1.0 - _elapsed, 3.0)
	_display = _from.lerp(Vector3(roots, trunk, leaves), ease_out)
	queue_redraw()
	if _elapsed >= 1.0 and _damage <= 0.0:
		set_process(false)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return
	var phase: int = (season - 1) % 4
	var sky: Color = SKIES[phase]
	var foliage: Color = PALETTES[phase]
	var health: float = clampf(float(hp) / maxf(1.0, float(max_hp)), 0.0, 1.0)
	foliage = Color("#8f7055").lerp(foliage, health)
	foliage = foliage.lerp(Color("#e7a190"), _damage * 0.55)

	# Layered sky, sunlight and distant hills.
	for band in range(12):
		var t: float = float(band) / 11.0
		draw_rect(Rect2(0, h * t / 1.45, w, h / 15.0 + 2.0), sky.lerp(Color("#b6b79a"), t * 0.55))
	draw_circle(Vector2(w * 0.78, h * 0.17), h * 0.075, Color(0.98, 0.89, 0.65, 0.72))
	var ground_y: float = h * 0.75
	for layer in range(2):
		var points := PackedVector2Array([Vector2(0, ground_y)])
		for i in range(17):
			var x: float = w * i / 16.0
			var y: float = ground_y - h * (0.12 + layer * 0.045 + sin(i * 0.65 + layer * 1.7) * 0.045)
			points.append(Vector2(x, y))
		points.append(Vector2(w, ground_y))
		draw_colored_polygon(points, sky.darkened(0.25 + layer * 0.16))
	draw_rect(Rect2(0, ground_y, w, h - ground_y), Color("#262c29"))
	draw_rect(Rect2(0, ground_y, w, h * 0.025), Color("#626f46"))

	# Roots fan through the exposed soil, growing with the root stat.
	var origin := Vector2(w * 0.5, ground_y)
	var root_count: int = clampi(roundi(_display.x) + 2, 3, 14)
	var root_depth: float = h * (0.09 + minf(_display.x, 16.0) * 0.005)
	for i in range(root_count):
		var spread: float = lerpf(-1.0, 1.0, float(i) / float(root_count - 1))
		var end := origin + Vector2(spread * w * (0.15 + minf(_display.x, 16.0) * 0.014), root_depth * (0.75 + 0.25 * cos(i * 2.1)))
		var elbow := origin.lerp(end, 0.46) + Vector2(0, h * 0.015)
		draw_polyline(PackedVector2Array([origin, elbow, end]), Color("#a18460"), maxf(1.5, h * 0.007), true)
		draw_line(elbow, end + Vector2(spread * w * 0.04, h * 0.018), Color("#76654e"), maxf(1.0, h * 0.003), true)

	# Tapered trunk and organic branches.
	var thickness: float = minf(w * 0.09, w * (0.022 + minf(_display.y, 20.0) * 0.003))
	var top := origin - Vector2(0, h * (0.30 + minf(_display.y, 20.0) * 0.007))
	var bark := Color("#76573d")
	draw_colored_polygon(PackedVector2Array([origin + Vector2(-thickness, 0), origin + Vector2(thickness, 0), top + Vector2(thickness * 0.26, 0), top - Vector2(thickness * 0.25, 0)]), bark)
	draw_line(origin + Vector2(-thickness * 0.42, 0), top, bark.lightened(0.25), maxf(2.0, thickness * 0.18), true)
	var reach: float = w * (0.13 + minf(_display.z, 24.0) * 0.005)
	for i in range(5):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var start := origin.lerp(top, 0.42 + float(i) * 0.10)
		var end := top + Vector2(side * reach * (0.78 + 0.08 * i), h * (0.055 - i * 0.026))
		draw_line(start, end, bark, maxf(2.0, thickness * (0.5 - i * 0.055)), true)

	# Deterministic overlapping canopy clusters; no random shimmer on redraw.
	var clusters: int = clampi(7 + roundi(_display.z) * 2, 9, 45)
	var radius: float = minf(h * 0.16, w * (0.065 + minf(_display.z, 24.0) * 0.002))
	for i in range(clusters):
		var angle: float = i * 2.399963
		var dist: float = sqrt(float(i) / float(clusters))
		var pos := top + Vector2(cos(angle) * reach * dist, sin(angle) * h * 0.12 * dist)
		var shade: Color = foliage.darkened(0.23 + 0.09 * sin(i * 1.7))
		draw_circle(pos, radius * (0.65 + 0.22 * cos(i * 1.3)), shade)
		draw_circle(pos - Vector2(radius * 0.12, radius * 0.16), radius * 0.52, foliage.lightened(0.11 + 0.07 * sin(i)))
	
	# Health bar remains legible on every palette.
	var bar := Rect2(w * 0.18, h * 0.947, w * 0.64, maxf(5.0, h * 0.022))
	draw_rect(bar, Color("#131b1a"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * health, bar.size.y)), Color("#d27366").lerp(Color("#9cc47b"), health))
