extends RefCounted
class_name Seed
## Seed — Milestone 6
## Plain data class. Built from a Dictionary loaded from seeds.json.

var id: String = ""
var display_name: String = ""
var starting_roots: int = 1
var starting_trunk: int = 1
var starting_leaves: int = 1
var starting_hp: int = 10
var passive_description: String = ""
var unlocks_on_win: String = ""


static func from_dictionary(d: Dictionary) -> Seed:
	var s: Seed = Seed.new()
	s.id = String(d.get("id", ""))
	s.display_name = String(d.get("display_name", s.id))
	s.starting_roots = int(d.get("starting_roots", 1))
	s.starting_trunk = int(d.get("starting_trunk", 1))
	s.starting_leaves = int(d.get("starting_leaves", 1))
	s.starting_hp = int(d.get("starting_hp", 10))
	s.passive_description = String(d.get("passive_description", ""))
	s.unlocks_on_win = String(d.get("unlocks_on_win", ""))
	return s


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"starting_roots": starting_roots,
		"starting_trunk": starting_trunk,
		"starting_leaves": starting_leaves,
		"starting_hp": starting_hp,
		"passive_description": passive_description,
		"unlocks_on_win": unlocks_on_win,
	}


func _to_string() -> String:
	return "Seed(%s, %d/%d/%d, hp %d)" % [
		id, starting_roots, starting_trunk, starting_leaves, starting_hp
	]
