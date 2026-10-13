class_name Battle
extends RefCounted
## Состояние и правила боя без узлов сцены: используется интерфейсом, тестами и симуляцией.
##
## Умения, состояния и пассивные приёмы — данные (data/combat/*.json). Здесь один исполнитель:
## run_effects() разбирает эффекты умения, а свойства состояний и приёмов читаются запросами
## mod_sum() / mod_any() / _signs(). Схема данных — docs/COMBAT_DATA.md.

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]
## Зоны на поле: ловушки Велиора, жир, паутина, каменные шипы.
const ZONE_KINDS: Array[String] = ["trap", "grease", "web", "spikes"]

var id := ""
var level := 2
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
var dark_gifts_used := 0
## Тёмных даров применено в этом бою, с перстнем тоже (Тьма только за первый).
var dark_gifts_cast := 0
## Боевая Тьма, набранная до этого боя (для потолка combat_dark_cap).
var combat_dark_before := 0
## Тьма от тёмных предметов за этот бой (в том же потолке).
var item_darkness := 0
## Нежить, уже сделавшая спасбросок под «Светом штейгера»: id → true.
var light_saved := {}
## Зоны: вид → {клетка: значение}. trap — {"src", "dice"}, grease и web — СЛ, spikes — кости за шаг.
var zones := {"trap": {}, "grease": {}, "web": {}, "spikes": {}}
var outcome := ""
var log_lines: Array[String] = []
## События для интерфейса: урон, лечение, промах. Интерфейс забирает их через take_events().
var events: Array[Dictionary] = []
## Правила сюжетного боя из battles.json (собирает CombatData.scenario): objective — цель, кроме «убить всех»
## ({"type": "survive", "rounds": N}); waves — подкрепления по раундам; timed — состояния до раунда;
## bound — связанный союзник, который вступает в бой в раунде round или когда к нему подойдут;
## surprise — враги застигнуты врасплох и пропускают первый ход; cannot_lose — поражения нет (соседи
## добивают врагов, бой засчитан как победа, rescued = true). Сохраняется вместе с боем.
var stage := {}


func setup(scenario: Dictionary, seed_value: int = -1, diff := "story") -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	difficulty = diff
	id = String(scenario.get("id", ""))
	stage = scenario.get("stage", {}).duplicate(true)
	combat_dark_before = int(scenario.get("combat_darkness", 0))
	level = int(scenario.get("level", 2))
	width = int(scenario.width)
	height = int(scenario.height)
	for o in scenario.obstacles:
		obstacles[o] = true
	for u in scenario.units:
		units.append(u)
	var raw_item_dark := 0
	for u in units:
		u.initiative = Dice.d20(rng) + u.init_mod
		for tid in u.traits:
			var st := String(CombatData.trait_def(tid).get("start_status", ""))
			if st != "":
				# «Тень» (тенекожа): в начале боя носитель спрятан.
				add_status(u, st, u)
		if u.team == 0:
			raw_item_dark += u.item_dark
	# Тьма тёмных предметов тоже в потолке боевой Тьмы за игру.
	item_darkness = 0
	item_darkness = clampi(raw_item_dark, 0, combat_dark_room())
	darkness += item_darkness
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
	_stage_start()
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
		if o.team != u.team and o.conscious() and not o.has_status("bound"):
			out.append(o)
	return out


func allies_of(u: Combatant) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for o in units:
		if o.team == u.team and not o.dead:
			out.append(o)
	return out


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func is_obstacle(c: Vector2i) -> bool:
	return obstacles.has(c)


## Линия обзора: прямая между центрами клеток не проходит через препятствия.
## Касание угла препятствия обзор не перекрывает; участники обзор не перекрывают.
func has_los(a: Vector2i, b: Vector2i) -> bool:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y)) * 4
	if steps <= 4:
		return true
	var from := Vector2(a)
	var to := Vector2(b)
	for i in range(1, steps):
		var p := from.lerp(to, float(i) / steps)
		var c := Vector2i(roundi(p.x), roundi(p.y))
		if c == a or c == b:
			continue
		# Точка у самой границы клетки — это касание угла, оно обзор не перекрывает.
		if is_obstacle(c) and absf(p.x - c.x) < 0.45 and absf(p.y - c.y) < 0.45:
			return false
	return true


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


func _foe_adjacent(u: Combatant) -> bool:
	for f in foes_of(u):
		if dist(f.cell, u.cell) <= 1:
			return true
	return false


# --- Состояния и приёмы: свойства из данных --------------------------------

## Свойства, действующие на участника: его приёмы (traits.json) и состояния (statuses.json).
## Приём с requires_trait действует, только если есть указанный приём.
func _sources(u: Combatant) -> Array:
	var out := []
	for tid in u.traits:
		var td := CombatData.trait_def(tid)
		if td.has("requires_trait") and not u.traits.has(String(td.requires_trait)):
			continue
		out.append(td)
		var sm: Dictionary = td.get("status_mod", {})
		for sid in sm:
			if u.statuses.has(sid):
				out.append(sm[sid])
	for sid in u.statuses:
		out.append(_status_view(u, sid))
	return out


## Свойства состояния с подставленным значением ("$value" → value, заданное наложившим).
func _status_view(u: Combatant, sid: String) -> Dictionary:
	var sd := CombatData.status_def(sid)
	if not sd.values().has("$value"):
		return sd
	var view := sd.duplicate()
	for k in view:
		if view[k] is String and view[k] == "$value":
			view[k] = u.statuses[sid].get("value", 0)
	return view


func mod_sum(u: Combatant, key: String) -> int:
	var s := 0
	for src in _sources(u):
		if src.has(key):
			s += int(src[key])
	return s


func mod_any(u: Combatant, key: String) -> bool:
	for src in _sources(u):
		if src.get(key, false):
			return true
	return false


func mod_get(u: Combatant, key: String) -> Variant:
	for src in _sources(u):
		if src.has(key):
			return src[key]
	return null


## Есть ли у источников свойство со знаком плюс и со знаком минус (преимущество и помеха не суммируются).
func _signs(u: Combatant, key: String) -> Vector2i:
	var pos := 0
	var neg := 0
	for src in _sources(u):
		var v := int(src.get(key, 0))
		if v > 0:
			pos = 1
		elif v < 0:
			neg = 1
	return Vector2i(pos, neg)


func add_status(u: Combatant, sid: String, src: Combatant, value: Variant = 0) -> void:
	u.statuses[sid] = {"src": src.id if src != null else "", "value": value, "fresh": true}
	events.append({"type": "status", "unit": u.id, "status": sid})


func remove_status(u: Combatant, sid: String) -> void:
	u.statuses.erase(sid)


## Снять состояния, которые кончаются по событию (ends в statuses.json).
func _end_statuses(u: Combatant, event: String, src_id := "") -> void:
	for sid in u.statuses.keys():
		var ends: Array = CombatData.status_def(sid).get("ends", [])
		if not ends.has(event):
			continue
		if src_id != "" and u.status_src(sid) != src_id:
			continue
		u.statuses.erase(sid)


## Счётчик «раз за бой»: можно ли ещё сработать приёму key не больше limit раз.
func _once(u: Combatant, key: String, limit := 1) -> bool:
	if int(u.counters.get(key, 0)) >= limit:
		return false
	u.counters[key] = int(u.counters.get(key, 0)) + 1
	return true


## Ауры союзников (Защитник, бирка жены): каждый вид ауры считается один раз.
func _aura_sum(t: Combatant, key: String) -> int:
	var best := {}
	for o in units:
		if o == t or o.team != t.team or not o.conscious():
			continue
		for tid in o.traits:
			var aura: Dictionary = CombatData.trait_def(tid).get("aura", {})
			if aura.is_empty() or best.has(tid) or dist(o.cell, t.cell) > int(aura.radius):
				continue
			if aura.has("requires_trait") and not o.traits.has(String(aura.requires_trait)):
				continue
			if aura.get("bearer_near_foe", false) and not _foe_adjacent(o):
				continue
			best[tid] = int(aura.mod.get(key, 0))
	var s := 0
	for tid in best:
		s += best[tid]
	return s


## КД с учётом состояний («Щит веры», «Замедление») и аур союзников.
func ac_of(t: Combatant) -> int:
	return t.ac + mod_sum(t, "ac") + _aura_sum(t, "ac")


func can_react(u: Combatant) -> bool:
	return u.conscious() and not u.reaction_used and not mod_any(u, "no_reactions") and not u.is_ranged()


func is_hidden(u: Combatant) -> bool:
	return mod_any(u, "untargetable")


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


## Расстояние пешком до клетки from от каждой клетки поля, в обход препятствий (участники не мешают).
func walk_distances(from: Vector2i) -> Dictionary:
	var dist_map := {from: 0}
	var frontier: Array[Vector2i] = [from]
	while not frontier.is_empty():
		var next: Array[Vector2i] = []
		for c in frontier:
			for d in DIRS:
				var n := c + d
				if not in_bounds(n) or is_obstacle(n) or dist_map.has(n):
					continue
				if d.x != 0 and d.y != 0 and (is_obstacle(c + Vector2i(d.x, 0)) or is_obstacle(c + Vector2i(0, d.y))):
					continue
				dist_map[n] = int(dist_map[c]) + 1
				next.append(n)
		frontier = next
	return dist_map


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
	if mod_any(u, "no_provoke"):
		return 0
	var count := 0
	var used := {}
	var from := u.cell
	for step in path:
		for e in foes_of(u):
			if used.has(e.id) or not can_react(e):
				continue
			if dist(from, e.cell) <= e.reach() and dist(step, e.cell) > e.reach():
				used[e.id] = true
				count += 1
		from = step
	return count


func move_along(u: Combatant, path: Array[Vector2i]) -> void:
	for step in path:
		if not u.conscious() or u.speed_left <= 0 or mod_any(u, "immobile"):
			break
		if not mod_any(u, "no_provoke"):
			for e in foes_of(u):
				if not can_react(e):
					continue
				if dist(u.cell, e.cell) <= e.reach() and dist(step, e.cell) > e.reach():
					e.reaction_used = true
					log_line("%s атакует при возможности." % e.name)
					var hit := _weapon_attack(e, u, {"oa": true})
					if not u.conscious():
						return
					if hit > 0 and mod_any(e, "oa_stop"):
						log_line("%s удерживает проход: %s останавливается." % [e.name, u.name])
						u.speed_left = 0
						return
		u.cell = step
		u.speed_left -= 1
		_free_bound_near(u)
		if _enter_cell(u, step):
			return


## Ловушка, шипы, жир и паутина на клетке, куда участник вошёл. Возвращает true, если он остановился.
func _enter_cell(u: Combatant, c: Vector2i) -> bool:
	if zones.trap.has(c) and u.team == 1:
		var trap: Dictionary = zones.trap[c]
		zones.trap.erase(c)
		log_line("%s попадает в ловушку!" % u.name)
		deal_damage(u, Dice.roll(rng, String(trap.get("dice", "2d6"))), "trap")
		u.speed_left = 0
		return true
	if zones.spikes.has(c) and u.conscious():
		deal_damage(u, Dice.roll(rng, String(zones.spikes[c])), "spikes")
		if not u.conscious():
			return true
	if zones.grease.has(c) and u.conscious() and _grease_check(u, int(zones.grease[c])):
		u.speed_left = 0
		return true
	if zones.web.has(c) and u.conscious() and _web_check(u, int(zones.web[c])):
		u.speed_left = 0
		return true
	return false


## Спасбросок Ловкости в жиру; при провале участник падает. Возвращает true при падении.
func _grease_check(u: Combatant, dc: int) -> bool:
	if u.has_status("prone") or not u.conscious():
		return false
	if saving_throw(u, "dex", dc):
		return false
	add_status(u, "prone", null)
	log_line("%s поскальзывается на жиру и падает." % u.name)
	return true


## Спасбросок Ловкости в паутине; при провале участник опутан. Возвращает true, если опутан.
func _web_check(u: Combatant, dc: int) -> bool:
	if u.has_status("restrained") or not u.conscious():
		return false
	if saving_throw(u, "dex", dc):
		return false
	add_status(u, "restrained", null)
	log_line("%s запутывается в паутине." % u.name)
	return true


# --- Атаки ----------------------------------------------------------------

func advantage_for(attacker: Combatant, target: Combatant, ranged: bool) -> int:
	var adv := 0
	var dis := 0
	var own := _signs(attacker, "attack")
	adv += own.x
	dis += own.y
	if not ranged:
		var melee := _signs(attacker, "melee_attack")
		adv += melee.x
		dis += melee.y
	var def := _signs(target, "defense")
	adv += def.x
	dis += def.y
	var by_range := _signs(target, "defense_ranged" if ranged else "defense_melee")
	adv += by_range.x
	dis += by_range.y
	if _assassinating(attacker, target):
		adv += 1
	if ranged and not mod_any(attacker, "no_ranged_penalty"):
		for f in foes_of(attacker):
			if dist(f.cell, attacker.cell) <= 1 and not mod_any(f, "no_threat"):
				dis += 1
				break
	if adv > 0 and dis > 0:
		return 0
	return 1 if adv > 0 else (-1 if dis > 0 else 0)


## «Убийство»: первый раунд по врагам, ещё не ходившим; с «Шёпотом Молчащих» — первые два раунда по всем.
func _assassinating(attacker: Combatant, target: Combatant) -> bool:
	var rounds := mod_sum(attacker, "assassinate")
	if rounds <= 0:
		return false
	if rounds >= 2:
		return round_num <= rounds
	return round_num == 1 and not target.acted


func can_sneak(attacker: Combatant, target: Combatant, adv: int) -> bool:
	if attacker.sneak_dice == "" or attacker.sneak_used or adv < 0:
		return false
	if adv > 0:
		return true
	for ally in units:
		if ally != attacker and ally.team == attacker.team and ally.conscious() and dist(ally.cell, target.cell) <= 1:
			return true
	return false


## Кости скрытой атаки с учётом «Добивания».
func sneak_expr(attacker: Combatant, target: Combatant) -> String:
	var expr := attacker.sneak_dice
	if mod_any(attacker, "finisher") and target.hp * 2 <= target.max_hp:
		var d := Dice.parse(expr)
		expr = "%dd%d" % [d.count * 2, d.sides]
	return expr


func enemy_damage_scale(attacker: Combatant) -> float:
	return float(CombatData.rules().story_enemy_damage) if attacker.team == 1 and difficulty == "story" else 1.0


## Плоские прибавки к урону атаки оружием: ярость, «Убийство».
func _flat_bonus(attacker: Combatant, target: Combatant, ranged: bool) -> int:
	var b := 0
	if not ranged:
		b += mod_sum(attacker, "melee_dmg")
	if _assassinating(attacker, target):
		b += attacker.level
	return b


## Кости, которые добавят к следующему попаданию оружием состояния атакующего (яд, шаг в тень).
func _pending_hit_dice(attacker: Combatant) -> Array[String]:
	var out: Array[String] = []
	for sid in attacker.statuses:
		for e in CombatData.status_def(sid).get("on_weapon_hit", []):
			if e.op == "bonus_dice":
				out.append(String(attacker.statuses[sid].get("value", "")))
	return out


## Прогноз атаки оружием для интерфейса и ИИ.
func attack_preview(attacker: Combatant, target: Combatant, extra_dice := "", weapon := {}) -> Dictionary:
	if weapon.is_empty():
		weapon = attacker.weapon
	var ranged: bool = weapon.get("kind", "melee") == "ranged"
	var adv := advantage_for(attacker, target, ranged)
	var chance := Dice.hit_chance(int(weapon.to_hit), ac_of(target), adv)
	var dmg_expr: String = weapon.damage
	var lo := float(Dice.min_of(dmg_expr))
	var hi := float(Dice.max_of(dmg_expr))
	var avg := Dice.avg_of(dmg_expr)
	var extras: Array[String] = []
	if extra_dice != "":
		extras.append(extra_dice)
	if can_sneak(attacker, target, adv):
		extras.append(sneak_expr(attacker, target))
	for e in _pending_hit_dice(attacker):
		if e != "":
			extras.append(e)
	extras.append_array(_item_dice(attacker, target))
	for e in extras:
		lo += Dice.min_of(e)
		hi += Dice.max_of(e)
		avg += Dice.avg_of(e)
	var flat := _flat_bonus(attacker, target, ranged)
	lo += flat
	hi += flat
	avg += flat
	var scale := enemy_damage_scale(attacker) * _mitigation_scale(target)
	return {"chance": chance, "adv": adv, "min": int(ceil(lo * scale)), "max": int(ceil(hi * scale)),
		"avg": avg * scale, "expected": chance * avg * scale, "sneak": can_sneak(attacker, target, adv)}


## Грубая доля урона от оружия, которая дойдёт до цели (для прогноза).
func _mitigation_scale(target: Combatant) -> float:
	var v = mod_get(target, "preview_mitigation")
	return float(v) if v != null else 1.0


func in_weapon_range(attacker: Combatant, target: Combatant) -> bool:
	if attacker.is_ranged():
		return dist(attacker.cell, target.cell) <= int(attacker.weapon.get("range", 1)) \
			and has_los(attacker.cell, target.cell)
	return dist(attacker.cell, target.cell) <= attacker.reach()


## Атакующий атаковал: с него спадает скрытность, с цели — метка «Направляющего снаряда».
func _attack_made(attacker: Combatant, target: Combatant) -> void:
	_end_statuses(attacker, "attack")
	if target != null:
		_end_statuses(target, "attacked")


func _roll_attack(adv: int) -> int:
	var r1 := Dice.d20(rng)
	var r2 := Dice.d20(rng)
	if adv > 0:
		return maxi(r1, r2)
	if adv < 0:
		return mini(r1, r2)
	return r1


## Атака оружием. opts: weapon, extra_dice, drain_extra, oa. Возвращает нанесённый урон (0 при промахе).
func _weapon_attack(attacker: Combatant, target: Combatant, opts: Dictionary) -> int:
	var weapon: Dictionary = opts.get("weapon", attacker.weapon)
	var ranged: bool = weapon.get("kind", "melee") == "ranged"
	var adv := advantage_for(attacker, target, ranged)
	if opts.get("oa", false) and mod_any(attacker, "oa_adv"):
		# Клинок гвардии: атака при возможности с преимуществом.
		adv = mini(adv + 1, 1)
	var roll := _roll_attack(adv)
	_attack_made(attacker, target)
	var total := roll + int(weapon.to_hit)
	var crit_on := mod_sum(attacker, "crit_on")
	var crit := roll == 20 or (crit_on > 0 and roll >= crit_on)
	var tac := ac_of(target)
	if roll == 1 or (not crit and total < tac):
		log_line("%s → %s: промах (%d против КД %d)." % [attacker.name, target.name, total, tac])
		events.append({"type": "miss", "unit": target.id})
		return 0
	var dmg := Dice.roll(rng, weapon.damage, crit)
	if can_sneak(attacker, target, adv):
		attacker.sneak_used = true
		dmg += Dice.roll(rng, sneak_expr(attacker, target), crit)
		_after_sneak(attacker)
	var extra := 0
	if opts.has("extra_dice"):
		extra = Dice.roll(rng, opts.extra_dice, crit)
		dmg += extra
	# Состояния атакующего, которые тратятся на попадание: «Шаг в тень», «Яд на клинке».
	var drain_hooks := 0
	var after: Array = []
	for sid in attacker.statuses.keys():
		var hooks: Array = CombatData.status_def(sid).get("on_weapon_hit", [])
		if hooks.is_empty():
			continue
		var value = attacker.statuses[sid].get("value", "")
		for e in hooks:
			if e.op == "bonus_dice":
				var bonus := Dice.roll(rng, String(value), crit)
				dmg += bonus
				if e.get("drain", false):
					drain_hooks += bonus
			else:
				after.append(e)
		_end_statuses(attacker, "weapon_hit")
	var drained := 0
	if target.undead and attacker.undead_dice != "":
		dmg += Dice.roll(rng, attacker.undead_dice, crit)
	if attacker.drain_dice != "":
		drained = Dice.roll(rng, attacker.drain_dice, crit)
		dmg += drained
	if attacker.fire_dice != "":
		dmg += Dice.roll(rng, attacker.fire_dice, crit)
	dmg += _flat_bonus(attacker, target, ranged)
	dmg = int(ceil(dmg * enemy_damage_scale(attacker)))
	dmg = _mitigate(target, dmg)
	log_line("%s → %s: %s%d урона." % [attacker.name, target.name, "крит! " if crit else "", dmg])
	if not after.is_empty():
		run_effects(after, {"user": attacker, "target": target, "params": {}})
	deal_damage(target, dmg, "weapon")
	if opts.get("drain_extra", false) and extra > 0:
		heal(attacker, extra / 2)
	if drain_hooks > 0:
		heal(attacker, drain_hooks / 2)
	if drained > 0:
		heal(attacker, drained / 2)
	var on_hit: Array = weapon.get("on_hit", [])
	if not on_hit.is_empty() and target.conscious():
		run_effects(on_hit, {"user": attacker, "target": target, "params": {}})
	if not ranged and mod_any(attacker, "cleave") and not attacker.cleave_used:
		_cleave(attacker, target)
	return dmg


## «Шёпот» и подобные: раз за бой после скрытой атаки.
func _after_sneak(attacker: Combatant) -> void:
	for tid in attacker.traits:
		var hook: Dictionary = CombatData.trait_def(tid).get("after_sneak", {})
		if hook.is_empty() or not _once(attacker, "after_sneak:" + tid, int(hook.get("per_battle", 1))):
			continue
		run_effects(hook.effects, {"user": attacker, "params": {}})


## Кости предметов при попадании оружием: по нежити, некротикой, огнём.
func _item_dice(attacker: Combatant, target: Combatant) -> Array[String]:
	var out: Array[String] = []
	if target.undead and attacker.undead_dice != "":
		out.append(attacker.undead_dice)
	if attacker.drain_dice != "":
		out.append(attacker.drain_dice)
	if attacker.fire_dice != "":
		out.append(attacker.fire_dice)
	return out


## Доспехи, ярость, «Стойкость» и «Уворот» уменьшают урон от оружия.
func _mitigate(target: Combatant, dmg: int) -> int:
	dmg = maxi(dmg - target.dr - mod_sum(target, "weapon_dr"), 0)
	var uncanny := mod_sum(target, "uncanny")
	if uncanny > 0 and dmg > 0 and int(target.counters.get("uncanny_turn", 0)) < uncanny:
		target.counters["uncanny_turn"] = int(target.counters.get("uncanny_turn", 0)) + 1
		dmg /= 2
		log_line("%s уворачивается: урон вдвое меньше." % target.name)
	return dmg


## «Рассечение»: второй удар по врагу рядом с первой целью и в досягаемости.
func _cleave(attacker: Combatant, first: Combatant) -> void:
	for f in foes_of(attacker):
		if f == first or dist(f.cell, first.cell) > 1 or dist(f.cell, attacker.cell) > attacker.reach():
			continue
		attacker.cleave_used = true
		log_line("%s: рассечение." % attacker.name)
		_weapon_attack(attacker, f, {"weapon": {"to_hit": attacker.weapon.to_hit,
			"damage": attacker.weapon.damage, "kind": "melee"}})
		return


func deal_damage(target: Combatant, amount: int, _kind: String) -> void:
	if amount <= 0 or target.dead:
		return
	target.hp = maxi(target.hp - amount, 0)
	if target.has_status("turned"):
		log_line("%s больше не бежит." % target.name)
	_end_statuses(target, "damaged")
	var relentless = mod_get(target, "relentless")
	if target.hp == 0 and relentless != null and target.has_status(String(relentless)) and _once(target, "relentless"):
		target.hp = 1
		log_line("%s в ярости не падает!" % target.name)
	events.append({"type": "damage", "unit": target.id, "amount": amount})
	if target.hp > 0 and target.hp * 2 <= target.max_hp and mod_any(target, "rally") and _once(target, "rally"):
		log_line("%s: клятва Молчащих держит на ногах." % target.name)
		heal(target, 2 * target.level)
	if target.hp == 0:
		if target.team == 0:
			if not target.down:
				target.down = true
				# Выбывший теряет ярость, паралич и скрытность и лежит: поднятый встанет и походит как обычно.
				_end_statuses(target, "down")
				add_status(target, "prone", null)
				log_line("%s выбывает из боя." % target.name)
				_rescue(target)
		else:
			target.dead = true
			log_line("%s повержен." % target.name)
	_check_outcome()


## «Цепь Безымянных»: союзник рядом с носителем, выбыв, сразу встаёт.
func _rescue(fallen: Combatant) -> void:
	for o in allies_of(fallen):
		if o.conscious() and dist(o.cell, fallen.cell) <= 1 and mod_any(o, "rescue") and _once(o, "rescue"):
			log_line("%s: цепь Безымянных поднимает %s." % [o.name, fallen.name])
			heal(fallen, 2 * o.level)
			return


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
	var roll := Dice.d20(rng)
	if target.undead and not light_saved.has(target.id):
		# «Свет штейгера»: первый спасбросок нежити рядом с носителем фонаря — с помехой.
		for h in foes_of(target):
			var light = mod_get(h, "undead_save_disadv")
			if light != null and dist(h.cell, target.cell) <= int(light.radius):
				light_saved[target.id] = true
				roll = mini(roll, Dice.d20(rng))
				break
	if roll + target.save_bonus(stat) >= dc:
		return true
	# «Молчание» (венец): раз за бой носитель или союзник рядом перебрасывает проваленный спасбросок.
	for h in units:
		if h.team != target.team or not h.conscious():
			continue
		var reroll = mod_get(h, "save_reroll")
		if reroll != null and dist(h.cell, target.cell) <= int(reroll.radius) \
				and _once(h, "save_reroll", int(reroll.get("per_battle", 1))):
			log_line("%s: Молчание, переброс спасброска." % h.name)
			return Dice.d20(rng) + target.save_bonus(stat) >= dc
	return false


func _spell_attack(u: Combatant, t: Combatant, expr: String) -> int:
	var adv := advantage_for(u, t, true)
	var roll := _roll_attack(adv)
	_attack_made(u, t)
	if roll == 1 or (roll != 20 and roll + u.spell_attack < ac_of(t)):
		log_line("Промах по %s." % t.name)
		events.append({"type": "miss", "unit": t.id})
		return 0
	var dmg := Dice.roll(rng, expr, roll == 20)
	deal_damage(t, dmg, "spell")
	return dmg


func _save_damage(u: Combatant, t: Combatant, stat: String, expr: String, half_on_save: bool) -> int:
	var dmg := Dice.roll(rng, expr)
	if saving_throw(t, stat, u.spell_dc):
		dmg = dmg / 2 if half_on_save else 0
		log_line("%s спасается%s." % [t.name, " частично" if half_on_save else ""])
	deal_damage(t, dmg, "spell")
	return dmg


# --- Действия хода -------------------------------------------------------

## Начать или продолжить действие «Атака»: с дополнительной атакой в нём два удара.
func _spend_attack(u: Combatant) -> void:
	if u.attacks_left == 0:
		var cap := mod_sum(u, "max_attacks")
		u.attacks_left = mini(u.attacks_per_action, cap) if cap > 0 else u.attacks_per_action
	u.attacks_left -= 1
	if u.attacks_left == 0:
		u.action_used = true


func can_attack(u: Combatant, target: Combatant) -> bool:
	return u.conscious() and not u.action_used and not mod_any(u, "no_actions") and not mod_any(u, "no_harm") \
		and target.conscious() and target.team != u.team and in_weapon_range(u, target)


func attack(u: Combatant, target: Combatant) -> void:
	if not can_attack(u, target):
		return
	_spend_attack(u)
	_weapon_attack(u, target, {})


func ability(aid: String) -> Dictionary:
	return CombatData.ability(aid)


func params_of(u: Combatant, aid: String) -> Dictionary:
	return CombatData.params_for(u, aid)


func slot_cost(aid: String) -> int:
	return int(ability(aid).get("slot_cost", 1))


func dark_gifts_left() -> int:
	return int(CombatData.rules().dark_gifts_per_battle) - dark_gifts_used


func can_use(u: Combatant, aid: String) -> bool:
	if not u.conscious() or mod_any(u, "no_actions") or not u.abilities.has(aid):
		return false
	var a := ability(aid)
	# «Не поднимает руку» (Ирена в храме): только защита и лечение.
	if mod_any(u, "no_harm") and (a.get("attack", false) or ["enemy", "cell", "empty_cell"].has(String(a.target))):
		return false
	match String(a.cost):
		"action":
			if u.action_used:
				return false
			# Начатое действие «Атака» можно продолжить только ударом.
			if u.attacks_left > 0 and not a.get("attack", false):
				return false
		"bonus":
			if u.bonus_used:
				return false
	match String(a.get("resource", "none")):
		"slot":
			if u.slots < slot_cost(aid):
				return false
		"use":
			if u.uses_left(aid) <= 0:
				return false
	if a.has("dark"):
		if dark_gifts_left() <= 0 and not mod_any(u, "no_gift_limit"):
			return false
		if String(a.dark) == "slot" and u.slots < 1:
			return false
	for req in a.get("requires", []):
		if not _requirement(u, String(req)):
			return false
	return true


## Условия из requires: "action_used", "action_free", "no_adjacent_foe", "not_status:X", "status_or_slot:X".
func _requirement(u: Combatant, req: String) -> bool:
	var parts := req.split(":")
	match parts[0]:
		"action_used":
			return u.action_used
		"action_free":
			return not u.action_used
		"no_adjacent_foe":
			return not _foe_adjacent(u)
		"not_status":
			return not u.has_status(parts[1])
		"status_or_slot":
			return u.has_status(parts[1]) or u.slots >= 1
	push_warning("Неизвестное условие умения: " + req)
	return false


## Видит ли участника хоть один враг (в сознании, не бегущий и по линии обзора).
func seen_by_foes(u: Combatant) -> bool:
	for f in foes_of(u):
		if mod_any(f, "flee"):
			continue
		if has_los(f.cell, u.cell):
			return true
	return false


## Допустимые цели способности: список клеток.
func ability_targets(u: Combatant, aid: String) -> Array[Vector2i]:
	var a := ability(aid)
	var out: Array[Vector2i] = []
	var rng_cells := int(a.get("range", 0))
	var filt: Dictionary = a.get("target_filter", {})
	match String(a.target):
		"self":
			out.append(u.cell)
		"enemy":
			for f in foes_of(u):
				if dist(u.cell, f.cell) <= rng_cells and has_los(u.cell, f.cell):
					out.append(f.cell)
		"ally":
			for o in units:
				if o.team == u.team and not o.dead and dist(u.cell, o.cell) <= rng_cells and has_los(u.cell, o.cell):
					if filt.has("not_status") and o.has_status(String(filt.not_status)):
						continue
					if filt.get("not_down", false) and o.down:
						continue
					out.append(o.cell)
		"cell", "empty_cell":
			var empty: bool = a.target == "empty_cell"
			for x in width:
				for y in height:
					var c := Vector2i(x, y)
					if is_obstacle(c) or dist(u.cell, c) > rng_cells:
						continue
					if empty and (occupant(c) != null or zones.trap.has(c)):
						continue
					if has_los(u.cell, c):
						out.append(c)
	return out


## Клетки, которые заденет способность при выборе цели.
func ability_area(u: Combatant, aid: String, target: Vector2i) -> Array[Vector2i]:
	var a := ability(aid)
	var p := params_of(u, aid)
	for e in a.effects:
		if e.get("to", "") == "nearest_foes":
			var cells: Array[Vector2i] = []
			for f in _nearest_foes(u, int(p.get("radius", 0)), int(CombatData.resolve(e.get("count", 1), p))):
				cells.append(f.cell)
			return cells
	if p.has("radius"):
		return cells_in_radius(u.cell if a.target == "self" else target, int(p.radius))
	var single: Array[Vector2i] = [target]
	return single


## Радиус умения с учётом предметов (колокол Ирены, молот-кадило Света, Шёпот Ловкача).
func radius_of(u: Combatant, aid: String) -> int:
	return int(params_of(u, aid).get("radius", 0))


## До count ближайших видимых врагов в радиусе («Веер кинжалов»).
func _nearest_foes(u: Combatant, radius: int, count: int) -> Array[Combatant]:
	var list: Array[Combatant] = []
	for f in foes_of(u):
		if dist(u.cell, f.cell) <= radius and has_los(u.cell, f.cell):
			list.append(f)
	list.sort_custom(func(a: Combatant, b: Combatant) -> bool: return dist(u.cell, a.cell) < dist(u.cell, b.cell))
	return list.slice(0, count)


## Урон или лечение способности (кости) для этого участника.
func dice_of(u: Combatant, aid: String) -> String:
	return String(params_of(u, aid).get("dice", ""))


func use_ability(u: Combatant, aid: String, target: Vector2i) -> bool:
	if not can_use(u, aid):
		return false
	if not ability_targets(u, aid).has(target):
		return false
	var a := ability(aid)
	if a.has("dark"):
		_pay_dark(u, String(a.dark))
	if a.get("attack", false):
		_spend_attack(u)
	elif a.cost == "action":
		u.action_used = true
	elif a.cost == "bonus":
		u.bonus_used = true
	match String(a.get("resource", "none")):
		"slot":
			u.slots -= slot_cost(aid)
		"use":
			u.uses[aid] = u.uses_left(aid) - 1
	log_line("%s: %s." % [u.name, TranslationServer.translate("ABILITY_" + aid)])
	run_effects(a.effects, {"user": u, "aid": aid, "cell": target, "target": occupant(target),
		"params": params_of(u, aid)})
	if a.has("dark"):
		_add_darkness(u)
	return true


# --- Исполнитель эффектов -------------------------------------------------

## Выполнить список эффектов. ctx: user — кто применяет; target — участник на выбранной клетке;
## cell — выбранная клетка; aid — умение; params — параметры умения (для "$имя"); dealt — урон,
## нанесённый предыдущими эффектами (для «половины нанесённого»).
func run_effects(effects: Array, ctx: Dictionary) -> void:
	if not ctx.has("dealt"):
		ctx["dealt"] = 0
	for e in effects:
		_apply(e, ctx)


func _apply(e: Dictionary, ctx: Dictionary) -> void:
	var u: Combatant = ctx.user
	var p: Dictionary = ctx.get("params", {})
	match String(e.op):
		"heal":
			for t in _select(e, ctx):
				var amount := 0
				if e.get("amount", "") == "half_dealt":
					amount = int(ctx.dealt) / 2
				else:
					amount = Dice.roll(rng, _dice(e, p))
					if e.get("add", "") == "level":
						amount += u.level
					if e.get("spell_heal", false):
						amount += mod_sum(u, "spell_heal")
					if e.get("item_heal", false):
						amount += u.heal_bonus
				heal(t, amount)
		"damage":
			for t in _select(e, ctx):
				var amount := int(ctx.dealt) / 2 if e.get("amount", "") == "half_dealt" else Dice.roll(rng, _dice(e, p))
				deal_damage(t, amount, String(e.get("type", "spell")))
		"spell_attack":
			_op_spell_attack(e, ctx)
		"weapon_attack":
			for t in _select(e, ctx):
				var opts := {}
				var w = e.get("weapon", "main")
				if w is Dictionary:
					opts["weapon"] = {"to_hit": u.weapon.to_hit, "kind": w.get("kind", "melee"),
						"damage": String(CombatData.resolve(w.damage, p))}
				elif w == "ranged":
					opts["weapon"] = u.ranged_weapon
				if e.has("extra_dice"):
					opts["extra_dice"] = String(CombatData.resolve(e.extra_dice, p))
				if e.get("drain_extra", false):
					opts["drain_extra"] = true
				var dmg := _weapon_attack(u, t, opts)
				ctx.dealt = int(ctx.dealt) + dmg
				if dmg > 0 and t.conscious() and e.has("on_hit"):
					run_effects(e.on_hit, _sub(ctx, t))
		"save_damage":
			for t in _select(e, ctx):
				var expr := Dice.add(_dice(e, p), String(CombatData.resolve(e.get("add_dice", ""), p)))
				ctx.dealt = int(ctx.dealt) + _save_damage(u, t, String(e.stat), expr, e.get("half", false))
		"save":
			for t in _select(e, ctx):
				if e.get("not_undead", false) and t.undead:
					continue
				var dc := _dc(e, u)
				if saving_throw(t, String(e.stat), dc):
					log_line("%s устоял." % t.name)
					if e.has("on_success"):
						run_effects(e.on_success, _sub(ctx, t, dc))
				elif e.has("on_fail"):
					run_effects(e.on_fail, _sub(ctx, t, dc))
		"status":
			for t in _select(e, ctx):
				if e.get("pay_slot", false) and not t.has_status(String(e.status)):
					# «Духовное оружие»: первый призыв стоит ячейку, дальше удары бонусом бесплатны.
					u.slots -= 1
				var value = e.get("value", 0)
				if value is String and value == "dc":
					value = int(ctx.get("dc", u.spell_dc))
				else:
					value = CombatData.resolve(value, p)
				add_status(t, String(e.status), u, value)
				log_line("%s: %s." % [t.name, TranslationServer.translate("STATUS_" + String(e.status))])
		"zone":
			_op_zone(e, ctx)
		"shove":
			for t in _select(e, ctx):
				_shove(u, t)
		"refresh_action":
			u.action_used = false
			u.attacks_left = 0
		"add_speed":
			u.speed_left += int(e.get("amount", u.speed))
		"hide":
			if not seen_by_foes(u) or Dice.d20(rng) + u.save_bonus("dex") >= int(e.get("dc", 15)):
				add_status(u, "hidden", u)
				log_line("%s прячется." % u.name)
			else:
				log_line("%s не удаётся спрятаться." % u.name)
		"heal_pool":
			_op_heal_pool(e, ctx)
		_:
			push_error("Неизвестная операция эффекта: %s" % e.op)


func _sub(ctx: Dictionary, t: Combatant, dc := -1) -> Dictionary:
	var out := ctx.duplicate()
	out["target"] = t
	if dc >= 0:
		out["dc"] = dc
	return out


func _dice(e: Dictionary, p: Dictionary) -> String:
	return String(CombatData.resolve(e.get("dice", "$dice"), p))


func _dc(e: Dictionary, u: Combatant) -> int:
	var dc = e.get("dc", "spell")
	return u.spell_dc if dc is String else int(dc)


## Кого задевает эффект: to — self, target, area, most_wounded_ally, nearest_foes, adjacent_foe;
## для области who — all, foes, allies, others (все, кроме применившего) и фильтры undead, wounded, not_status.
func _select(e: Dictionary, ctx: Dictionary) -> Array[Combatant]:
	var u: Combatant = ctx.user
	var out: Array[Combatant] = []
	match String(e.get("to", "target")):
		"self":
			out.append(u)
		"target":
			if ctx.get("target") != null:
				out.append(ctx.target)
		"area":
			var no_ff: bool = bool(e.get("friendly_fire", false)) and mod_any(u, "no_friendly_fire")
			for c in ability_area(u, String(ctx.aid), ctx.cell):
				var o := occupant(c)
				if o == null or o.dead:
					continue
				var foe := o.team != u.team
				match String(e.get("who", "all")):
					"foes":
						if not foe or not o.conscious():
							continue
					"allies":
						if foe:
							continue
					"others":
						if o == u:
							continue
				if not foe and no_ff:
					continue
				if e.get("undead", false) and not o.undead:
					continue
				if e.get("wounded", false) and o.hp >= o.max_hp:
					continue
				if e.has("not_status") and o.has_status(String(e.not_status)):
					continue
				out.append(o)
		"most_wounded_ally":
			var best: Combatant = null
			for o in units:
				if o.team != u.team or o.dead or o.hp >= o.max_hp:
					continue
				if e.get("conscious", false) and not o.conscious():
					continue
				if e.has("radius") and dist(o.cell, u.cell) > int(e.radius):
					continue
				if best == null or float(o.hp) / o.max_hp < float(best.hp) / best.max_hp:
					best = o
			if best != null:
				out.append(best)
		"nearest_foes":
			var p: Dictionary = ctx.get("params", {})
			out = _nearest_foes(u, int(p.get("radius", 0)), int(CombatData.resolve(e.get("count", 1), p)))
		"adjacent_foe":
			var t: Combatant = ctx.get("target")
			if t != null:
				for f in foes_of(u):
					if f != t and dist(f.cell, t.cell) <= 1:
						out.append(f)
						break
	return out


func _op_spell_attack(e: Dictionary, ctx: Dictionary) -> void:
	var u: Combatant = ctx.user
	var p: Dictionary = ctx.get("params", {})
	var expr := _dice(e, p)
	var times := int(CombatData.resolve(e.get("repeat", 1), p))
	var aim: Combatant = ctx.get("target")
	var reach := int(ability(String(ctx.aid)).get("range", 0)) if ctx.has("aid") else 0
	for i in times:
		if e.get("retarget", false) and (aim == null or not aim.conscious()):
			aim = _nearest_foe_in_range(u, reach)
		if aim == null:
			break
		var dmg := _spell_attack(u, aim, expr)
		ctx.dealt = int(ctx.dealt) + dmg
		if dmg <= 0:
			continue
		if e.get("drain", false):
			heal(u, dmg / 2)
		if e.has("on_hit") and aim.conscious():
			run_effects(e.on_hit, _sub(ctx, aim))
		# Именные правила предметов при попадании умением (посох Молчащих Воплотителя).
		for tid in u.traits:
			var extra: Dictionary = CombatData.trait_def(tid).get("extra_on_hit", {})
			if extra.has(ctx.get("aid", "")):
				var sub := _sub(ctx, aim)
				sub["dealt"] = dmg
				run_effects(extra[ctx.aid], sub)


func _op_zone(e: Dictionary, ctx: Dictionary) -> void:
	var u: Combatant = ctx.user
	var p: Dictionary = ctx.get("params", {})
	var kind := String(e.kind)
	if kind == "trap":
		zones.trap[ctx.cell] = {"src": u.id, "dice": _dice(e, p)}
		return
	var area := ability_area(u, String(ctx.aid), ctx.cell)
	for c in area:
		zones[kind][c] = _dice(e, p) if kind == "spikes" else u.spell_dc
	for c in area:
		var o := occupant(c)
		if o == null or not o.conscious():
			continue
		if kind == "grease":
			_grease_check(o, u.spell_dc)
		elif kind == "web":
			_web_check(o, u.spell_dc)


## «Сохранение жизни»: per_level × уровень хитов раненым союзникам в радиусе, каждому не выше половины хитов.
func _op_heal_pool(e: Dictionary, ctx: Dictionary) -> void:
	var u: Combatant = ctx.user
	var p: Dictionary = ctx.get("params", {})
	var pool := int(CombatData.resolve(e.get("per_level", 8), p)) * u.level
	var radius := int(p.get("radius", 6))
	var wounded := allies_of(u).filter(func(o: Combatant) -> bool:
		return dist(o.cell, u.cell) <= radius and o.hp * 2 < o.max_hp)
	wounded.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.hp < b.hp)
	for o in wounded:
		if pool <= 0:
			break
		var amount := mini(pool, o.max_hp / 2 - o.hp)
		if amount > 0:
			heal(o, amount)
			pool -= amount


func _nearest_foe_in_range(u: Combatant, r: int) -> Combatant:
	var best: Combatant = null
	for f in foes_of(u):
		if dist(u.cell, f.cell) <= r and has_los(u.cell, f.cell):
			if best == null or dist(u.cell, f.cell) < dist(u.cell, best.cell):
				best = f
	return best


## Клетка, куда отлетит цель толчка, или (-1, -1), если некуда.
func shove_dest(u: Combatant, t: Combatant) -> Vector2i:
	var d := Vector2i(signi(t.cell.x - u.cell.x), signi(t.cell.y - u.cell.y))
	var dest := t.cell + d
	if not in_bounds(dest) or is_obstacle(dest) or occupant(dest) != null:
		return Vector2i(-1, -1)
	if d.x != 0 and d.y != 0 and (is_obstacle(t.cell + Vector2i(d.x, 0)) or is_obstacle(t.cell + Vector2i(0, d.y))):
		return Vector2i(-1, -1)
	return dest


func _shove(u: Combatant, t: Combatant) -> void:
	_end_statuses(u, "attack")
	var bonus := maxi(t.save_bonus("str"), t.save_bonus("dex"))
	if Dice.d20(rng) + bonus >= u.shove_dc():
		log_line("%s устоял на месте." % t.name)
		return
	var dest := shove_dest(u, t)
	if dest.x < 0:
		add_status(t, "prone", u)
		log_line("%s падает." % t.name)
		return
	t.cell = dest
	log_line("%s отлетает назад." % t.name)
	_enter_cell(t, dest)


# --- Прогноз умения для интерфейса и ИИ -----------------------------------

## Прогноз умения по выбранной клетке: {"kind", "chance", "min", "max", "hits": [id задетых]}.
## kind — "weapon", "spell_attack", "save", "damage", "heal" или "other" по первому эффекту.
func ability_preview(u: Combatant, aid: String, cell: Vector2i) -> Dictionary:
	var a := ability(aid)
	var p := params_of(u, aid)
	var t := occupant(cell)
	var hits := []
	for c in ability_area(u, aid, cell):
		var o := occupant(c)
		if o != null:
			hits.append(o.id)
	var out := {"kind": "other", "hits": hits}
	if a.effects.is_empty():
		return out
	var e: Dictionary = a.effects[0]
	var expr := _dice(e, p) if e.has("dice") or p.get("dice", "") != "" else ""
	match String(e.op):
		"weapon_attack":
			if t != null and e.get("to", "target") == "target":
				var w = e.get("weapon", "main")
				var weapon: Dictionary = u.ranged_weapon if w is String and w == "ranged" else {}
				var extra := String(CombatData.resolve(e.get("extra_dice", ""), p))
				out.merge(attack_preview(u, t, extra, weapon), true)
				out["kind"] = "weapon"
		"spell_attack":
			if t != null:
				out["kind"] = "spell_attack"
				out["chance"] = Dice.hit_chance(u.spell_attack, ac_of(t), advantage_for(u, t, true))
				out["min"] = Dice.min_of(expr)
				out["max"] = Dice.max_of(expr)
				out["times"] = int(CombatData.resolve(e.get("repeat", 1), p))
		"save_damage", "save":
			if t != null:
				out["kind"] = "save"
				out["chance"] = 1.0 - Dice.hit_chance(t.save_bonus(String(e.stat)), _dc(e, u), 0, false)
				if expr != "":
					out["min"] = Dice.min_of(expr)
					out["max"] = Dice.max_of(expr)
		"damage":
			out["kind"] = "damage"
			out["chance"] = 1.0
			out["min"] = Dice.min_of(expr)
			out["max"] = Dice.max_of(expr)
		"heal":
			if expr != "":
				out["kind"] = "heal"
				out["min"] = Dice.min_of(expr)
				out["max"] = Dice.max_of(expr)
		"shove":
			if t != null:
				out["kind"] = "save"
				out["chance"] = 1.0 - Dice.hit_chance(maxi(t.save_bonus("str"), t.save_bonus("dex")), u.shove_dc(), 0, false)
				out["falls"] = shove_dest(u, t).x < 0
		"hide":
			out["chance"] = 1.0 if not seen_by_foes(u) else Dice.hit_chance(u.save_bonus("dex"), int(e.get("dc", 15)), 0, false)
	return out


# --- Тьма -----------------------------------------------------------------

## Сколько ещё боевой Тьмы влезает в потолок за игру.
func combat_dark_room() -> int:
	return maxi(int(CombatData.rules().combat_dark_cap) - combat_dark_before - darkness_gained - item_darkness, 0)


func _add_darkness(u: Combatant) -> void:
	if not mod_any(u, "no_gift_limit"):
		dark_gifts_used += 1
	dark_gifts_cast += 1
	if dark_gifts_cast > 1:
		return
	var gain := mini(int(CombatData.rules().dark_first_gift), combat_dark_room())
	if gain > 0:
		darkness += gain
		darkness_gained += gain


## Цена тёмного дара в бою воину и плуту: хиты, равные двум уровням (не ниже 1 хита).
func dark_hp_cost(u: Combatant) -> int:
	return mini(2 * u.level, maxi(u.hp - 1, 0))


func _pay_dark(u: Combatant, cost: String) -> void:
	if cost == "slot":
		u.slots -= 1
		return
	var loss := dark_hp_cost(u)
	if loss > 0:
		u.hp -= loss
		events.append({"type": "damage", "unit": u.id, "amount": loss})
		log_line("%s платит за дар: −%d хитов." % [u.name, loss])


## Стадия Тьмы по шкале DESIGN.md: shadow (Тень), dusk (Сумрак), gloom (Мрак), abyss (Бездна).
static func darkness_stage(value: int) -> String:
	for pair in CombatData.rules().darkness_stages:
		if value >= int(pair[0]):
			return String(pair[1])
	return "shadow"


# --- Ходы ----------------------------------------------------------------

func _start_turn() -> void:
	var u := current()
	u.speed_left = u.speed
	u.action_used = false
	u.attacks_left = 0
	u.bonus_used = false
	u.sneak_used = false
	u.reaction_used = false
	u.cleave_used = false
	u.counters.erase("uncanny_turn")
	_end_statuses(u, "own_turn_start")
	if u.statuses.has("hidden"):
		# Скрытность держится до конца следующего своего хода.
		u.statuses.hidden["fresh"] = false
	for o in units:
		_end_statuses(o, "src_turn_start", u.id)
	_aura_damage(u)
	if not u.conscious():
		return
	for tid in u.traits:
		var hook: Array = CombatData.trait_def(tid).get("turn_start", [])
		if not hook.is_empty():
			run_effects(hook, {"user": u, "params": {}})
	if mod_any(u, "skip_turn"):
		var why := PackedStringArray()
		for sid in u.statuses.keys():
			if CombatData.status_def(sid).get("skip_turn", false):
				why.append(TranslationServer.translate("STATUS_" + sid))
				u.statuses.erase(sid)
		u.speed_left = 0
		u.action_used = true
		u.bonus_used = true
		log_line("%s пропускает ход (%s)." % [u.name, ", ".join(why)])
		return
	for sid in u.statuses.keys():
		if CombatData.status_def(sid).get("turn_start", "") == "stand_up":
			u.statuses.erase(sid)
			u.speed_left = u.speed / 2
	var mult = mod_get(u, "speed_mult")
	if mult != null:
		u.speed_left = int(u.speed_left * float(mult))
	if zones.web.has(u.cell):
		var dc := int(zones.web[u.cell])
		if u.has_status("restrained"):
			if saving_throw(u, "str", dc):
				remove_status(u, "restrained")
				log_line("%s вырывается из паутины." % u.name)
		else:
			_web_check(u, dc)
	elif u.has_status("restrained"):
		remove_status(u, "restrained")
	if mod_any(u, "immobile"):
		u.speed_left = 0


## Ауры врагов в начале хода («Духовные стражи»): враг, начинающий ход рядом, получает урон.
func _aura_damage(u: Combatant) -> void:
	for h in units:
		if h.team == u.team or not h.conscious() or not u.conscious():
			continue
		for sid in h.statuses:
			var aid := String(CombatData.status_def(sid).get("aura_ability", ""))
			if aid == "":
				continue
			var p := params_of(h, aid)
			if dist(h.cell, u.cell) <= int(p.get("radius", 0)):
				log_line("%s: аура жжёт %s." % [h.name, u.name])
				run_effects(ability(aid).aura_effects, {"user": h, "target": u, "aid": aid, "params": p})


func end_turn() -> void:
	if outcome != "":
		return
	var u := current()
	u.acted = true
	_end_statuses(u, "own_turn_end")
	# Скрытность держится до конца следующего своего хода и пропадает, если стоишь вплотную к врагу.
	if u.statuses.has("hidden") and (not u.statuses.hidden.get("fresh", false) or _foe_adjacent(u)):
		remove_status(u, "hidden")
		log_line("%s больше не скрыт." % u.name)
	elif u.statuses.has("hidden"):
		u.statuses.hidden["fresh"] = false
	if zones.grease.has(u.cell) and u.conscious():
		_grease_check(u, int(zones.grease[u.cell]))
	for sid in u.statuses.keys():
		var stat := String(CombatData.status_def(sid).get("turn_end_save", ""))
		if stat != "" and u.conscious() and saving_throw(u, stat, int(u.statuses[sid].get("value", 13))):
			u.statuses.erase(sid)
			log_line("%s стряхивает %s." % [u.name, TranslationServer.translate("STATUS_" + sid)])
	for i in order.size():
		turn_index += 1
		if turn_index >= order.size():
			turn_index = 0
			round_num += 1
			log_line("Раунд %d." % round_num)
			_new_round()
			if outcome != "":
				return
		if can_act(current()):
			break
	_start_turn()
	# Если аура добила начинающего ход врага, ход переходит дальше.
	if outcome == "" and not current().conscious():
		end_turn()


## Может ли участник ходить: в сознании и не связан.
func can_act(u: Combatant) -> bool:
	return u.conscious() and not u.has_status("bound")


func _check_outcome() -> void:
	if outcome != "":
		return
	if heroes().all(func(h: Combatant) -> bool: return not can_act(h)):
		if stage.get("cannot_lose", false):
			# Облава: если герой выбыл, соседи с вилами добивают мертвецов (prologue-plan.md, сцена 2).
			for e in enemies():
				e.dead = true
			stage["rescued"] = true
			outcome = "victory"
			log_line(TranslationServer.translate("BATTLE_LOG_RESCUED"))
			return
		outcome = "defeat"
		log_line("Все герои выбыли. Поражение.")
	elif enemies().all(func(e: Combatant) -> bool: return e.dead) and _waves_left() == 0:
		outcome = "victory"
		log_line("Победа!")


# --- Сюжетный бой: цель, подкрепления, связанные союзники ---------------------

func _stage_start() -> void:
	for t in stage.get("timed", []):
		var u := get_unit(String(t.unit))
		if u != null:
			add_status(u, String(t.status), null)
	for bnd in stage.get("bound", []):
		var u := get_unit(String(bnd.unit))
		if u != null:
			add_status(u, "bound", null)
	if stage.get("surprise", false):
		for e in enemies():
			add_status(e, "surprised", null)
		log_line(TranslationServer.translate("BATTLE_LOG_AMBUSH"))
	for i in order.size():
		if can_act(current()):
			break
		turn_index = (turn_index + 1) % order.size()


## Начало раунда: снять временные состояния, развязать союзника, вывести подкрепления, проверить цель.
func _new_round() -> void:
	for t in stage.get("timed", []):
		var u := get_unit(String(t.unit))
		if u != null and round_num >= int(t.until_round) and u.has_status(String(t.status)):
			remove_status(u, String(t.status))
			log_line(TranslationServer.translate(String(t.get("log", "BATTLE_LOG_TIMED_END"))).format({"name": u.name}))
	for bnd in stage.get("bound", []):
		if round_num >= int(bnd.round):
			_release(get_unit(String(bnd.unit)), null)
	for w in stage.get("waves", []):
		if int(w.round) == round_num and not w.get("done", false):
			_spawn_wave(w)
	var obj: Dictionary = stage.get("objective", {})
	if String(obj.get("type", "")) == "survive" and round_num > int(obj.rounds):
		outcome = "victory"
		log_line(TranslationServer.translate("BATTLE_LOG_SURVIVED"))


## Сколько подкреплений ещё не вышло: пока они есть, бой «до последнего врага» не кончается.
func _waves_left() -> int:
	var n := 0
	for w in stage.get("waves", []):
		if not w.get("done", false):
			n += 1
	return n


## Ближайший раунд с подкреплением (для интерфейса) или 0.
func next_wave_round() -> int:
	var best := 0
	for w in stage.get("waves", []):
		if not w.get("done", false) and (best == 0 or int(w.round) < best):
			best = int(w.round)
	return best


func _spawn_wave(w: Dictionary) -> void:
	w["done"] = true
	var cells: Array = w.cells
	var i := 0
	for kind in w.units:
		var c: Array = cells[i % cells.size()]
		i += 1
		var cell := _free_cell_near(Vector2i(int(c[0]), int(c[1])))
		if cell.x < 0:
			continue
		var n := 1
		for o in units:
			if o.kind == kind:
				n += 1
		var e := CombatData.make_enemy(String(kind), n)
		e.cell = cell
		e.initiative = Dice.d20(rng) + e.init_mod
		units.append(e)
		order.append(e.id)
		events.append({"type": "spawn", "unit": e.id})
	log_line(TranslationServer.translate(String(w.get("log", "BATTLE_LOG_WAVE"))))


## Свободная клетка поблизости: сама клетка или ближайшая проходимая без участника.
func _free_cell_near(start: Vector2i) -> Vector2i:
	var seen := {start: true}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var next: Array[Vector2i] = []
		for c in frontier:
			if in_bounds(c) and not is_obstacle(c) and occupant(c) == null:
				return c
			for d in DIRS:
				var n := c + d
				if in_bounds(n) and not seen.has(n):
					seen[n] = true
					next.append(n)
		frontier = next
	return Vector2i(-1, -1)


## Развязать союзника: by — кто разрезал верёвки (null — вырвался сам в свой раунд).
func _release(u: Combatant, by: Combatant) -> void:
	if u == null or not u.has_status("bound"):
		return
	remove_status(u, "bound")
	if by == null:
		log_line(TranslationServer.translate("BATTLE_LOG_BREAKS_FREE").format({"name": u.name}))
	else:
		log_line(TranslationServer.translate("BATTLE_LOG_CUT_FREE").format({"name": u.name, "by": by.name}))


## Герой, вставший рядом со связанным союзником, разрезает верёвки.
func _free_bound_near(u: Combatant) -> void:
	if u.team != 0 or stage.get("bound", []).is_empty():
		return
	for o in heroes():
		if o != u and o.has_status("bound") and dist(o.cell, u.cell) <= 1:
			_release(o, u)


func log_line(text: String) -> void:
	log_lines.append(text)


func take_events() -> Array[Dictionary]:
	var out := events.duplicate()
	events.clear()
	return out


# --- Сохранение ----------------------------------------------------------

const SAVE_VERSION := 1


func to_dict() -> Dictionary:
	var obs := []
	for o in obstacles:
		obs.append([o.x, o.y])
	var zd := {}
	for kind in ZONE_KINDS:
		var arr := []
		for c in zones[kind]:
			arr.append([c.x, c.y, zones[kind][c]])
		zd[kind] = arr
	return {
		"version": SAVE_VERSION, "id": id, "level": level, "width": width, "height": height, "obstacles": obs,
		"units": units.map(func(u: Combatant) -> Dictionary: return u.to_dict()),
		"order": Array(order), "turn_index": turn_index, "round": round_num,
		"rng_seed": str(rng.seed), "rng_state": str(rng.state), "difficulty": difficulty,
		"darkness": darkness, "darkness_gained": darkness_gained, "dark_gifts_used": dark_gifts_used,
		"dark_gifts_cast": dark_gifts_cast, "combat_dark_before": combat_dark_before, "item_darkness": item_darkness,
		"zones": zd, "light_saved": light_saved.keys(), "outcome": outcome, "stage": stage,
	}


static func from_dict(d: Dictionary) -> Battle:
	var b := Battle.new()
	b.id = String(d.get("id", ""))
	b.level = int(d.get("level", 2))
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
	b.dark_gifts_used = int(d.dark_gifts_used)
	b.dark_gifts_cast = int(d.dark_gifts_cast)
	b.combat_dark_before = int(d.combat_dark_before)
	b.item_darkness = int(d.item_darkness)
	for kind in ZONE_KINDS:
		for z in d.zones.get(kind, []):
			var v = z[2]
			if typeof(v) == TYPE_FLOAT:
				v = int(v)
			elif typeof(v) == TYPE_DICTIONARY:
				v = Combatant.ints(v)
			b.zones[kind][Vector2i(int(z[0]), int(z[1]))] = v
	for lid in d.get("light_saved", []):
		b.light_saved[String(lid)] = true
	b.outcome = d.outcome
	b.stage = CombatData.whole_numbers(d.get("stage", {}))
	return b
