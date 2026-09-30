extends Control
## TreeVisual — Milestone 5
## Runtime-drawn tree. Grows with stats. No sprite assets.
## Updates only on explicit queue_redraw() — never in _process().

const TRUNK_COLOR: Color = Color(0.42, 0.29, 0.17)
const LEAF_COLOR: Color = Color(0.29, 0.48, 0.23)
const ROOT_COLOR: Color = Color(0.33, 0.24, 0.15)
const GROUND_COLOR: Color = Color(0.15, 0.20, 0.14)

var roots: int = 1
var trunk: int = 1
var leaves: int = 1
var hp: int = 10
var max_hp: int = 10


func _ready() -> void:
	# Connect to GameManager if it exists — but tests may instantiate us
	# without an active run, so guard.
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null and gm.has_signal("state_changed"):
		gm.state_changed.connect(_on_state_changed)


func _on_state_changed(state: GameState) -> void:
	if state == null:
		return
	roots = state.roots
	trunk = state.trunk
	leaves = state.leaves
	hp = state.hp
	max_hp = state.max_hp
	queue_redraw()


func set_stats(r: int, t: int, l: int, h: int, mh: int) -> void:
	roots = r
	trunk = t
	leaves = l
	hp = h
	max_hp = mh
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return

	# Ground line
	var ground_y: float = h * 0.88
	draw_rect(Rect2(0, ground_y, w, h - ground_y), GROUND_COLOR)

	# --- Roots (below ground) ---
	var root_count: int = clampi(roots, 0, 12)
	var root_spread: float = w * 0.35
	for i in range(root_count):
		var t: float = float(i + 1) / float(root_count + 1)
		var x_off: float = lerp(-root_spread, root_spread, t)
		var depth: float = ground_y + 8.0 + float(i % 3) * 6.0
		var root_px: Vector2 = Vector2(w * 0.5 + x_off, depth)
		draw_line(Vector2(w * 0.5, ground_y), root_px, ROOT_COLOR, 3.0)

	# --- Trunk ---
	var trunk_thickness: float = 6.0 + float(clampi(trunk, 1, 20)) * 2.5
	var trunk_height: float = h * 0.28 + float(clampi(trunk, 1, 20)) * 4.0
	var trunk_top: Vector2 = Vector2(w * 0.5, ground_y - trunk_height)
	draw_line(
		Vector2(w * 0.5, ground_y),
		trunk_top,
		TRUNK_COLOR,
		trunk_thickness
	)

	# --- Leaves (clusters above trunk) ---
	var leaf_count: int = clampi(leaves, 0, 24)
	if leaf_count > 0:
		var canopy_radius: float = 20.0 + float(leaf_count) * 2.0
		var rings: int = int(ceil(float(leaf_count) / 6.0))
		var drawn: int = 0
		for ring in range(rings):
			var ring_radius: float = canopy_radius * (1.0 - float(ring) * 0.22)
			var count_in_ring: int = 6
			if drawn + count_in_ring > leaf_count:
				count_in_ring = leaf_count - drawn
			for i in range(count_in_ring):
				var angle: float = TAU * float(i) / float(count_in_ring) + float(ring) * 0.4
				var offset: Vector2 = Vector2(cos(angle), sin(angle)) * ring_radius
				var pos: Vector2 = trunk_top + offset
				draw_circle(pos, 14.0, LEAF_COLOR)
				drawn += 1
			if drawn >= leaf_count:
				break

	# --- HP indicator: small bar at bottom ---
	if max_hp > 0:
		var bar_w: float = w * 0.6
		var bar_x: float = (w - bar_w) * 0.5
		var bar_y: float = h - 16.0
		var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
		draw_rect(Rect2(bar_x, bar_y, bar_w, 8.0), Color(0.2, 0.1, 0.1))
		draw_rect(Rect2(bar_x, bar_y, bar_w * ratio, 8.0), Color(0.6, 0.3, 0.3))
