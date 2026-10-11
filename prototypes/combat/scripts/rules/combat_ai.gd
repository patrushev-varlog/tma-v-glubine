class_name CombatAI
extends RefCounted
## Простой ИИ: враги в бою, а в симуляции — и герои.


static func take_turn(b: Battle, u: Combatant, use_dark := false) -> void:
	if not u.conscious() or b.outcome != "":
		return
	if u.team == 1:
		_enemy_turn(b, u)
	else:
		_hero_turn(b, u, use_dark)


# --- Враги ----------------------------------------------------------------

static func _enemy_turn(b: Battle, u: Combatant) -> void:
	var target := _pick_target(b, u)
	if target == null:
		return
	if u.is_ranged():
		var in_range := _foes_in_range(b, u, int(u.weapon.get("range", 1)))
		if in_range.is_empty():
			_move_toward(b, u, target, int(u.weapon.get("range", 1)))
			in_range = _foes_in_range(b, u, int(u.weapon.get("range", 1)))
		if not in_range.is_empty():
			in_range.sort_custom(func(a: Combatant, c: Combatant) -> bool: return a.hp < c.hp)
			b.attack(u, in_range[0])
		return
	_approach_and_attack(b, u, target, func() -> void: b.attack(u, target))


static func _pick_target(b: Battle, u: Combatant) -> Combatant:
	if u.taunted_by != "":
		var t := b.get_unit(u.taunted_by)
		if t != null and t.conscious():
			return t
	var best: Combatant = null
	for f in b.foes_of(u):
		if best == null:
			best = f
			continue
		var df := Battle.dist(u.cell, f.cell)
		var db := Battle.dist(u.cell, best.cell)
		if df < db or (df == db and f.hp < best.hp):
			best = f
	return best


static func _foes_in_range(b: Battle, u: Combatant, r: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for f in b.foes_of(u):
		if Battle.dist(u.cell, f.cell) <= r:
			out.append(f)
	return out


## Подходит на дистанцию want_range к цели (как можно ближе к ней).
static func _move_toward(b: Battle, u: Combatant, target: Combatant, want_range: int) -> void:
	var reach := b.reachable(u)
	var best_cell := u.cell
	var best_score := 1_000_000
	for c in reach:
		if c is String:
			continue
		var d := Battle.dist(c, target.cell)
		var score := (0 if d <= want_range else d * 10) + int(reach[c].cost)
		if want_range > 1 and d <= 1:
			score += 50
		if score < best_score:
			best_score = score
			best_cell = c
	if best_cell != u.cell:
		b.move_along(u, b.path_to(u, best_cell, reach))


static func _approach_and_attack(b: Battle, u: Combatant, target: Combatant, do_attack: Callable) -> void:
	if Battle.dist(u.cell, target.cell) > u.reach():
		_move_toward(b, u, target, u.reach())
	if not u.conscious():
		return
	if Battle.dist(u.cell, target.cell) <= u.reach() and target.conscious():
		do_attack.call()
		return
	for f in b.foes_of(u):
		if b.can_attack(u, f):
			b.attack(u, f)
			return


# --- Герои в симуляции ----------------------------------------------------

static func _hero_turn(b: Battle, u: Combatant, use_dark: bool) -> void:
	_bonus_actions(b, u, use_dark)
	if b.outcome != "":
		return
	var target := _pick_target(b, u)
	if target == null:
		return
	if u.abilities.has("hallowed_ground") and b.can_use(u, "hallowed_ground"):
		var spot := _best_area(b, u, "hallowed_ground", true)
		if spot.score >= 2:
			b.use_ability(u, "hallowed_ground", spot.cell)
			return
	if u.abilities.has("bomb") and b.can_use(u, "bomb"):
		var spot2 := _best_area(b, u, "bomb", false)
		if spot2.score >= 2:
			b.use_ability(u, "bomb", spot2.cell)
			return
	if u.abilities.has("fire_bolt"):
		_caster_turn(b, u, target, use_dark)
		return
	if u.abilities.has("sacred_flame") and Battle.dist(u.cell, target.cell) > 1:
		var spell := "wither" if use_dark and u.abilities.has("wither") else "sacred_flame"
		if b.ability_targets(u, spell).has(target.cell):
			b.use_ability(u, spell, target.cell)
			return
	var aid := ""
	if use_dark and u.abilities.has("cursed_blade"):
		aid = "cursed_blade"
	elif u.abilities.has("trip") and b.can_use(u, "trip"):
		aid = "trip"
	_approach_and_attack(b, u, target, func() -> void:
		if aid != "" and b.ability_targets(u, aid).has(target.cell):
			b.use_ability(u, aid, target.cell)
		else:
			b.attack(u, target))


static func _bonus_actions(b: Battle, u: Combatant, use_dark: bool) -> void:
	if u.abilities.has("healing_word") and b.can_use(u, "healing_word"):
		for o in b.units:
			if o.team == u.team and not o.dead and (o.down or o.hp * 10 < o.max_hp * 4):
				if b.ability_targets(u, "healing_word").has(o.cell):
					b.use_ability(u, "healing_word", o.cell)
					return
	if u.abilities.has("second_wind") and b.can_use(u, "second_wind") and u.hp * 2 < u.max_hp:
		b.use_ability(u, "second_wind", u.cell)
		return
	if u.abilities.has("taunt") and b.can_use(u, "taunt"):
		var near := 0
		for f in b.foes_of(u):
			if Battle.dist(f.cell, u.cell) <= 3:
				near += 1
		if near >= 2:
			b.use_ability(u, "taunt", u.cell)
			return
	if use_dark and u.abilities.has("shadow_step") and b.can_use(u, "shadow_step"):
		b.use_ability(u, "shadow_step", u.cell)


static func _caster_turn(b: Battle, u: Combatant, target: Combatant, use_dark: bool) -> void:
	var adjacent := 0
	for f in b.foes_of(u):
		if Battle.dist(f.cell, u.cell) <= 1:
			adjacent += 1
	if adjacent >= 2 and b.can_use(u, "thunderwave"):
		b.use_ability(u, "thunderwave", u.cell)
		return
	var spell := "fire_bolt"
	if use_dark and u.abilities.has("life_drain"):
		spell = "life_drain"
	elif b.can_use(u, "magic_missile") and target.hp > 6:
		spell = "magic_missile"
	if not b.ability_targets(u, spell).has(target.cell):
		_move_toward(b, u, target, int(b.ability(spell).range))
	if b.ability_targets(u, spell).has(target.cell):
		b.use_ability(u, spell, target.cell)


## Лучшая клетка для площадной способности: сколько врагов (или нежити) без своих.
static func _best_area(b: Battle, u: Combatant, aid: String, undead_only: bool) -> Dictionary:
	var best := {"cell": u.cell, "score": 0}
	for c in b.ability_targets(u, aid):
		var score := 0
		for ac in b.ability_area(u, aid, c):
			var o := b.occupant(ac)
			if o == null or o.dead:
				continue
			if o.team == u.team:
				if not undead_only:
					score -= 3
			elif o.conscious() and (o.undead or not undead_only):
				score += 1
		if score > best.score:
			best = {"cell": c, "score": score}
	return best
