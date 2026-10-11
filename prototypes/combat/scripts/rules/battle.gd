class_name Battle
extends RefCounted
## Состояние и правила боя. Без узлов сцены: используется интерфейсом, тестами и симуляцией.

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]
## Режим «История»: урон врагов умножается на этот коэффициент.
const STORY_ENEMY_DAMAGE := 0.6
const DARK_GIFT_COST := 2
const DARK_BATTLE_CAP := 6

var title := ""
var width := 12
var height := 12
var obstacles := {}
var units: Array[Combatant] = []
var order: Array[String] = []
var turn_index := 0
var round_num := 1
var rng := RandomNumberGenerator.new()
var difficulty := "story"
var darkness := 0
var darkness_gained := 0
var traps := {}
var outcome := ""
var log_lines: Array[String] = []
## События для интерфейса: всплывающий урон и т. п. Интерфейс забирает их через take_events().
var events: Array[Dictionary] = []


func setup(scenario: Dictionary, seed_value: int = -1, diff := "story") -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	difficulty = diff
	title = scenario.get("title", "")
	width = scenario.width
	height = scenario.height
	for o in scenario.obstacles:
		obstacles[o] = true
	for u in scenario.units:
		units.append(u)
	for u in units:
		u.initiative = Dice.d20(rng) + u.init_mod
	var sorted := units.duplicate()
	sorted.sort_custom(func(a: Combatant, b: Combatant) -> bool:
		if a.initiative != b.initiative:
			return a.initiative > b.initiative
		return a.team < b.team)
	for u in sorted:
		order.append(u.id)
	turn_index = 0
	round_num = 1
	log_line("Бой начался. Раунд 1.")
	_start_turn()


# --- Доступ к участникам ---------------------------------------------------

func get_unit(uid: String) -> Combatant:
	for u in units:
		if u.id == uid:
			return u
	return null


func current() -> Combatant:
	return get_unit(order[turn_index])


func occupant(cell: Vector2i) -> Combatant:
	for u in units:
		if not u.dead and u.cell == cell:
			return u
	return null


func heroes() -> Array[Combatant]:
	return _team(0)


func enemies() -> Array[Combatant]:
	return _team(1)


func _team(team: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for u in units:
		if u.team == team:
			out.append(u)
	return out


func foes_of(u: Combatant) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for o in units:
		if o.team != u.team and o.conscious():
			out.append(o)
	return out


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func is_obstacle(c: Vector2i) -> bool:
	return obstacles.has(c)


static func dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func cells_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var c := Vector2i(x, y)
			if in_bounds(c) and not is_obstacle(c):
				out.append(c)
	return out


# --- Передвижение ----------------------------------------------------------

## Клетки, куда юнит может дойти за оставшееся движение: {клетка: {"cost", "prev"}}.
## Через союзников проходить можно, останавливаться на занятой клетке нельзя.
func reachable(u: Combatant) -> Dictionary:
	var best := {u.cell: {"cost": 0, "prev": u.cell}}
	var frontier: Array[Vector2i] = [u.cell]
	while not frontier.is_empty():
		var next: Array[Vector2i] = []
		for c in frontier:
			var cost: int = best[c].cost
			if cost >= u.speed_left:
				continue
			for d in DIRS:
				var n := c + d
				if not in_bounds(n) or is_obstacle(n) or best.has(n):
					continue
				if d.x != 0 and d.y != 0 and (is_obstacle(c + Vector2i(d.x, 0)) or is_obstacle(c + Vector2i(0, d.y))):
					continue
				var o := occupant(n)
				if o != null and o.team != u.team and o.conscious():
					continue
				best[n] = {"cost": cost + 1, "prev": c}
				next.append(n)
		frontier = next
	var out := {}
	for c in best:
		var o := occupant(c)
		if c == u.cell or o == null:
			out[c] = best[c]
	# Клетки с союзниками нужны для восстановления пути, но не как цель.
	out["_all"] = best
	return out


func path_to(u: Combatant, target: Vector2i, reach_map: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not reach_map.has(target) or target == u.cell:
		return path
	var all: Dictionary = reach_map["_all"]
	var c := target
	while c != u.cell:
		path.push_front(c)
		c = all[c].prev
	return path


## Сколько атак при возможности спровоцирует путь (без учёта того, что юнит может выбыть раньше).
func count_opportunity(u: Combatant, path: Array[Vector2i]) -> int:
	if u.disengaged:
		return 0
	var count := 0
	var used := {}
	var from := u.cell
	for step in path:
		for e in foes_of(u):
			if used.has(e.id) or e.reaction_used or e.is_ranged():
				continue
			if dist(from, e.cell) <= e.reach() and dist(step, e.cell) > e.reach():
				used[e.id] = true
				count += 1
		from = step
	return count


func move_along(u: Combatant, path: Array[Vector2i]) -> void:
	for step in path:
		if not u.conscious() or u.speed_left <= 0:
			break
		if not u.disengaged:
			for e in foes_of(u):
				if e.reaction_used or e.is_ranged():
					continue
				if dist(u.cell, e.cell) <= e.reach() and dist(step, e.cell) > e.reach():
					e.reaction_used = true
					log_line("%s атакует при возможности." % e.name)
					_weapon_attack(e, u, {})
					if not u.conscious():
						return
		u.cell = step
		u.speed_left -= 1
		if traps.has(step) and u.team == 1:
			traps.erase(step)
			var dmg := Dice.roll(rng, "2d6")
			log_line("%s попадает в ловушку!" % u.name)
			deal_damage(u, dmg, "trap")
			u.speed_left = 0
			return


# --- Атаки ----------------------------------------------------------------

func advantage_for(attacker: Combatant, target: Combatant, ranged: bool) -> int:
	var adv := 0
	var dis := 0
	if attacker.hidden:
		adv += 1
	if target.prone:
		if ranged:
			dis += 1
		else:
			adv += 1
	if attacker.prone:
		dis += 1
	if ranged:
		for f in foes_of(attacker):
			if dist(f.cell, attacker.cell) <= 1:
				dis += 1
				break
	if adv > 0 and dis > 0:
		return 0
	return 1 if adv > 0 else (-1 if dis > 0 else 0)


func can_sneak(attacker: Combatant, target: Combatant, adv: int) -> bool:
	if attacker.sneak_dice == "" or attacker.sneak_used or adv < 0:
		return false
	if adv > 0:
		return true
	for ally in units:
		if ally != attacker and ally.team == attacker.team and ally.conscious() and dist(ally.cell, target.cell) <= 1:
			return true
	return false


func enemy_damage_scale(attacker: Combatant) -> float:
	return STORY_ENEMY_DAMAGE if attacker.team == 1 and difficulty == "story" else 1.0


## Прогноз атаки оружием для интерфейса и ИИ.
func attack_preview(attacker: Combatant, target: Combatant, extra_dice := "") -> Dictionary:
	var ranged := attacker.is_ranged()
	var adv := advantage_for(attacker, target, ranged)
	var chance := Dice.hit_chance(int(attacker.weapon.to_hit), target.total_ac(), adv)
	var dmg_expr: String = attacker.weapon.damage
	var lo := Dice.min_of(dmg_expr)
	var hi := Dice.max_of(dmg_expr)
	var avg := Dice.avg_of(dmg_expr)
	if extra_dice != "":
		lo += Dice.min_of(extra_dice)
		hi += Dice.max_of(extra_dice)
		avg += Dice.avg_of(extra_dice)
	if can_sneak(attacker, target, adv):
		lo += Dice.min_of(attacker.sneak_dice)
		hi += Dice.max_of(attacker.sneak_dice)
		avg += Dice.avg_of(attacker.sneak_dice)
	var scale := enemy_damage_scale(attacker)
	return {"chance": chance, "adv": adv, "min": int(ceil(lo * scale)), "max": int(ceil(hi * scale)),
		"avg": avg * scale, "expected": chance * avg * scale}


func in_weapon_range(attacker: Combatant, target: Combatant) -> bool:
	if attacker.is_ranged():
		return dist(attacker.cell, target.cell) <= int(attacker.weapon.get("range", 1))
	return dist(attacker.cell, target.cell) <= attacker.reach()


## Атака оружием. Возвращает нанесённый урон (0 при промахе).
func _weapon_attack(attacker: Combatant, target: Combatant, opts: Dictionary) -> int:
	var ranged := attacker.is_ranged()
	var adv := advantage_for(attacker, target, ranged)
	var r1 := Dice.d20(rng)
	var r2 := Dice.d20(rng)
	var roll := r1
	if adv > 0:
		roll = maxi(r1, r2)
	elif adv < 0:
		roll = mini(r1, r2)
	attacker.hidden = false
	var total := roll + int(attacker.weapon.to_hit)
	var crit := roll == 20
	if roll == 1 or (not crit and total < target.total_ac()):
		log_line("%s → %s: промах (%d против КД %d)." % [attacker.name, target.name, total, target.total_ac()])
		events.append({"type": "miss", "unit": target.id})
		return 0
	var dmg := Dice.roll(rng, attacker.weapon.damage, crit)
	if can_sneak(attacker, target, adv):
		attacker.sneak_used = true
		dmg += Dice.roll(rng, attacker.sneak_dice, crit)
	var extra := 0
	if opts.has("extra_dice"):
		extra = Dice.roll(rng, opts.extra_dice, crit)
		dmg += extra
	dmg = int(ceil(dmg * enemy_damage_scale(attacker)))
	log_line("%s → %s: %s%d урона." % [attacker.name, target.name, "крит! " if crit else "", dmg])
	deal_damage(target, dmg, "weapon")
	if opts.has("drain_extra") and extra > 0:
		heal(attacker, extra / 2)
	return dmg


func deal_damage(target: Combatant, amount: int, _kind: String) -> void:
	if amount <= 0 or target.dead:
		return
	target.hp = maxi(target.hp - amount, 0)
	events.append({"type": "damage", "unit": target.id, "amount": amount})
	if target.hp == 0:
		if target.team == 0:
			if not target.down:
				target.down = true
				target.prone = true
				log_line("%s выбывает из боя." % target.name)
		else:
			target.dead = true
			log_line("%s повержен." % target.name)
	_check_outcome()


func heal(target: Combatant, amount: int) -> void:
	if amount <= 0 or target.dead:
		return
	var was_down := target.down
	target.hp = mini(target.hp + amount, target.max_hp)
	if target.hp > 0 and target.down:
		target.down = false
	events.append({"type": "heal", "unit": target.id, "amount": amount})
	if was_down and not target.down:
		log_line("%s снова в строю." % target.name)


func saving_throw(target: Combatant, stat: String, dc: int) -> bool:
	return Dice.d20(rng) + target.save_bonus(stat) >= dc


# --- Действия хода -------------------------------------------------------

func can_attack(u: Combatant, target: Combatant) -> bool:
	return u.conscious() and not u.action_used and target.conscious() and target.team != u.team and in_weapon_range(u, target)


func attack(u: Combatant, target: Combatant) -> void:
	if not can_attack(u, target):
		return
	u.action_used = true
	_weapon_attack(u, target, {})


func ability(aid: String) -> Dictionary:
	return Content.ABILITIES[aid]


func can_use(u: Combatant, aid: String) -> bool:
	if not u.conscious() or not u.abilities.has(aid):
		return false
	var a := ability(aid)
	if a.cost == "action" and u.action_used:
		return false
	if a.cost == "bonus" and u.bonus_used:
		return false
	if a.resource == "slot" and u.slots <= 0:
		return false
	if a.resource == "use" and u.uses_left(aid) <= 0:
		return false
	return true


## Допустимые цели способности: список клеток.
func ability_targets(u: Combatant, aid: String) -> Array[Vector2i]:
	var a := ability(aid)
	var out: Array[Vector2i] = []
	var rng_cells: int = a.range
	match String(a.target):
		"self":
			out.append(u.cell)
		"enemy":
			for f in foes_of(u):
				if dist(u.cell, f.cell) <= rng_cells:
					out.append(f.cell)
		"ally":
			for o in units:
				if o.team == u.team and not o.dead and dist(u.cell, o.cell) <= rng_cells:
					if aid == "shield_of_faith" and (o.ac_bonus > 0 or o.down):
						continue
					out.append(o.cell)
		"cell":
			for x in width:
				for y in height:
					var c := Vector2i(x, y)
					if not is_obstacle(c) and dist(u.cell, c) <= rng_cells:
						out.append(c)
		"empty_cell":
			for x in width:
				for y in height:
					var c := Vector2i(x, y)
					if not is_obstacle(c) and occupant(c) == null and not traps.has(c) and dist(u.cell, c) <= rng_cells:
						out.append(c)
	return out


## Клетки, которые заденет способность при выборе цели.
func ability_area(u: Combatant, aid: String, target: Vector2i) -> Array[Vector2i]:
	var a := ability(aid)
	if a.has("radius") and a.target == "self":
		return cells_in_radius(u.cell, int(a.radius))
	if a.has("radius"):
		return cells_in_radius(target, int(a.radius))
	var single: Array[Vector2i] = [target]
	return single


func ability_preview(u: Combatant, aid: String, target: Vector2i) -> String:
	var a := ability(aid)
	var t := occupant(target)
	match aid:
		"cursed_blade", "trip":
			if t != null:
				var p := attack_preview(u, t, "1d8" if aid == "cursed_blade" else "")
				return "%s: шанс %d%%, урон %d–%d" % [a.name, roundi(p.chance * 100), p.min, p.max]
		"fire_bolt", "life_drain":
			if t != null:
				var expr := "1d10" if aid == "fire_bolt" else "3d6"
				var ch := Dice.hit_chance(Content.SPELL_ATTACK, t.total_ac(), advantage_for(u, t, true))
				return "%s: шанс %d%%, урон %d–%d" % [a.name, roundi(ch * 100), Dice.min_of(expr), Dice.max_of(expr)]
		"sacred_flame", "wither":
			if t != null:
				var stat := "dex" if aid == "sacred_flame" else "con"
				var fail := 1.0 - Dice.hit_chance(t.save_bonus(stat), Content.SPELL_DC, 0, false)
				var expr2 := "1d8" if aid == "sacred_flame" else "2d8"
				return "%s: провал спасброска %d%%, урон %d–%d" % [a.name, roundi(fail * 100), Dice.min_of(expr2), Dice.max_of(expr2)]
		"magic_missile":
			return "%s: без промаха, урон 6–15" % a.name
	var hit := []
	for c in ability_area(u, aid, target):
		var o := occupant(c)
		if o != null:
			hit.append(o.name)
	if hit.is_empty():
		return a.name
	return "%s: задевает %s" % [a.name, ", ".join(hit)]


func use_ability(u: Combatant, aid: String, target: Vector2i) -> bool:
	if not can_use(u, aid):
		return false
	if not ability_targets(u, aid).has(target):
		return false
	var a := ability(aid)
	if a.cost == "action":
		u.action_used = true
	else:
		u.bonus_used = true
	if a.resource == "slot":
		u.slots -= 1
	elif a.resource == "use":
		u.uses[aid] = u.uses_left(aid) - 1
	log_line("%s: %s." % [u.name, a.name])
	var t := occupant(target)
	match aid:
		"second_wind":
			heal(u, Dice.roll(rng, "1d10+2"))
		"disengage":
			u.disengaged = true
		"sacred_flame":
			_save_spell(t, "dex", "1d8", false)
		"healing_word":
			heal(t, Dice.roll(rng, "1d4+3"))
		"fire_bolt":
			_spell_attack(u, t, "1d10", false)
		"magic_missile":
			deal_damage(t, Dice.roll(rng, "3d4+3"), "force")
		"thunderwave":
			for c in ability_area(u, aid, target):
				var o := occupant(c)
				if o != null and o != u and not o.dead:
					_save_spell(o, "con", "2d8", true)
		"hallowed_ground":
			for c in ability_area(u, aid, target):
				var o := occupant(c)
				if o == null or o.dead:
					continue
				if o.team == u.team:
					heal(o, Dice.roll(rng, "1d6"))
				elif o.undead:
					deal_damage(o, Dice.roll(rng, "2d6"), "radiant")
		"shield_of_faith":
			t.ac_bonus = 2
		"trip":
			if _weapon_attack(u, t, {}) > 0 and t.conscious():
				if not saving_throw(t, "str", Content.SPELL_DC):
					t.prone = true
					log_line("%s падает." % t.name)
		"taunt":
			for f in foes_of(u):
				if dist(f.cell, u.cell) <= int(a.radius):
					f.taunted_by = u.id
					f.taunt_turns = 1
		"bomb":
			for c in ability_area(u, aid, target):
				var o := occupant(c)
				if o != null and not o.dead:
					_save_spell(o, "dex", "2d6", true)
		"trap":
			traps[target] = u.id
		"cursed_blade":
			_weapon_attack(u, t, {"extra_dice": "1d8", "drain_extra": true})
		"shadow_step":
			u.hidden = true
			u.disengaged = true
		"wither":
			var dealt := _save_spell(t, "con", "2d8", true)
			var ally := _most_wounded_ally(u)
			if ally != null and dealt > 0:
				heal(ally, dealt)
		"life_drain":
			var d2 := _spell_attack(u, t, "3d6", false)
			if d2 > 0:
				heal(u, d2 / 2)
	if a.get("dark", false):
		_add_darkness()
	return true


func _spell_attack(u: Combatant, t: Combatant, expr: String, _half: bool) -> int:
	var adv := advantage_for(u, t, true)
	var r1 := Dice.d20(rng)
	var r2 := Dice.d20(rng)
	var roll := r1 if adv == 0 else (maxi(r1, r2) if adv > 0 else mini(r1, r2))
	u.hidden = false
	if roll == 1 or (roll != 20 and roll + Content.SPELL_ATTACK < t.total_ac()):
		log_line("Промах по %s." % t.name)
		events.append({"type": "miss", "unit": t.id})
		return 0
	var dmg := Dice.roll(rng, expr, roll == 20)
	deal_damage(t, dmg, "spell")
	return dmg


func _save_spell(t: Combatant, stat: String, expr: String, half_on_save: bool) -> int:
	var dmg := Dice.roll(rng, expr)
	if saving_throw(t, stat, Content.SPELL_DC):
		dmg = dmg / 2 if half_on_save else 0
		log_line("%s спасается%s." % [t.name, " частично" if half_on_save else ""])
	deal_damage(t, dmg, "spell")
	return dmg


func _most_wounded_ally(u: Combatant) -> Combatant:
	var best: Combatant = null
	for o in units:
		if o.team == u.team and not o.dead and o.hp < o.max_hp:
			if best == null or float(o.hp) / o.max_hp < float(best.hp) / best.max_hp:
				best = o
	return best


func _add_darkness() -> void:
	var gain := mini(DARK_GIFT_COST, DARK_BATTLE_CAP - darkness_gained)
	if gain > 0:
		darkness += gain
		darkness_gained += gain


static func darkness_level(value: int) -> String:
	if value >= 75:
		return "Бездна"
	if value >= 50:
		return "Мрак"
	if value >= 25:
		return "Сумрак"
	return "Тень"


# --- Ходы ----------------------------------------------------------------

func _start_turn() -> void:
	var u := current()
	u.speed_left = u.speed
	u.action_used = false
	u.bonus_used = false
	u.sneak_used = false
	u.disengaged = false
	u.reaction_used = false
	if u.prone and u.conscious():
		u.prone = false
		u.speed_left = u.speed / 2


func end_turn() -> void:
	if outcome != "":
		return
	var u := current()
	if u.taunt_turns > 0:
		u.taunt_turns -= 1
		if u.taunt_turns == 0:
			u.taunted_by = ""
	for i in order.size():
		turn_index += 1
		if turn_index >= order.size():
			turn_index = 0
			round_num += 1
			log_line("Раунд %d." % round_num)
		var n := current()
		if n.conscious():
			break
	_start_turn()


func _check_outcome() -> void:
	if outcome != "":
		return
	if heroes().all(func(h: Combatant) -> bool: return not h.conscious()):
		outcome = "defeat"
		log_line("Все герои выбыли. Поражение.")
	elif enemies().all(func(e: Combatant) -> bool: return e.dead):
		outcome = "victory"
		log_line("Победа!")


func log_line(text: String) -> void:
	log_lines.append(text)


func take_events() -> Array[Dictionary]:
	var out := events.duplicate()
	events.clear()
	return out


# --- Сохранение ----------------------------------------------------------

func to_dict() -> Dictionary:
	var obs := []
	for o in obstacles:
		obs.append([o.x, o.y])
	var tr := []
	for t in traps:
		tr.append([t.x, t.y, traps[t]])
	return {
		"version": 1, "title": title, "width": width, "height": height, "obstacles": obs,
		"units": units.map(func(u: Combatant) -> Dictionary: return u.to_dict()),
		"order": Array(order), "turn_index": turn_index, "round": round_num,
		"rng_seed": str(rng.seed), "rng_state": str(rng.state), "difficulty": difficulty,
		"darkness": darkness, "darkness_gained": darkness_gained, "traps": tr, "outcome": outcome,
	}


static func from_dict(d: Dictionary) -> Battle:
	var b := Battle.new()
	b.title = d.title
	b.width = int(d.width)
	b.height = int(d.height)
	for o in d.obstacles:
		b.obstacles[Vector2i(int(o[0]), int(o[1]))] = true
	for ud in d.units:
		b.units.append(Combatant.from_dict(ud))
	for oid in d.order:
		b.order.append(String(oid))
	b.turn_index = int(d.turn_index)
	b.round_num = int(d.round)
	b.rng.seed = String(d.rng_seed).to_int()
	b.rng.state = String(d.rng_state).to_int()
	b.difficulty = d.difficulty
	b.darkness = int(d.darkness)
	b.darkness_gained = int(d.darkness_gained)
	for t in d.traps:
		b.traps[Vector2i(int(t[0]), int(t[1]))] = String(t[2])
	b.outcome = d.outcome
	return b


func save_to(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(to_dict()))


static func load_from(path: String) -> Battle:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return null
	return Battle.from_dict(data)
