extends RefCounted
class_name RNG
## RNG — Milestone 3
## Thin deterministic wrapper around Godot's RandomNumberGenerator.
## Same seed -> same sequence, always.
##
## Gotcha reminder (Godot 4.3): no := when RHS returns Variant.

var _rng: RandomNumberGenerator


func _init(seed_value: int = 0) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value


func next_int(max_exclusive: int) -> int:
	if max_exclusive <= 0:
		return 0
	return _rng.randi_range(0, max_exclusive - 1)


func next_float() -> float:
	return _rng.randf()


func pick_weighted(weights: PackedInt32Array) -> int:
	## Returns the index of the chosen weight. Weights must be >= 0.
	## If all weights are 0, returns 0.
	var total: int = 0
	for w in weights:
		if w < 0:
			push_error("RNG.pick_weighted: negative weight")
			return 0
		total += w
	if total <= 0:
		return 0
	var roll: int = _rng.randi_range(0, total - 1)
	var acc: int = 0
	for i in range(weights.size()):
		acc += weights[i]
		if roll < acc:
			return i
	return weights.size() - 1
