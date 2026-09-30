extends RefCounted
class_name SeasonSystem
## SeasonSystem — Milestone 6
## Pure functions. advance_season() takes a state and returns a result dict
## containing a NEW GameState. The caller's state is not mutated.
##
## Gotcha reminders (Godot 4.3):
##   - no := when RHS returns Variant
##   - no reserved Object method names (get_meta, has_meta, etc.)

const MAX_SEASON: int = 12


static func growth_points_for(leaves: int) -> int:
	return 1 + int(leaves / 3)


static func seed_growth_bonus(seed_name: String) -> int:
	## Willow passive: +1 growth point each season.
	match seed_name:
		"willow":
			return 1
		_:
			return 0


static func apply_growth_points(state: GameState) -> GameState:
	var next: GameState = _copy_state(state)
	var base: int = growth_points_for(next.leaves)
	var bonus: int = seed_growth_bonus(next.seed_name)
	next.growth_points += base + bonus
	return next


static func spend_growth_point(state: GameState, stat: String) -> GameState:
	var next: GameState = _copy_state(state)
	if next.growth_points <= 0:
		return next
	match stat:
		"roots":
			next.roots += 1
		"trunk":
			next.trunk += 1
			next.max_hp += 2
			next.hp += 2
		"leaves":
			next.leaves += 1
		_:
			return next
	next.growth_points -= 1
	return next


static func advance_season(state: GameState, rng: RNG, events: EventSystem) -> Dictionary:
	var next: GameState = _copy_state(state)

	# 1. Resolve event.
	var event: Dictionary = events.pick_event(next.season, rng)
	var damage: int = 0
	if not event.is_empty():
		damage = events.compute_damage(event, next)

		# Birch passive: first event of the run is fully negated.
		if next.seed_name == "birch" and not next.passive_used and damage > 0:
			damage = 0
			next.passive_used = true
		elif damage > 0:
			# No passive — consume it anyway if it wasn't already consumed.
			# Birch only; other seeds ignore this branch.
			pass

		next.hp -= damage
		if next.hp < 0:
			next.hp = 0
	elif next.seed_name == "birch" and not next.passive_used:
		# Birch's passive is only consumed on an event that would have hurt.
		# If no event fired, don't consume.
		pass

	# 2. Lose check.
	if next.hp <= 0:
		return {
			"event": event,
			"damage": damage,
			"won": false,
			"lost": true,
			"state": next,
		}

	# 3. Advance season.
	next.season += 1

	# 4. Win check.
	if next.season > MAX_SEASON:
		return {
			"event": event,
			"damage": damage,
			"won": true,
			"lost": false,
			"state": next,
		}

	# 5. Grant growth points (base + seed bonus).
	next.growth_points += growth_points_for(next.leaves) + seed_growth_bonus(next.seed_name)

	return {
		"event": event,
		"damage": damage,
		"won": false,
		"lost": false,
		"state": next,
	}


static func _copy_state(state: GameState) -> GameState:
	var c: GameState = GameState.new()
	c.season = state.season
	c.hp = state.hp
	c.max_hp = state.max_hp
	c.roots = state.roots
	c.trunk = state.trunk
	c.leaves = state.leaves
	c.growth_points = state.growth_points
	c.rng_seed = state.rng_seed
	c.seed_name = state.seed_name
	c.passive_used = state.passive_used
	return c
