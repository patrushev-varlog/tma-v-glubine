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
## Тёмных даров за бой: столько же, сколько укладывается в потолок Тьмы.
const DARK_GIFTS_PER_BATTLE := DARK_BATTLE_CAP / DARK_GIFT_COST
## СЛ паралича гуля.
const PARALYZE_DC := 10

var title := ""
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
## Тьма от тёмных предметов за этот бой (сверх потолка тёмных даров).
var item_darkness := 0
var traps := {}
## Клетки, залитые «Жиром», и клетки «Паутины» до конца боя: клетка → СЛ.
var grease := {}
var webs := {}
## Клетки «Каменных шипов»: клетка → кости урона за шаг.
var spikes := {}
## СЛ «Замедления» для спасбросков в конце хода.
var slow_dc := 13
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
	level = scenario.get("level", 2)
	width = scenario.width
	height = scenario.height
	for o in scenario.obstacles:
		obstacles[o] = true
	for u in scenario.units:
		units.append(u)
	for u in units:
		u.initiative = Dice.d20(rng) + u.init_mod
		if u.team == 0 and u.item_dark > 0:
			item_darkness += u.item_dark
	if item_darkness > 0:
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


## КД с учётом «Защитника» соседа-Стража.
func ac_of(t: Combatant) -> int:
	var v := t.total_ac()
	for o in units:
		if o != t and o.team == t.team and o.conscious() and o.has_trait("protector") and dist(o.cell, t.cell) <= 1:
			v += 2
			break
	return v


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
## Нужно ИИ, чтобы обходить стены, а не упираться в них.
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
	if u.disengaged:
		return 0
	var count := 0
	var used := {}
	var from := u.cell
	for step in path:
		for e in foes_of(u):
			if used.has(e.id) or not e.can_react():
				continue
			if dist(from, e.cell) <= e.reach() and dist(step, e.cell) > e.reach():
				used[e.id] = true
				count += 1
		from = step
	return count


func move_along(u: Combatant, path: Array[Vector2i]) -> void:
	for step in path:
		if not u.conscious() or u.speed_left <= 0 or u.restrained:
			break
		if not u.disengaged:
			for e in foes_of(u):
				if not e.can_react():
					continue
				if dist(u.cell, e.cell) <= e.reach() and dist(step, e.cell) > e.reach():
					e.reaction_used = true
					log_line("%s атакует при возможности." % e.name)
					var hit := _weapon_attack(e, u, {})
					if not u.conscious():
						return
					if hit > 0 and e.has_trait("hold_the_line"):
						log_line("%s удерживает проход: %s останавливается." % [e.name, u.name])
						u.speed_left = 0
						return
		u.cell = step
		u.speed_left -= 1
		if _enter_cell(u, step):
			return


## Ловушка, жир и паутина на клетке, куда участник вошёл. Возвращает true, если он остановился.
func _enter_cell(u: Combatant, c: Vector2i) -> bool:
	if traps.has(c) and u.team == 1:
		traps.erase(c)
		var dmg := Dice.roll(rng, "2d6")
		log_line("%s попадает в ловушку!" % u.name)
		deal_damage(u, dmg, "trap")
		u.speed_left = 0
		return true
	if spikes.has(c) and u.conscious():
		deal_damage(u, Dice.roll(rng, String(spikes[c])), "spikes")
		if not u.conscious():
			return true
	if grease.has(c) and u.conscious() and _grease_check(u, int(grease[c])):
		u.speed_left = 0
		return true
	if webs.has(c) and u.conscious() and _web_check(u, int(webs[c])):
		u.speed_left = 0
		return true
	return false


## Спасбросок Ловкости в жиру; при провале участник падает. Возвращает true при падении.
func _grease_check(u: Combatant, dc: int) -> bool:
	if u.prone or not u.conscious():
		return false
	if saving_throw(u, "dex", dc):
		return false
	u.prone = true
	log_line("%s поскальзывается на жиру и падает." % u.name)
	return true


## Спасбросок Ловкости в паутине; при провале участник опутан. Возвращает true, если опутан.
func _web_check(u: Combatant, dc: int) -> bool:
	if u.restrained or not u.conscious():
		return false
	if saving_throw(u, "dex", dc):
		return false
	u.restrained = true
	log_line("%s запутывается в паутине." % u.name)
	return true


# --- Атаки ----------------------------------------------------------------

func advantage_for(attacker: Combatant, target: Combatant, ranged: bool) -> int:
	var adv := 0
	var dis := 0
	if attacker.hidden:
		adv += 1
	if target.guided_by != "":
		adv += 1
	if target.reckless or target.restrained or target.stunned:
		adv += 1
	if attacker.reckless and not ranged:
		adv += 1
	if attacker.has_trait("assassinate") and round_num == 1 and not target.acted:
		adv += 1
	if target.dodging:
		dis += 1
	if attacker.restrained or attacker.poisoned:
		dis += 1
	if target.prone:
		if ranged:
			dis += 1
		else:
			adv += 1
	if attacker.prone:
		dis += 1
	if ranged:
		for f in foes_of(attacker):
			if dist(f.cell, attacker.cell) <= 1 and not f.turned and not f.stunned:
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


## Кости скрытой атаки с учётом «Добивания».
func sneak_expr(attacker: Combatant, target: Combatant) -> String:
	var expr := attacker.sneak_dice
	if attacker.has_trait("finisher") and target.hp * 2 <= target.max_hp:
		var d := Dice.parse(expr)
		expr = "%dd%d" % [d.count * 2, d.sides]
	return expr


func enemy_damage_scale(attacker: Combatant) -> float:
	return STORY_ENEMY_DAMAGE if attacker.team == 1 and difficulty == "story" else 1.0


## Плоские прибавки к урону атаки оружием: ярость, «Убийство».
func _flat_bonus(attacker: Combatant, target: Combatant, ranged: bool) -> int:
	var b := 0
	if attacker.raging and not ranged:
		b += 2
	if attacker.has_trait("assassinate") and round_num == 1 and not target.acted:
		b += attacker.level
	return b


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
	if attacker.poison_ready:
		extras.append("2d6")
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
		"avg": avg * scale, "expected": chance * avg * scale}


## Грубая доля урона от оружия, которая дойдёт до цели (для прогноза).
func _mitigation_scale(target: Combatant) -> float:
	return 0.8 if target.raging else 1.0


func in_weapon_range(attacker: Combatant, target: Combatant) -> bool:
	if attacker.is_ranged():
		return dist(attacker.cell, target.cell) <= int(attacker.weapon.get("range", 1)) \
			and has_los(attacker.cell, target.cell)
	return dist(attacker.cell, target.cell) <= attacker.reach()


## Атака оружием. Возвращает нанесённый урон (0 при промахе).
func _weapon_attack(attacker: Combatant, target: Combatant, opts: Dictionary) -> int:
	var weapon: Dictionary = opts.get("weapon", attacker.weapon)
	var ranged: bool = weapon.get("kind", "melee") == "ranged"
	var adv := advantage_for(attacker, target, ranged)
	var r1 := Dice.d20(rng)
	var r2 := Dice.d20(rng)
	var roll := r1
	if adv > 0:
		roll = maxi(r1, r2)
	elif adv < 0:
		roll = mini(r1, r2)
	attacker.hidden = false
	target.guided_by = ""
	var total := roll + int(weapon.to_hit)
	var crit := roll == 20
	var tac := ac_of(target)
	if roll == 1 or (not crit and total < tac):
		log_line("%s → %s: промах (%d против КД %d)." % [attacker.name, target.name, total, tac])
		events.append({"type": "miss", "unit": target.id})
		return 0
	var dmg := Dice.roll(rng, weapon.damage, crit)
	if can_sneak(attacker, target, adv):
		attacker.sneak_used = true
		dmg += Dice.roll(rng, sneak_expr(attacker, target), crit)
	var extra := 0
	if opts.has("extra_dice"):
		extra = Dice.roll(rng, opts.extra_dice, crit)
		dmg += extra
	var shadow := 0
	if attacker.shadow_ready:
		attacker.shadow_ready = false
		shadow = Dice.roll(rng, dice_of(attacker, "shadow_step"), crit)
		dmg += shadow
	if attacker.poison_ready:
		attacker.poison_ready = false
		dmg += Dice.roll(rng, "2d6", crit)
		target.poisoned = true
		log_line("Яд: %s ослаб." % target.name)
	var drained := 0
	if target.undead and attacker.undead_dice != "":
		dmg += Dice.roll(rng, attacker.undead_dice, crit)
	if attacker.drain_dice != "":
		drained = Dice.roll(rng, attacker.drain_dice, crit)
		dmg += drained
	dmg += _flat_bonus(attacker, target, ranged)
	dmg = int(ceil(dmg * enemy_damage_scale(attacker)))
	dmg = _mitigate(target, dmg)
	log_line("%s → %s: %s%d урона." % [attacker.name, target.name, "крит! " if crit else "", dmg])
	deal_damage(target, dmg, "weapon")
	if opts.has("drain_extra") and extra > 0:
		heal(attacker, extra / 2)
	if shadow > 0:
		heal(attacker, shadow / 2)
	if drained > 0:
		heal(attacker, drained / 2)
	if weapon.get("on_hit", "") == "paralyze" and target.conscious() and not target.undead:
		if not saving_throw(target, "con", PARALYZE_DC):
			target.stunned = true
			log_line("%s парализован и пропустит ход." % target.name)
	if not ranged and attacker.has_trait("cleave") and not attacker.cleave_used:
		_cleave(attacker, target)
	return dmg


## Кости предметов при попадании оружием: по нежити и некротикой.
func _item_dice(attacker: Combatant, target: Combatant) -> Array[String]:
	var out: Array[String] = []
	if target.undead and attacker.undead_dice != "":
		out.append(attacker.undead_dice)
	if attacker.drain_dice != "":
		out.append(attacker.drain_dice)
	return out


## Ярость, «Стойкость», «Уворот» и доспехи со снижением уменьшают урон от оружия.
func _mitigate(target: Combatant, dmg: int) -> int:
	if target.dr > 0:
		dmg = maxi(dmg - target.dr, 0)
	if target.raging:
		dmg = maxi(dmg - 2, 0)
	if target.has_trait("stalwart"):
		dmg = maxi(dmg - 3, 0)
	if target.has_trait("uncanny_dodge") and not target.uncanny_used and dmg > 0:
		target.uncanny_used = true
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
	if target.turned:
		target.turned = false
		log_line("%s больше не бежит." % target.name)
	if target.hp == 0 and target.raging and target.has_trait("relentless") and not target.relentless_used:
		target.relentless_used = true
		target.hp = 1
		log_line("%s в ярости не падает!" % target.name)
	events.append({"type": "damage", "unit": target.id, "amount": amount})
	if target.rally and not target.rally_used and target.hp > 0 and target.hp * 2 <= target.max_hp:
		target.rally_used = true
		log_line("%s: клятва Молчащих держит на ногах." % target.name)
		heal(target, 2 * target.level)
	if target.hp == 0:
		if target.team == 0:
			if not target.down:
				target.down = true
				target.prone = true
				target.raging = false
				log_line("%s выбывает из боя." % target.name)
				_rescue(target)
		else:
			target.dead = true
			log_line("%s повержен." % target.name)
	_check_outcome()


## «Цепь Безымянных»: союзник рядом с носителем, выбыв, сразу встаёт.
func _rescue(fallen: Combatant) -> void:
	for o in allies_of(fallen):
		if o.rescue and not o.rescue_used and o.conscious() and dist(o.cell, fallen.cell) <= 1:
			o.rescue_used = true
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
	return Dice.d20(rng) + target.save_bonus(stat) >= dc


# --- Действия хода -------------------------------------------------------

## Начать или продолжить действие «Атака»: с дополнительной атакой в нём два удара.
func _spend_attack(u: Combatant) -> void:
	if u.attacks_left == 0:
		u.attacks_left = 1 if u.slow_spell else u.attacks_per_action
	u.attacks_left -= 1
	if u.attacks_left == 0:
		u.action_used = true


func can_attack(u: Combatant, target: Combatant) -> bool:
	return u.conscious() and not u.action_used and not u.stunned and target.conscious() and target.team != u.team \
		and in_weapon_range(u, target)


func attack(u: Combatant, target: Combatant) -> void:
	if not can_attack(u, target):
		return
	_spend_attack(u)
	_weapon_attack(u, target, {})


func ability(aid: String) -> Dictionary:
	return Content.ABILITIES[aid]


func slot_cost(aid: String) -> int:
	return int(ability(aid).get("slot_cost", 1))


func can_use(u: Combatant, aid: String) -> bool:
	if not u.conscious() or u.stunned or not u.abilities.has(aid):
		return false
	var a := ability(aid)
	if a.cost == "action":
		if u.action_used:
			return false
		# Начатое действие «Атака» можно продолжить только ударом.
		if u.attacks_left > 0 and not a.get("attack", false):
			return false
	if a.cost == "bonus" and u.bonus_used:
		return false
	if a.resource == "slot" and u.slots < slot_cost(aid):
		return false
	if a.resource == "use" and u.uses_left(aid) <= 0:
		return false
	if a.get("dark", false) and dark_gifts_left() <= 0 and not u.ring:
		return false
	match aid:
		"action_surge":
			return u.action_used
		"hide":
			return not _foe_adjacent(u)
		"rage":
			return not u.raging
		"reckless":
			return not u.reckless and not u.action_used
		"poison_blade":
			return not u.poison_ready
		"spiritual_weapon":
			return u.spirit_weapon or u.slots >= 1
		"spirit_guardians":
			return not u.guardians
	return true


func _foe_adjacent(u: Combatant) -> bool:
	for f in foes_of(u):
		if dist(f.cell, u.cell) <= 1:
			return true
	return false


## Видит ли участника хоть один враг (в сознании и по линии обзора).
func seen_by_foes(u: Combatant) -> bool:
	for f in foes_of(u):
		if f.turned:
			continue
		if has_los(f.cell, u.cell):
			return true
	return false


func dark_gifts_left() -> int:
	return DARK_GIFTS_PER_BATTLE - dark_gifts_used


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
				if dist(u.cell, f.cell) <= rng_cells and has_los(u.cell, f.cell):
					out.append(f.cell)
		"ally":
			for o in units:
				if o.team == u.team and not o.dead and dist(u.cell, o.cell) <= rng_cells and has_los(u.cell, o.cell):
					if aid == "shield_of_faith" and (o.ac_bonus > 0 or o.down):
						continue
					out.append(o.cell)
		"cell":
			for x in width:
				for y in height:
					var c := Vector2i(x, y)
					if not is_obstacle(c) and dist(u.cell, c) <= rng_cells and has_los(u.cell, c):
						out.append(c)
		"empty_cell":
			for x in width:
				for y in height:
					var c := Vector2i(x, y)
					if not is_obstacle(c) and occupant(c) == null and not traps.has(c) and dist(u.cell, c) <= rng_cells \
						and has_los(u.cell, c):
						out.append(c)
	return out


## Клетки, которые заденет способность при выборе цели.
func ability_area(u: Combatant, aid: String, target: Vector2i) -> Array[Vector2i]:
	var a := ability(aid)
	if aid == "knife_fan":
		var cells: Array[Vector2i] = []
		for f in _fan_targets(u):
			cells.append(f.cell)
		return cells
	if a.has("radius") and a.target == "self":
		return cells_in_radius(u.cell, int(a.radius))
	if a.has("radius"):
		return cells_in_radius(target, int(a.radius))
	var single: Array[Vector2i] = [target]
	return single


## Цели «Веера кинжалов»: до трёх ближайших видимых врагов в 4 клетках.
func _fan_targets(u: Combatant) -> Array[Combatant]:
	var list: Array[Combatant] = []
	for f in foes_of(u):
		if dist(u.cell, f.cell) <= 4 and has_los(u.cell, f.cell):
			list.append(f)
	list.sort_custom(func(a: Combatant, b: Combatant) -> bool: return dist(u.cell, a.cell) < dist(u.cell, b.cell))
	return list.slice(0, 3)


## Урон способности (кости) для этого участника.
func dice_of(u: Combatant, aid: String) -> String:
	var expr := Content.ability_dice(aid, u.level)
	if aid == "fire_bolt" and u.has_trait("empowered"):
		expr += "+3"
	return expr


func ability_preview(u: Combatant, aid: String, target: Vector2i) -> String:
	var a := ability(aid)
	var t := occupant(target)
	match aid:
		"cursed_blade", "trip", "shoot":
			if t != null:
				var p := attack_preview(u, t, dice_of(u, aid) if aid == "cursed_blade" else "",
					u.ranged_weapon if aid == "shoot" else {})
				return "%s: шанс %d%%, урон %d–%d%s" % [a.name, roundi(p.chance * 100), p.min, p.max,
					" (со скрытой атакой)" if can_sneak(u, t, p.adv) else ""]
		"fire_bolt", "life_drain", "guiding_bolt", "spiritual_weapon", "scorching_ray":
			if t != null:
				var expr := dice_of(u, aid)
				var ch := Dice.hit_chance(u.spell_attack, ac_of(t), advantage_for(u, t, true))
				var times := " ×3" if aid == "scorching_ray" else ""
				return "%s: шанс %d%%, урон %d–%d%s" % [a.name, roundi(ch * 100), Dice.min_of(expr), Dice.max_of(expr), times]
		"sacred_flame", "wither":
			if t != null:
				var stat := "dex" if aid == "sacred_flame" else "con"
				var fail := 1.0 - Dice.hit_chance(t.save_bonus(stat), u.spell_dc, 0, false)
				var expr2 := dice_of(u, aid)
				return "%s: провал спасброска %d%%, урон %d–%d" % [a.name, roundi(fail * 100), Dice.min_of(expr2), Dice.max_of(expr2)]
		"magic_missile":
			return "%s: без промаха, урон 6–15" % a.name
		"shove":
			if t != null:
				var bonus := maxi(t.save_bonus("str"), t.save_bonus("dex"))
				var fail2 := 1.0 - Dice.hit_chance(bonus, u.shove_dc(), 0, false)
				var dest := _shove_dest(u, t)
				return "%s: провал спасброска %d%%, %s" % [a.name, roundi(fail2 * 100),
					"отлетит на клетку" if dest.x >= 0 else "некуда отлететь — упадёт"]
		"hide":
			if not seen_by_foes(u):
				return "%s: враги тебя не видят, спрячешься наверняка." % a.name
			var ch2 := Dice.hit_chance(u.save_bonus("dex"), 15, 0, false)
			return "%s: тебя видят, шанс спрятаться %d%%." % [a.name, roundi(ch2 * 100)]
		"turn_undead":
			var names := []
			for f in foes_of(u):
				if f.undead and not f.turned and dist(f.cell, u.cell) <= int(a.radius):
					names.append(f.name)
			if names.is_empty():
				return "%s: рядом нет нежити." % a.name
			return "%s: изгоняет %s" % [a.name, ", ".join(names)]
		"preserve_life":
			return "%s: %d хитов на раненых рядом." % [a.name, 8 * u.level]
		"dodge", "dash", "action_surge", "rage", "reckless", "poison_blade", "spirit_guardians", "mass_healing_word":
			return "%s: %s" % [a.name, a.desc]
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
	if a.get("attack", false):
		_spend_attack(u)
	elif a.cost == "action":
		u.action_used = true
	elif a.cost == "bonus":
		u.bonus_used = true
	if a.resource == "slot":
		u.slots -= slot_cost(aid)
	elif a.resource == "use":
		u.uses[aid] = u.uses_left(aid) - 1
	log_line("%s: %s." % [u.name, a.name])
	var t := occupant(target)
	match aid:
		"second_wind":
			heal(u, Dice.roll(rng, "1d10") + u.level)
		"disengage":
			u.disengaged = true
		"sacred_flame":
			_save_spell(u, t, "dex", dice_of(u, aid), false)
		"healing_word":
			heal(t, _heal_roll(u, aid))
		"fire_bolt":
			_spell_attack(u, t, dice_of(u, aid))
		"magic_missile":
			deal_damage(t, Dice.roll(rng, dice_of(u, aid)), "force")
		"thunderwave", "fireball":
			var stat := "con" if aid == "thunderwave" else "dex"
			for c in ability_area(u, aid, target):
				var o := occupant(c)
				if o == null or o == u or o.dead:
					continue
				if o.team == u.team and u.has_trait("sculpt"):
					continue
				_save_spell(u, o, stat, dice_of(u, aid), true)
		"hallowed_ground":
			for c in ability_area(u, aid, target):
				var o := occupant(c)
				if o == null or o.dead:
					continue
				if o.team == u.team:
					heal(o, Dice.roll(rng, "1d6") + u.heal_bonus)
				elif o.undead:
					deal_damage(o, Dice.roll(rng, "2d6"), "radiant")
		"shield_of_faith":
			t.ac_bonus = 2
		"trip":
			if _weapon_attack(u, t, {}) > 0 and t.conscious():
				if not saving_throw(t, "str", u.spell_dc):
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
					_save_spell(u, o, "dex", dice_of(u, aid), true)
		"trap":
			traps[target] = u.id
		"cursed_blade":
			_weapon_attack(u, t, {"extra_dice": dice_of(u, aid), "drain_extra": true})
		"shadow_step":
			u.hidden = true
			u.disengaged = true
			u.shadow_ready = true
		"wither":
			var dealt := _save_spell(u, t, "con", dice_of(u, aid), true)
			var ally := _most_wounded_ally(u)
			if ally != null and dealt > 0:
				heal(ally, dealt / 2)
		"life_drain":
			var d2 := _spell_attack(u, t, dice_of(u, aid))
			if d2 > 0:
				heal(u, d2 / 2)
		"dodge":
			u.dodging = true
		"shove":
			_shove(u, t)
		"action_surge":
			u.action_used = false
			u.attacks_left = 0
		"rage":
			u.raging = true
		"reckless":
			u.reckless = true
		"dash":
			u.speed_left += u.speed
		"hide":
			if not seen_by_foes(u) or Dice.d20(rng) + u.save_bonus("dex") >= 15:
				u.hidden = true
				log_line("%s прячется." % u.name)
			else:
				log_line("%s не удаётся спрятаться." % u.name)
		"poison_blade":
			u.poison_ready = true
		"shoot":
			_weapon_attack(u, t, {"weapon": u.ranged_weapon})
		"knife_fan":
			var dagger := {"to_hit": u.weapon.to_hit, "damage": "1d4+3", "kind": "ranged"}
			for f in _fan_targets(u):
				_weapon_attack(u, f, {"weapon": dagger})
		"preserve_life":
			_preserve_life(u, int(a.radius))
		"mass_healing_word":
			for o in allies_of(u):
				if dist(o.cell, u.cell) <= int(a.radius) and o.hp < o.max_hp:
					heal(o, _heal_roll(u, aid))
		"turn_undead":
			for f in foes_of(u):
				if f.undead and not f.turned and dist(f.cell, u.cell) <= int(a.radius):
					if saving_throw(f, "wis", u.spell_dc):
						log_line("%s устоял." % f.name)
					else:
						f.turned = true
						log_line("%s бежит в страхе." % f.name)
		"guiding_bolt":
			if _spell_attack(u, t, dice_of(u, aid)) > 0 and t.conscious():
				t.guided_by = u.id
		"spiritual_weapon":
			if not u.spirit_weapon:
				u.spirit_weapon = true
				u.slots -= 1
			_spell_attack(u, t, dice_of(u, aid))
		"spirit_guardians":
			u.guardians = true
		"scorching_ray":
			var aim := t
			for i in 3:
				if aim == null or not aim.conscious():
					aim = _nearest_foe_in_range(u, int(a.range))
				if aim == null:
					break
				_spell_attack(u, aim, dice_of(u, aid))
		"spike_growth":
			for c in ability_area(u, aid, target):
				spikes[c] = dice_of(u, aid)
		"grease":
			for c in ability_area(u, aid, target):
				grease[c] = u.spell_dc
			for c in ability_area(u, aid, target):
				var o := occupant(c)
				if o != null and o.conscious():
					_grease_check(o, u.spell_dc)
		"web":
			for c in ability_area(u, aid, target):
				webs[c] = u.spell_dc
			for c in ability_area(u, aid, target):
				var o := occupant(c)
				if o != null and o.conscious():
					_web_check(o, u.spell_dc)
		"slow":
			slow_dc = u.spell_dc
			for c in ability_area(u, aid, target):
				var o := occupant(c)
				if o == null or not o.conscious() or o.team == u.team or o.slow_spell:
					continue
				if saving_throw(o, "wis", u.spell_dc):
					log_line("%s устоял." % o.name)
				else:
					o.slow_spell = true
					log_line("%s замедлен." % o.name)
	if a.get("dark", false) and not u.ring:
		_add_darkness()
	return true


func _heal_roll(u: Combatant, aid: String) -> int:
	return Dice.roll(rng, dice_of(u, aid)) + (3 if u.has_trait("life_disciple") else 0) + u.heal_bonus


func _preserve_life(u: Combatant, radius: int) -> void:
	var pool := 8 * u.level
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
func _shove_dest(u: Combatant, t: Combatant) -> Vector2i:
	var d := Vector2i(signi(t.cell.x - u.cell.x), signi(t.cell.y - u.cell.y))
	var dest := t.cell + d
	if not in_bounds(dest) or is_obstacle(dest) or occupant(dest) != null:
		return Vector2i(-1, -1)
	if d.x != 0 and d.y != 0 and (is_obstacle(t.cell + Vector2i(d.x, 0)) or is_obstacle(t.cell + Vector2i(0, d.y))):
		return Vector2i(-1, -1)
	return dest


func _shove(u: Combatant, t: Combatant) -> void:
	u.hidden = false
	var bonus := maxi(t.save_bonus("str"), t.save_bonus("dex"))
	if Dice.d20(rng) + bonus >= u.shove_dc():
		log_line("%s устоял на месте." % t.name)
		return
	var dest := _shove_dest(u, t)
	if dest.x < 0:
		t.prone = true
		log_line("%s падает." % t.name)
		return
	t.cell = dest
	log_line("%s отлетает назад." % t.name)
	_enter_cell(t, dest)


func _spell_attack(u: Combatant, t: Combatant, expr: String) -> int:
	var adv := advantage_for(u, t, true)
	var r1 := Dice.d20(rng)
	var r2 := Dice.d20(rng)
	var roll := r1 if adv == 0 else (maxi(r1, r2) if adv > 0 else mini(r1, r2))
	u.hidden = false
	t.guided_by = ""
	if roll == 1 or (roll != 20 and roll + u.spell_attack < ac_of(t)):
		log_line("Промах по %s." % t.name)
		events.append({"type": "miss", "unit": t.id})
		return 0
	var dmg := Dice.roll(rng, expr, roll == 20)
	deal_damage(t, dmg, "spell")
	return dmg


func _save_spell(u: Combatant, t: Combatant, stat: String, expr: String, half_on_save: bool) -> int:
	var dmg := Dice.roll(rng, expr)
	if saving_throw(t, stat, u.spell_dc):
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
	dark_gifts_used += 1
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
	u.attacks_left = 0
	u.bonus_used = false
	u.sneak_used = false
	u.disengaged = false
	u.reaction_used = false
	u.dodging = false
	u.cleave_used = false
	u.reckless = false
	u.uncanny_used = false
	for o in units:
		if o.guided_by == u.id:
			o.guided_by = ""
		if o.slowed_by == u.id:
			o.slowed_by = ""
	_aura_damage(u)
	if not u.conscious():
		return
	if u.stunned:
		u.stunned = false
		u.speed_left = 0
		u.action_used = true
		u.bonus_used = true
		log_line("%s парализован и пропускает ход." % u.name)
		return
	if u.prone:
		u.prone = false
		u.speed_left = u.speed / 2
	if u.slowed_by != "":
		u.speed_left = maxi(u.speed_left - 2, 0)
	if u.slow_spell:
		u.speed_left /= 2
	if webs.has(u.cell):
		if u.restrained:
			if saving_throw(u, "str", int(webs[u.cell])):
				u.restrained = false
				log_line("%s вырывается из паутины." % u.name)
		else:
			_web_check(u, int(webs[u.cell]))
	elif u.restrained:
		u.restrained = false
	if u.restrained:
		u.speed_left = 0


## «Духовные стражи»: враг, начинающий ход рядом с жрецом, получает урон светом.
func _aura_damage(u: Combatant) -> void:
	for h in units:
		if not h.guardians or not h.conscious() or h.team == u.team or not u.conscious():
			continue
		if dist(h.cell, u.cell) <= int(Content.ABILITIES.spirit_guardians.radius):
			log_line("Духовные стражи жгут %s." % u.name)
			_save_spell(h, u, "wis", Content.ability_dice("spirit_guardians", h.level), true)


func end_turn() -> void:
	if outcome != "":
		return
	var u := current()
	u.acted = true
	u.poisoned = false
	if grease.has(u.cell) and u.conscious():
		_grease_check(u, int(grease[u.cell]))
	if u.slow_spell and u.conscious() and saving_throw(u, "wis", slow_dc):
		u.slow_spell = false
		log_line("%s стряхивает замедление." % u.name)
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
	# Если стражи добили начинающего ход врага, ход переходит дальше.
	if outcome == "" and not current().conscious():
		end_turn()


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
		"version": 2, "title": title, "level": level, "width": width, "height": height, "obstacles": obs,
		"units": units.map(func(u: Combatant) -> Dictionary: return u.to_dict()),
		"order": Array(order), "turn_index": turn_index, "round": round_num,
		"rng_seed": str(rng.seed), "rng_state": str(rng.state), "difficulty": difficulty,
		"darkness": darkness, "darkness_gained": darkness_gained, "dark_gifts_used": dark_gifts_used, "item_darkness": item_darkness, "traps": tr,
		"outcome": outcome, "grease": _zones(grease), "webs": _zones(webs), "slow_dc": slow_dc,
		"spikes": spikes.keys().map(func(c: Vector2i) -> Array: return [c.x, c.y, spikes[c]]),
	}


static func _zones(z: Dictionary) -> Array:
	var out := []
	for c in z:
		out.append([c.x, c.y, z[c]])
	return out


static func _zones_from(arr: Array) -> Dictionary:
	var out := {}
	for g in arr:
		out[Vector2i(int(g[0]), int(g[1]))] = int(g[2]) if g.size() > 2 else 13
	return out


static func from_dict(d: Dictionary) -> Battle:
	var b := Battle.new()
	b.title = d.title
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
	b.dark_gifts_used = int(d.get("dark_gifts_used", 0))
	b.item_darkness = int(d.get("item_darkness", 0))
	for t in d.traps:
		b.traps[Vector2i(int(t[0]), int(t[1]))] = String(t[2])
	b.grease = _zones_from(d.get("grease", []))
	b.webs = _zones_from(d.get("webs", []))
	b.slow_dc = int(d.get("slow_dc", 13))
	for sp in d.get("spikes", []):
		b.spikes[Vector2i(int(sp[0]), int(sp[1]))] = String(sp[2])
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
