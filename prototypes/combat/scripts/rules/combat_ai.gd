class_name CombatAI
extends RefCounted
## Простой ИИ: враги в бою, а в симуляции — и герои со спутниками.
## Герои выбирают действие по грубой оценке ожидаемой пользы: урон, контроль, лечение.

## Сколько «стоит» одна ячейка заклинания при выборе действия.
const SLOT_VALUE := 2.5
## Умения, которые ИИ героя не рассматривает как основное действие.
const SKIP_MAIN := ["dodge", "shove", "trap"]


static func take_turn(b: Battle, u: Combatant, use_dark := false) -> void:
	if not u.conscious() or b.outcome != "" or u.action_used and u.bonus_used and u.speed_left == 0:
		return
	if u.team == 1:
		_enemy_turn(b, u)
	else:
		_hero_turn(b, u, use_dark)


# --- Враги ----------------------------------------------------------------

static func _enemy_turn(b: Battle, u: Combatant) -> void:
	if u.turned:
		_flee(b, u)
		return
	var target := _pick_target(b, u)
	if target == null:
		return
	if u.is_ranged():
		var r := int(u.weapon.get("range", 1))
		var in_range := _foes_in_range(b, u, r)
		if in_range.is_empty():
			_move_toward(b, u, target, r)
			in_range = _foes_in_range(b, u, r)
		var guard := 0
		while not in_range.is_empty() and not u.action_used and u.conscious() and b.outcome == "" and guard < 4:
			guard += 1
			if b.difficulty == "trial":
				b.attack(u, _best_victim(b, u, in_range))
			else:
				in_range.sort_custom(func(a: Combatant, c: Combatant) -> bool: return a.hp < c.hp)
				b.attack(u, in_range[0])
			in_range = _foes_in_range(b, u, r)
		return
	_approach_and_attack(b, u, target, func() -> void: b.attack(u, target))


static func _pick_target(b: Battle, u: Combatant) -> Combatant:
	if u.taunted_by != "":
		var t := b.get_unit(u.taunted_by)
		if t != null and t.conscious():
			return t
	if u.team == 1 and b.difficulty == "trial":
		return _best_victim(b, u, b.foes_of(u))
	var best: Combatant = null
	for f in b.foes_of(u):
		if f.turned and u.team == 0 and best != null:
			continue
		if best == null:
			best = f
			continue
		var df := Battle.dist(u.cell, f.cell)
		var db := Battle.dist(u.cell, best.cell)
		if df < db or (df == db and f.hp < best.hp):
			best = f
	return best


## «Испытание»: враг выбирает, кого выгоднее бить. Ценит добивание, слабую броню
## и хрупких героев; дальние цели дешевле, чем ближние, только если до них можно дойти.
static func _best_victim(b: Battle, u: Combatant, candidates: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	var best_score := -INF
	var reach := int(u.weapon.get("range", 1)) if u.is_ranged() else u.reach()
	for f in candidates:
		if not f.conscious():
			continue
		var p := b.attack_preview(u, f)
		var score: float = p.expected / maxf(f.hp, 1.0) * 10.0
		if p.max >= f.hp:
			score += 4.0 * p.chance
		score += (16.0 - f.max_hp) * 0.25
		var gap := Battle.dist(u.cell, f.cell) if u.is_ranged() else int(b.walk_distances(f.cell).get(u.cell, 99))
		var steps := maxi(0, gap - reach)
		if steps > 0 and not u.is_ranged():
			# Уход от героя рядом провоцирует атаку — умный враг этого избегает.
			for g in b.foes_of(u):
				if g != f and g.can_react() and Battle.dist(u.cell, g.cell) <= g.reach():
					score -= 3.0
		if steps > u.speed_left:
			score -= 2.0 + float(steps - u.speed_left) * 0.8
		if score > best_score:
			best_score = score
			best = f
	return best


static func _foes_in_range(b: Battle, u: Combatant, r: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for f in b.foes_of(u):
		if Battle.dist(u.cell, f.cell) <= r and (r <= 1 or b.has_los(u.cell, f.cell)):
			out.append(f)
	return out


## Изгнанная нежить уходит как можно дальше от героев и не атакует.
static func _flee(b: Battle, u: Combatant) -> void:
	var reach := b.reachable(u)
	var best_cell := u.cell
	var best_score := -1
	for c in reach:
		if c is String:
			continue
		var nearest := 99
		for f in b.foes_of(u):
			nearest = mini(nearest, Battle.dist(c, f.cell))
		var score := nearest * 10 - b.count_opportunity(u, b.path_to(u, c, reach)) * 15
		if score > best_score:
			best_score = score
			best_cell = c
	if best_cell != u.cell:
		b.move_along(u, b.path_to(u, best_cell, reach))


## Подходит на дистанцию want_range к цели (как можно ближе к ней).
static func _move_toward(b: Battle, u: Combatant, target: Combatant, want_range: int) -> void:
	if u.speed_left <= 0:
		return
	var reach := b.reachable(u)
	var walk := b.walk_distances(target.cell)
	var best_cell := u.cell
	var best_score := 1_000_000
	for c in reach:
		if c is String:
			continue
		var d := Battle.dist(c, target.cell)
		if want_range > 1 and d <= want_range and not b.has_los(c, target.cell):
			d = want_range + 1
		if d > want_range:
			# Вне дальности оцениваем путь пешком, чтобы обходить стены.
			d = maxi(d, int(walk.get(c, 99)))
		var score := (0 if d <= want_range else d * 10) + int(reach[c].cost)
		if want_range > 1:
			# Стрелки и заклинатели не лезут вплотную к врагам.
			for f in b.foes_of(u):
				if Battle.dist(c, f.cell) <= 1 and not f.is_ranged():
					score += 50
					break
		if b.grease.has(c) or b.webs.has(c) or (u.team == 0 and b.spikes.has(c)):
			score += 25
		if c != u.cell and (u.team == 0 or b.difficulty == "trial"):
			score += b.count_opportunity(u, b.path_to(u, c, reach)) * 15
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
	_finish_attacks(b, u)


## Добивает оставшиеся удары действия «Атака» по любым врагам рядом.
static func _finish_attacks(b: Battle, u: Combatant) -> void:
	var guard := 0
	while not u.action_used and u.conscious() and b.outcome == "" and guard < 4:
		guard += 1
		var victim: Combatant = null
		for f in b.foes_of(u):
			if b.can_attack(u, f) and (victim == null or f.hp < victim.hp):
				victim = f
		if victim == null:
			return
		b.attack(u, victim)


# --- Герои в симуляции ----------------------------------------------------

static func _hero_turn(b: Battle, u: Combatant, use_dark: bool) -> void:
	_bonus_before(b, u, use_dark)
	if b.outcome != "" or not u.conscious():
		return
	_main_action(b, u, use_dark)
	if b.outcome != "" or not u.conscious():
		return
	if u.action_used and b.can_use(u, "action_surge"):
		b.use_ability(u, "action_surge", u.cell)
		_main_action(b, u, use_dark)
	if b.outcome != "" or not u.conscious():
		return
	_bonus_after(b, u, use_dark)


static func _wounded(o: Combatant) -> bool:
	return o.down or o.hp * 10 < o.max_hp * 4


static func _bonus_before(b: Battle, u: Combatant, use_dark: bool) -> void:
	if b.can_use(u, "mass_healing_word"):
		var hurt := 0
		for o in b.allies_of(u):
			if _wounded(o) and Battle.dist(o.cell, u.cell) <= 6:
				hurt += 1
		if hurt >= 2:
			b.use_ability(u, "mass_healing_word", u.cell)
			return
	if b.can_use(u, "healing_word"):
		var best: Combatant = null
		for o in b.allies_of(u):
			if _wounded(o) and b.ability_targets(u, "healing_word").has(o.cell):
				if best == null or (o.down and not best.down) or o.hp < best.hp:
					best = o
		if best == null:
			# Выбывший союзник вне досягаемости: подойти к нему, чтобы поднять.
			for o in b.allies_of(u):
				if o.down and o != u:
					_move_toward(b, u, o, int(b.ability("healing_word").range))
					if b.ability_targets(u, "healing_word").has(o.cell):
						best = o
					break
		if best != null:
			b.use_ability(u, "healing_word", best.cell)
			return
	if b.can_use(u, "second_wind") and u.hp * 2 < u.max_hp:
		b.use_ability(u, "second_wind", u.cell)
		return
	var near := _nearest_foe_dist(b, u)
	if b.can_use(u, "rage") and near <= u.speed_left + 2:
		b.use_ability(u, "rage", u.cell)
		return
	if b.can_use(u, "taunt"):
		var close := 0
		for f in b.foes_of(u):
			if Battle.dist(f.cell, u.cell) <= 3:
				close += 1
		if close >= 2:
			b.use_ability(u, "taunt", u.cell)
			return
	if use_dark and b.can_use(u, "shadow_step") and near <= u.speed_left + 1:
		b.use_ability(u, "shadow_step", u.cell)
		return
	if b.can_use(u, "hide") and near > 1:
		b.use_ability(u, "hide", u.cell)
		return
	if b.can_use(u, "poison_blade") and near <= u.speed_left + 1:
		b.use_ability(u, "poison_blade", u.cell)
		return


static func _bonus_after(b: Battle, u: Combatant, _use_dark: bool) -> void:
	if u.bonus_used:
		return
	if b.can_use(u, "healing_word"):
		for o in b.allies_of(u):
			if o.down and b.ability_targets(u, "healing_word").has(o.cell):
				b.use_ability(u, "healing_word", o.cell)
				return
	if b.can_use(u, "spiritual_weapon") and (u.spirit_weapon or u.slots >= 3):
		var targets := b.ability_targets(u, "spiritual_weapon")
		if not targets.is_empty():
			var best := targets[0]
			for c in targets:
				if b.occupant(c).hp < b.occupant(best).hp:
					best = c
			b.use_ability(u, "spiritual_weapon", best)
			return
	if b.can_use(u, "shield_of_faith") and u.slots >= 3:
		for o in b.allies_of(u):
			if o.conscious() and o.ac_bonus == 0 and _nearest_foe_dist(b, o) <= 2 \
				and b.ability_targets(u, "shield_of_faith").has(o.cell):
				b.use_ability(u, "shield_of_faith", o.cell)
				return


static func _nearest_foe_dist(b: Battle, u: Combatant) -> int:
	var best := 99
	for f in b.foes_of(u):
		best = mini(best, Battle.dist(u.cell, f.cell))
	return best


## Основное действие: оцениваем атаку оружием и каждое доступное умение, выполняем лучшее.
static func _main_action(b: Battle, u: Combatant, use_dark: bool) -> void:
	var target := _pick_target(b, u)
	if target == null:
		return
	var best_score := _weapon_score(b, u, target)
	var best_aid := ""
	var best_cell := Vector2i(-1, -1)
	for aid in u.abilities:
		if SKIP_MAIN.has(aid) or not b.can_use(u, aid):
			continue
		var a := b.ability(aid)
		if a.cost != "action":
			continue
		var dark: bool = a.get("dark", false)
		if dark and not use_dark:
			continue
		var plan := _ability_plan(b, u, aid, target)
		if plan.is_empty():
			continue
		var score: float = plan.score
		if a.resource == "slot":
			score -= SLOT_VALUE * b.slot_cost(aid)
			if u.abilities.has("healing_word") and u.slots - b.slot_cost(aid) < 1:
				score -= 8.0
		if dark:
			score += 3.0
		if score > best_score:
			best_score = score
			best_aid = aid
			best_cell = plan.cell
	if best_aid == "":
		_weapon_action(b, u, target)
		return
	var a2 := b.ability(best_aid)
	if not b.ability_targets(u, best_aid).has(best_cell):
		# Цель вне досягаемости: сначала подойти.
		var t := b.occupant(best_cell)
		if t != null:
			_move_toward(b, u, t, int(a2.range))
		elif a2.target == "self":
			_move_toward(b, u, target, 1)
	if b.ability_targets(u, best_aid).has(best_cell):
		if best_aid == "reckless":
			b.use_ability(u, best_aid, best_cell)
			_weapon_action(b, u, target)
			return
		b.use_ability(u, best_aid, best_cell)
		if b.ability(best_aid).get("attack", false):
			_finish_attacks(b, u)
	else:
		_weapon_action(b, u, target)


static func _weapon_score(b: Battle, u: Combatant, target: Combatant) -> float:
	var p := b.attack_preview(u, target)
	var walk := int(b.walk_distances(target.cell).get(u.cell, 99))
	var score: float = p.expected * u.attacks_per_action
	if walk - u.reach() > u.speed_left:
		score *= 0.4
	return score


static func _weapon_action(b: Battle, u: Combatant, target: Combatant) -> void:
	var walk := int(b.walk_distances(target.cell).get(u.cell, 99))
	if walk - u.reach() > u.speed_left and b.can_use(u, "dash"):
		b.use_ability(u, "dash", u.cell)
	if b.can_use(u, "reckless") and u.hp * 2 > u.max_hp and walk - u.reach() <= u.speed_left:
		b.use_ability(u, "reckless", u.cell)
	_approach_and_attack(b, u, target, func() -> void: b.attack(u, target))


## План умения: {"score", "cell"} или пустой словарь, если применять незачем.
static func _ability_plan(b: Battle, u: Combatant, aid: String, main_target: Combatant) -> Dictionary:
	var a := b.ability(aid)
	match aid:
		"reckless", "action_surge":
			return {}
		"thunderwave", "fireball", "bomb", "hallowed_ground", "grease", "web", "slow", "spike_growth":
			return _area_plan(b, u, aid)
		"turn_undead", "spirit_guardians", "knife_fan", "preserve_life":
			return _self_plan(b, u, aid)
	if a.target != "enemy":
		return {}
	# Одна цель: лучшая из тех, что уже в досягаемости, иначе главная цель, если до неё можно дойти.
	var best := {}
	var candidates: Array[Combatant] = []
	for c in b.ability_targets(u, aid):
		candidates.append(b.occupant(c))
	if candidates.is_empty():
		var gap := Battle.dist(u.cell, main_target.cell) - int(a.range)
		if gap <= u.speed_left:
			candidates.append(main_target)
	for t in candidates:
		var s := _single_value(b, u, aid, t)
		if best.is_empty() or s > best.score:
			best = {"score": s, "cell": t.cell}
	return best


## Ожидаемая польза от умения по одной цели.
static func _single_value(b: Battle, u: Combatant, aid: String, t: Combatant) -> float:
	var expr := b.dice_of(u, aid)
	var avg := Dice.avg_of(expr) if expr != "" else 0.0
	var value := 0.0
	match aid:
		"magic_missile":
			value = avg
		"sacred_flame", "wither":
			var stat := "dex" if aid == "sacred_flame" else "con"
			var fail := 1.0 - Dice.hit_chance(t.save_bonus(stat), u.spell_dc, 0, false)
			value = avg * (fail + (0.5 * (1.0 - fail) if aid == "wither" else 0.0))
			if aid == "wither":
				value *= 1.25
		"cursed_blade", "trip", "shoot":
			var p := b.attack_preview(u, t, expr if aid == "cursed_blade" else "", u.ranged_weapon if aid == "shoot" else {})
			value = p.expected * u.attacks_per_action
			if aid == "trip" and not t.prone:
				value += 2.0
			if aid == "cursed_blade":
				value += p.chance * avg * 0.5
		_:
			var ch := Dice.hit_chance(u.spell_attack, b.ac_of(t), b.advantage_for(u, t, true))
			value = ch * avg
			if aid == "scorching_ray":
				value *= 3.0
			elif aid == "life_drain":
				value *= 1.5
			elif aid == "guiding_bolt":
				value += 2.0
	if avg >= t.hp:
		value += 4.0
	return minf(value, t.hp + 4.0)


## Лучшая клетка для площадного умения: урон по врагам минус урон по своим, или польза контроля.
static func _area_plan(b: Battle, u: Combatant, aid: String) -> Dictionary:
	var best := {}
	var seen := {}
	var radius := int(b.ability(aid).get("radius", 1))
	var options := b.ability_targets(u, aid)
	if b.ability(aid).target == "self":
		options = [u.cell] as Array[Vector2i]
	var allowed := {}
	for c in options:
		allowed[c] = true
	# Рассматриваем только клетки рядом с врагами, чтобы не перебирать всё поле.
	for f in b.foes_of(u):
		for c in b.cells_in_radius(f.cell, radius):
			if seen.has(c) or not allowed.has(c):
				continue
			seen[c] = true
			var s := _area_value(b, u, aid, c)
			if s > 0.0 and (best.is_empty() or s > best.score):
				best = {"score": s, "cell": c}
	return best


static func _area_value(b: Battle, u: Combatant, aid: String, c: Vector2i) -> float:
	var expr := b.dice_of(u, aid)
	var avg := Dice.avg_of(expr) if expr != "" else 0.0
	var value := 0.0
	for cell in b.ability_area(u, aid, c):
		var o := b.occupant(cell)
		if o == null or o.dead or (o == u and aid == "thunderwave"):
			continue
		var foe := o.team != u.team
		match aid:
			"thunderwave", "fireball", "bomb":
				if foe:
					if o.conscious():
						value += minf(avg * 0.75, o.hp + 3.0)
				elif not u.has_trait("sculpt"):
					value -= avg * 1.5
			"hallowed_ground":
				if foe and o.undead:
					value += minf(7.0, o.hp + 2.0)
				elif not foe and o.hp < o.max_hp:
					value += minf(3.5, o.max_hp - o.hp) + (6.0 if o.down else 0.0)
			"grease":
				if foe and o.conscious() and not o.prone and not o.is_ranged():
					value += 4.0
				elif not foe:
					value -= 2.0
			"web":
				if foe and o.conscious() and not o.restrained:
					value += 4.0 + o.attacks_per_action
				elif not foe:
					value -= 4.0
			"spike_growth":
				# Враг, идущий через шипы к отряду, получает урон за каждую клетку.
				if foe and o.conscious() and not o.is_ranged() and not b.spikes.has(cell):
					value += avg * 1.5
				elif not foe:
					value -= 1.0
			"slow":
				if foe and o.conscious() and not o.slow_spell:
					value += 3.5 + 2.0 * (o.attacks_per_action - 1) + o.max_hp / 20.0
	if aid == "hallowed_ground" and value < 4.0:
		return 0.0
	return value


static func _self_plan(b: Battle, u: Combatant, aid: String) -> Dictionary:
	var value := 0.0
	match aid:
		"turn_undead":
			for f in b.foes_of(u):
				if f.undead and not f.turned and Battle.dist(f.cell, u.cell) <= int(b.ability(aid).radius):
					var fail := 1.0 - Dice.hit_chance(f.save_bonus("wis"), u.spell_dc, 0, false)
					value += fail * (4.0 + f.attacks_per_action * 2.0)
		"spirit_guardians":
			var close := 0
			for f in b.foes_of(u):
				if Battle.dist(f.cell, u.cell) <= 4:
					close += 1
			value = 6.0 + 5.0 * close
		"knife_fan":
			var dagger := {"to_hit": u.weapon.to_hit, "damage": "1d4+3", "kind": "ranged"}
			for f in b._fan_targets(u):
				value += b.attack_preview(u, f, "", dagger).expected
		"preserve_life":
			var pool := 8 * u.level
			var need := 0
			for o in b.allies_of(u):
				if Battle.dist(o.cell, u.cell) <= 6 and o.hp * 2 < o.max_hp:
					need += o.max_hp / 2 - o.hp + (6 if o.down else 0)
			value = minf(pool, need) * 1.2
			if need < 8:
				return {}
	if value <= 0.0:
		return {}
	return {"score": value, "cell": u.cell}
