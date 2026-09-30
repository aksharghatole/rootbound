extends RefCounted
class_name GameState
## GameState — Milestone 2
## Plain data object. No scene dependencies. No UI. Fully headless-testable.

const MAX_SEASON: int = 12
const STARTING_HP: int = 10

var season: int = 1
var hp: int = STARTING_HP
var max_hp: int = STARTING_HP
var roots: int = 1
var trunk: int = 1
var leaves: int = 1
var growth_points: int = 2
var rng_seed: int = 0
var seed_name: String = "oak"
var passive_used: bool = false


func _init() -> void:
	# Nothing yet. Real init lands in M3 when we add starting stats per seed.
	pass


func is_alive() -> bool:
	return hp > 0


func has_won() -> bool:
	return season >= MAX_SEASON and is_alive()


func to_dictionary() -> Dictionary:
	return {
		"season": season,
		"hp": hp,
		"max_hp": max_hp,
		"roots": roots,
		"trunk": trunk,
		"leaves": leaves,
		"growth_points": growth_points,
		"rng_seed": rng_seed,
		"seed_name": seed_name,
		"passive_used": passive_used,
	}


func _to_string() -> String:
	return "GameState(season=%d, hp=%d/%d, roots=%d, trunk=%d, leaves=%d, gp=%d)" % [
		season, hp, max_hp, roots, trunk, leaves, growth_points
	]
