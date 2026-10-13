class_name CombatAI
extends RefCounted
## Простой ИИ: враги в бою, а в симуляции — и герои со спутниками.
## Какое умение когда брать, ИИ читает из поля ai умения (abilities.json): фаза хода, приоритет, условие
## и способ выбрать цель. Основное действие выбирается по грубой оценке ожидаемой пользы эффектов.

## Сколько «стоит» одна ячейка заклинания при выборе действия.
const SLOT_VALUE := 2.5


static func take_turn(b: Battle, u: Combatant, use_dark := false) -> void:
	if not u.conscious() or b.outcome != "" or u.action_used and u.bonus_used and u.speed_left == 0:
		return
	if u.team == 1 and not _has_active_abilities(b, u):
		_enemy_turn(b, u)
	else:
		_hero_turn(b, u, use_dark)


## Есть ли у участника умения, которыми ИИ пользуется (кроме базовых действий).
static func _has_active_abilities(b: Battle, u: Combatant) -> bool:
	for aid in u.abilities:
		if not b.ability(aid).get("ai", {}).get("skip", false):
			return true
	return false


static func _ai(b: Battle, aid: String) -> Dictionary:
	return b.ability(aid).get("ai", {})


# --- Враги ----------------------------------------------------------------

static func _enemy_turn(b: Battle, u: Combatant) -> void:
	if b.mod_any(u, "flee"):
		_flee(b, u)
		return
	var target := _pick_target(b, u)
	if target == null:
		return
	if u.is_ranged():
		var r := int(u.weapon.get("range", 1))
		var taunter := _taunter(b, u)
		if taunter != null:
			# Провокация действует и на стрелков: подходят на выстрел и бьют только Гаррета.
			if not _foes_in_range(b, u, r).has(taunter):
				_move_toward(b, u, taunter, r)
			var g := 0
			while b.can_attack(u, taunter) and b.outcome == "" and g < 4:
				g += 1
				b.attack(u, taunter)
			return
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


## Кто спровоцировал участника, если провокация ещё действует.
static func _taunter(b: Battle, u: Combatant) -> Combatant:
	if not b.mod_any(u, "forced_target"):
		return null
	for sid in u.statuses:
		if CombatData.status_def(sid).get("forced_target", false):
			var t := b.get_unit(u.status_src(sid))
			if t != null and t.conscious():
				return t
	return null


static func _pick_target(b: Battle, u: Combatant) -> Combatant:
	var taunter := _taunter(b, u)
	if taunter != null:
		return taunter
	if u.team == 1 and b.difficulty == "trial":
		return _best_victim(b, u, b.foes_of(u))
	var best: Combatant = null
	for f in b.foes_of(u):
		if b.mod_any(f, "flee") and u.team == 0 and best != null:
			continue
		if b.is_hidden(f):
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
		# Спрятавшегося не видно, пока он сам не атакует.
		if not f.conscious() or b.is_hidden(f):
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
				if g != f and b.can_react(g) and Battle.dist(u.cell, g.cell) <= g.reach():
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
		if b.is_hidden(f) and u.team == 1:
			continue
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
		if b.zones.grease.has(c) or b.zones.web.has(c) or (u.team == 0 and b.zones.spikes.has(c)):
			score += 25
		if c != u.cell and (u.team == 0 or b.difficulty == "trial"):
			score += b.count_opportunity(u, b.path_to(u, c, reach)) * 15
		if score < best_score:
			best_score = score
			best_cell = c
	if best_cell != u.cell:
		b.move_along(u, b.path_to(u, best_cell, reach))


static func _approach_and_attack(b: Battle, u: Combatant, target: Combatant, do_attack: Callable) -> void:
	# Стрелок с умениями (арбалетчик) подходит на выстрел, а не вплотную.
	var want := int(u.weapon.get("range", 1)) if u.is_ranged() else u.reach()
	if not b.in_weapon_range(u, target):
		_move_toward(b, u, target, want)
	if not u.conscious():
		return
	if b.in_weapon_range(u, target) and target.conscious():
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


# --- Ход героя (и врага с умениями) ---------------------------------------

static func _hero_turn(b: Battle, u: Combatant, use_dark: bool) -> void:
	_bonus_phase(b, u, use_dark, "before")
	if b.outcome != "" or not u.conscious():
		return
	_main_action(b, u, use_dark)
	if b.outcome != "" or not u.conscious():
		return
	for aid in _phase(b, u, "surge"):
		if u.action_used and b.can_use(u, aid):
			b.use_ability(u, aid, u.cell)
			_main_action(b, u, use_dark)
	if b.outcome != "" or not u.conscious():
		return
	if not u.bonus_used:
		_bonus_phase(b, u, use_dark, "after")


## Умения участника для фазы хода, по приоритету (меньше — раньше).
static func _phase(b: Battle, u: Combatant, phase: String) -> Array[String]:
	var list: Array[String] = []
	for aid in u.abilities:
		var ai := _ai(b, aid)
		if ai.get("phase", "") == phase or (phase == "after" and ai.has("after")):
			list.append(aid)
	list.sort_custom(func(x: String, y: String) -> bool:
		return _priority(b, x, phase) < _priority(b, y, phase))
	return list


static func _priority(b: Battle, aid: String, phase: String) -> int:
	var ai := _ai(b, aid)
	if phase == "after" and ai.has("after"):
		return 0
	return int(ai.get("priority", 50))


static func _wounded(o: Combatant) -> bool:
	return o.down or o.hp * 10 < o.max_hp * 4


## Бонусное умение до или после основного действия: первое по приоритету, у которого выполнено условие.
static func _bonus_phase(b: Battle, u: Combatant, use_dark: bool, phase: String) -> void:
	for aid in _phase(b, u, phase):
		if not b.can_use(u, aid):
			continue
		if b.ability(aid).has("dark") and not use_dark:
			continue
		var ai := _ai(b, aid)
		if not _when(b, u, aid, ai.get("when", {})):
			continue
		var pick := String(ai.get("after", "")) if phase == "after" and ai.has("after") else String(ai.get("pick", "self"))
		var cell := _pick_cell(b, u, aid, pick, ai)
		if cell.x < 0:
			continue
		b.use_ability(u, aid, cell)
		return


## Условия из ai.when.
static func _when(b: Battle, u: Combatant, aid: String, when: Dictionary) -> bool:
	var near := _nearest_foe_dist(b, u)
	for key in when:
		var v = when[key]
		match String(key):
			"self_hp_below":
				if not u.hp < u.max_hp * float(v):
					return false
			"self_hp_above":
				if not u.hp > u.max_hp * float(v):
					return false
			"foe_within_move":
				if near > u.speed_left + int(v):
					return false
			"no_foe_within":
				if near <= int(v):
					return false
			"foes_within":
				var close := 0
				for f in b.foes_of(u):
					if Battle.dist(f.cell, u.cell) <= int(v[0]):
						close += 1
				if close < int(v[1]):
					return false
			"allies_within":
				var near_allies := 0
				for o in b.allies_of(u):
					if o != u and o.conscious() and Battle.dist(o.cell, u.cell) <= int(v[0]):
						near_allies += 1
				if near_allies < int(v[1]):
					return false
			"hp_above_dark_cost":
				if u.hp <= int(v) * b.dark_hp_cost(u):
					return false
			"wounded_allies":
				var hurt := 0
				for o in b.allies_of(u):
					if _wounded(o) and Battle.dist(o.cell, u.cell) <= b.radius_of(u, aid):
						hurt += 1
				if hurt < int(v):
					return false
			"slots_at_least":
				if u.slots < int(v):
					return false
			"status_or_slots":
				if not u.has_status(String(v[0])) and u.slots < int(v[1]):
					return false
	return true


## Клетка цели для бонусного умения или (-1, -1), если подходящей нет.
static func _pick_cell(b: Battle, u: Combatant, aid: String, pick: String, ai: Dictionary) -> Vector2i:
	var none := Vector2i(-1, -1)
	var targets := b.ability_targets(u, aid)
	match pick:
		"self":
			return u.cell
		"wounded_ally":
			var best: Combatant = null
			for o in b.allies_of(u):
				if _wounded(o) and targets.has(o.cell):
					if best == null or (o.down and not best.down) or o.hp < best.hp:
						best = o
			if best == null and ai.get("reach_down_ally", false):
				# Выбывший союзник вне досягаемости: подойти к нему, чтобы поднять.
				for o in b.allies_of(u):
					if o.down and o != u:
						_move_toward(b, u, o, int(b.ability(aid).get("range", 1)))
						if b.ability_targets(u, aid).has(o.cell):
							best = o
						break
			return best.cell if best != null else none
		"down_ally":
			for o in b.allies_of(u):
				if o.down and targets.has(o.cell):
					return o.cell
			return none
		"weakest_foe":
			if targets.is_empty():
				return none
			var best_c := targets[0]
			for c in targets:
				if b.occupant(c).hp < b.occupant(best_c).hp:
					best_c = c
			return best_c
		"guard_ally":
			for o in b.allies_of(u):
				if o.conscious() and targets.has(o.cell) and _nearest_foe_dist(b, o) <= 2:
					return o.cell
			return none
	return none


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
		var a := b.ability(aid)
		if a.get("ai", {}).get("skip", false) or a.cost != "action" or not b.can_use(u, aid):
			continue
		var dark: bool = a.has("dark")
		if dark and not use_dark:
			continue
		var plan := _ability_plan(b, u, aid, target)
		if plan.is_empty():
			continue
		var score: float = plan.score
		if a.get("resource", "none") == "slot":
			score -= SLOT_VALUE * b.slot_cost(aid)
			if u.abilities.has("healing_word") and u.slots - b.slot_cost(aid) < 1:
				score -= 8.0
		if dark:
			score += 3.0
			# Цена дара: ячейка у заклинателя, хиты у воина и плута.
			if String(a.dark) == "slot":
				score -= SLOT_VALUE
				if u.abilities.has("healing_word") and u.slots < 2:
					score -= 8.0
			else:
				score -= b.dark_hp_cost(u) * 0.5
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
			_move_toward(b, u, t, int(a2.get("range", 1)))
		elif a2.target == "self":
			_move_toward(b, u, target, 1)
	if b.ability_targets(u, best_aid).has(best_cell):
		b.use_ability(u, best_aid, best_cell)
		if a2.get("attack", false):
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


## Атака оружием; перед ней — умения фазы weapon («Рывок», если не дойти; «Безрассудная атака», если дойти).
static func _weapon_action(b: Battle, u: Combatant, target: Combatant) -> void:
	for aid in _phase(b, u, "weapon"):
		if not b.can_use(u, aid):
			continue
		var walk := int(b.walk_distances(target.cell).get(u.cell, 99))
		var reachable := walk - u.reach() <= u.speed_left
		var when: Dictionary = _ai(b, aid).get("when", {})
		if when.get("target_out_of_reach", false) and reachable:
			continue
		if when.get("target_reachable", false) and not reachable:
			continue
		var rest := when.duplicate()
		rest.erase("target_out_of_reach")
		rest.erase("target_reachable")
		if _when(b, u, aid, rest):
			b.use_ability(u, aid, u.cell)
	_approach_and_attack(b, u, target, func() -> void: b.attack(u, target))


# --- Оценка умений ----------------------------------------------------------

## План умения: {"score", "cell"} или пустой словарь, если применять незачем.
static func _ability_plan(b: Battle, u: Combatant, aid: String, main_target: Combatant) -> Dictionary:
	var a := b.ability(aid)
	var kind := String(a.get("ai", {}).get("kind", ""))
	if kind in ["turn", "aura", "fan", "heal_pool"]:
		return _self_plan(b, u, aid, kind)
	if b.params_of(u, aid).has("radius"):
		return _area_plan(b, u, aid)
	if a.target != "enemy":
		return {}
	# Одна цель: лучшая из тех, что уже в досягаемости, иначе главная цель, если до неё можно дойти.
	var best := {}
	var candidates: Array[Combatant] = []
	for c in b.ability_targets(u, aid):
		candidates.append(b.occupant(c))
	if candidates.is_empty():
		var gap := Battle.dist(u.cell, main_target.cell) - int(a.get("range", 1))
		if gap <= u.speed_left:
			candidates.append(main_target)
	for t in candidates:
		var s := _single_value(b, u, aid, t)
		if best.is_empty() or s > best.score:
			best = {"score": s, "cell": t.cell}
	return best


## Ожидаемая польза от умения по одной цели — по его первому эффекту урона.
static func _single_value(b: Battle, u: Combatant, aid: String, t: Combatant) -> float:
	var a := b.ability(aid)
	var p := b.params_of(u, aid)
	var expr := String(p.get("dice", ""))
	var avg := Dice.avg_of(expr) if expr != "" else 0.0
	var value := 0.0
	var gives_ally_heal := false
	for e in a.effects:
		if e.op == "heal" and e.get("amount", "") == "half_dealt":
			gives_ally_heal = true
	for e in a.effects:
		match String(e.op):
			"damage":
				value = avg
			"save_damage":
				var fail := 1.0 - Dice.hit_chance(t.save_bonus(String(e.stat)), u.spell_dc, 0, false)
				value = avg * (fail + (0.5 * (1.0 - fail) if e.get("half", false) else 0.0))
				if gives_ally_heal:
					value *= 1.25
			"weapon_attack":
				var w = e.get("weapon", "main")
				var weapon: Dictionary = u.ranged_weapon if w is String and w == "ranged" else {}
				var extra := String(CombatData.resolve(e.get("extra_dice", ""), p))
				var pv := b.attack_preview(u, t, extra, weapon)
				value = pv.expected * u.attacks_per_action
				value += _on_hit_value(e, t)
				if e.get("drain_extra", false):
					value += pv.chance * avg * 0.5
			"save":
				# Контроль без урона («Аркан»): шанс провала × польза состояния.
				if e.get("not_undead", false) and t.undead:
					return 0.0
				var fail_s := 1.0 - Dice.hit_chance(t.save_bonus(String(e.stat)), b._dc(e, u), 0, false)
				for x in e.get("on_fail", []):
					if x.op == "status" and not t.has_status(String(x.status)):
						value += fail_s * float(CombatData.status_def(String(x.status)).get("ai_value", 0))
			"spell_attack":
				var ch := Dice.hit_chance(u.spell_attack, b.ac_of(t), b.advantage_for(u, t, true))
				value = ch * avg * int(CombatData.resolve(e.get("repeat", 1), p))
				if e.get("drain", false):
					value *= 1.5
				value += _on_hit_value(e, t)
			_:
				continue
		break
	if avg >= t.hp:
		value += 4.0
	return minf(value, t.hp + 4.0)


## Польза состояний, которые умение накладывает при попадании (ai_value в statuses.json).
static func _on_hit_value(e: Dictionary, t: Combatant) -> float:
	var v := 0.0
	for sub in e.get("on_hit", []):
		var effects: Array = [sub] + sub.get("on_fail", [])
		for x in effects:
			if x.op == "status" and not t.has_status(String(x.status)):
				v += float(CombatData.status_def(String(x.status)).get("ai_value", 0))
	return v


## Лучшая клетка для площадного умения: урон по врагам минус урон по своим, или польза контроля.
static func _area_plan(b: Battle, u: Combatant, aid: String) -> Dictionary:
	var best := {}
	var seen := {}
	var radius := maxi(b.radius_of(u, aid), 1)
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
	var a := b.ability(aid)
	var ai: Dictionary = a.get("ai", {})
	var p := b.params_of(u, aid)
	var ctx := {"user": u, "aid": aid, "cell": c, "params": p}
	var value := 0.0
	for e in a.effects:
		var expr := String(CombatData.resolve(e.get("dice", "$dice"), p))
		var avg := Dice.avg_of(expr) if expr != "" else 0.0
		match String(e.op):
			"save_damage", "damage":
				for o in b._select(e, ctx):
					if o.team != u.team:
						if o.conscious():
							value += minf(avg * (0.75 if e.op == "save_damage" else 1.0), o.hp + (3.0 if e.op == "save_damage" else 2.0))
					else:
						value -= avg * 1.5
			"heal":
				for o in b._select(e, ctx):
					if o.hp < o.max_hp:
						value += minf(avg, o.max_hp - o.hp) + (6.0 if o.down else 0.0)
			"zone":
				for cell in b.ability_area(u, aid, c):
					var o := b.occupant(cell)
					if o == null or o.dead:
						continue
					if o.team == u.team:
						value += float(ai.get("ally", 0))
						continue
					if not o.conscious() or _zone_skip(b, o, ai.get("foe_skip", []), cell, String(e.kind)):
						continue
					value += float(ai.get("foe", 0)) + float(ai.get("foe_per_attack", 0)) * o.attacks_per_action
					value += float(ai.get("foe_dice_mult", 0)) * avg
			"save":
				if ai.get("kind", "") == "slow":
					for o in b._select(e, ctx):
						value += 3.5 + 2.0 * (o.attacks_per_action - 1) + o.max_hp / 20.0
	if value < float(ai.get("min_value", 0)):
		return 0.0
	return value


static func _zone_skip(b: Battle, o: Combatant, skip: Array, cell: Vector2i, kind: String) -> bool:
	for s in skip:
		match String(s):
			"ranged":
				if o.is_ranged():
					return true
			"on_zone":
				if b.zones[kind].has(cell):
					return true
			_:
				if o.has_status(String(s)):
					return true
	return false


static func _self_plan(b: Battle, u: Combatant, aid: String, kind: String) -> Dictionary:
	var a := b.ability(aid)
	var p := b.params_of(u, aid)
	var value := 0.0
	match kind:
		"turn":
			var e: Dictionary = a.effects[0]
			for f in b.foes_of(u):
				if f.undead and not f.has_status("turned") and Battle.dist(f.cell, u.cell) <= int(p.get("radius", 0)):
					var fail := 1.0 - Dice.hit_chance(f.save_bonus(String(e.stat)), u.spell_dc, 0, false)
					value += fail * (4.0 + f.attacks_per_action * 2.0)
		"aura":
			var close := 0
			for f in b.foes_of(u):
				if Battle.dist(f.cell, u.cell) <= 4:
					close += 1
			value = 6.0 + 5.0 * close
		"fan":
			var dagger := {"to_hit": u.weapon.to_hit, "damage": String(p.get("dagger", "1d4+3")), "kind": "ranged"}
			for f in b._nearest_foes(u, int(p.get("radius", 0)), int(p.get("count", 3))):
				value += b.attack_preview(u, f, "", dagger).expected
		"heal_pool":
			var pool := int(p.get("per_level", 8)) * u.level
			var need := 0
			for o in b.allies_of(u):
				if Battle.dist(o.cell, u.cell) <= int(p.get("radius", 6)) and o.hp * 2 < o.max_hp:
					need += o.max_hp / 2 - o.hp + (6 if o.down else 0)
			value = minf(pool, need) * 1.2
			if need < int(a.ai.get("min_need", 0)):
				return {}
	if value <= 0.0:
		return {}
	return {"score": value, "cell": u.cell}
