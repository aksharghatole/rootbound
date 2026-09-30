extends RefCounted
class_name Meta
## Meta — Milestone 4
## Persistent progression across runs. Plain data. Testable headless.

var unlocked_seeds: Array = ["oak"]
var best_season: int = 0
var total_runs: int = 0


func _init() -> void:
	pass


func unlock_seed(seed_name: String) -> bool:
	## Returns true if it was newly unlocked.
	if unlocked_seeds.has(seed_name):
		return false
	unlocked_seeds.append(seed_name)
	return true


func record_run(final_season: int, won: bool) -> void:
	total_runs += 1
	var achieved: int = final_season if won else final_season
	if achieved > best_season:
		best_season = achieved


func to_dictionary() -> Dictionary:
	return {
		"unlocked_seeds": unlocked_seeds.duplicate(),
		"best_season": best_season,
		"total_runs": total_runs,
	}


func _to_string() -> String:
	return "Meta(seeds=%s, best=%d, runs=%d)" % [
		str(unlocked_seeds), best_season, total_runs
	]
