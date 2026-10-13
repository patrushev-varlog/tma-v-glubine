class_name CombatData
extends RefCounted
## Данные боя из data/combat/*.json и сборка участников и боёв из них.
## Правила, по которым эти данные исполняются, — в Battle; схема данных — docs/COMBAT_DATA.md.

const DIR := "res://data/combat/"

static var _cache := {}

## Для настройки баланса из tools/simulate.gd: буквы врагов, которых убрать из боя.
static var exclude: Array = []
## Для настройки баланса: усиление врагов вместо записанного в бою.
static var boost_override := {}
## Для баланса: бой после завершённой охоты главы (+hunt_hp процентов хитов врагам).
static var hunt_done := false


static func table(name: String) -> Dictionary:
	if not _cache.has(name):
		var text := FileAccess.get_file_as_string(DIR + name + ".json")
		var data = JSON.parse_string(text)
		assert(typeof(data) == TYPE_DICTIONARY, "Не читается %s.json" % name)
		data.erase("_doc")
		_cache[name] = whole_numbers(data)
	return _cache[name]


## JSON отдаёт все числа как float; целые превращаем в int, чтобы правила и сохранения считали одинаково.
static func whole_numbers(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			return int(v) if v == floorf(v) else v
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = whole_numbers(v[k])
			return d
		TYPE_ARRAY:
			var a := []
			for x in v:
				a.append(whole_numbers(x))
			return a
	return v


static func rules() -> Dictionary:
	return table("rules")


static func ability(aid: String) -> Dictionary:
	return table("abilities")[aid]


static func has_ability(aid: String) -> bool:
	return table("abilities").has(aid)


static func status_def(sid: String) -> Dictionary:
	return table("statuses").get(sid, {})


static func trait_def(tid: String) -> Dictionary:
	return table("traits").get(tid, {})


static func prof(level: int) -> int:
	return 3 if level >= 5 else 2


static func slots_for(level: int) -> int:
	return int(rules().slots_by_level[level])


# --- Параметры умений -------------------------------------------------------

## Параметры умения для этого участника: params из данных, поверх — ability_params его приёмов
## (колокол Ирены расширяет «Освящённую землю», «Усиленный заговор» прибавляет к снаряду и т. п.).
static func params_for(u: Combatant, aid: String) -> Dictionary:
	var a := ability(aid)
	var p: Dictionary = a.get("params", {}).duplicate()
	if a.has("radius"):
		p["radius"] = int(a.radius)
	for tid in u.traits:
		var td := trait_def(tid)
		if td.has("requires_trait") and not u.traits.has(String(td.requires_trait)):
			continue
		var over: Dictionary = td.get("ability_params", {})
		if over.has(aid):
			p.merge(over[aid], true)
	var dice := ability_dice(aid, u.level, int(p.get("dice_bonus", 0)))
	if dice != "":
		p["dice"] = dice
	return p


## Урон способности с учётом уровня. scale: "cantrip" — вдвое больше костей с 5 уровня,
## "dark" — +1 кость с 3 уровня и ещё +1 с 5-го; "dark5" и "bomb" — +1 кость с 5 уровня.
static func ability_dice(aid: String, level: int, bonus := 0) -> String:
	var a := ability(aid)
	var expr_s: String = a.get("dice", "")
	if expr_s == "":
		return expr_s
	var d := Dice.parse(expr_s)
	var count: int = d.count
	match String(a.get("scale", "")):
		"cantrip":
			if level >= 5:
				count *= 2
		"dark5", "bomb":
			if level >= 5:
				count += 1
		"dark":
			if level >= 3:
				count += 1
			if level >= 5:
				count += 1
	return Dice.expr(count, d.sides, d.bonus + bonus)


## Значение из данных эффекта: "$имя" берётся из параметров умения.
static func resolve(value: Variant, params: Dictionary) -> Variant:
	if value is String and String(value).begins_with("$"):
		return params.get(String(value).substr(1), "")
	return value


# --- Участники --------------------------------------------------------------

static func sneak_for(level: int) -> String:
	return "%dd6" % ((level + 1) / 2)


static func class_ids() -> Array:
	return table("classes").keys()


## Ветки класса в порядке объявления.
static func archetypes_of(class_id: String) -> Array:
	return table("classes")[class_id].archetypes.keys()


static func make_hero(class_id: String, level := 2, archetype := "") -> Combatant:
	var t: Dictionary = table("classes")[class_id]
	if archetype == "":
		archetype = archetypes_of(class_id)[0]
	var arch: Dictionary = t.archetypes[archetype] if level >= 2 else {}
	var c := _from_template(t, class_id, class_id, level)
	c.archetype = archetype if level >= 2 else ""
	if arch.has("ac"):
		c.ac = int(arch.ac)
	if arch.has("weapon"):
		c.weapon = _weapon(arch.weapon, level)
	if arch.has("ranged_weapon"):
		c.ranged_weapon = _weapon(arch.ranged_weapon, level)
	for lv in range(2, level + 1):
		var gain: String = arch.levels[str(lv)]
		if table("traits").has(gain):
			c.traits.append(gain)
		else:
			# Новые умения встают перед тёмным даром, чтобы он оставался последней кнопкой класса.
			c.abilities.insert(c.abilities.size() - 1, gain)
	var cut: Dictionary = t.get("slot_cut", {})
	if cut.has(str(level)):
		# Жрец-герой лечит лучше всех в отряде, поэтому на старших уровнях у него меньше ячеек.
		c.slots -= int(cut[str(level)])
		c.max_slots = c.slots
	_set_uses(c, t)
	_finish(c)
	c.name = tr_unit("HERO", class_id)
	c.letter = "Я"
	c.color = Color.html(rules().hero_color)
	c.is_hero = true
	return c


static func make_companion(comp_id: String, level := 2) -> Combatant:
	var t: Dictionary = table("companions")[comp_id]
	var c := _from_template(t, comp_id, comp_id, level)
	_set_uses(c, t)
	if level >= int(t.get("extra_attack_at", 99)):
		c.traits.append("extra_attack")
	_finish(c)
	c.name = tr_unit("COMPANION", comp_id)
	c.letter = c.name.left(1)
	c.color = Color.html(t.color)
	c.is_companion = true
	return c


static func make_enemy(kind: String, idx: int) -> Combatant:
	var t: Dictionary = table("enemies")[kind]
	var c := Combatant.new()
	c.id = "%s_%d" % [kind, idx]
	c.kind = kind
	c.team = 1
	c.max_hp = int(t.hp)
	c.hp = c.max_hp
	c.ac = int(t.ac)
	c.speed = int(t.get("speed", 6))
	c.init_mod = int(t.get("init", 0))
	c.saves = t.saves.duplicate()
	c.weapon = t.weapon.duplicate(true)
	c.attacks_per_action = int(t.get("attacks", 1))
	c.undead = t.get("undead", false)
	c.spell_dc = int(t.get("spell_dc", 13))
	c.spell_attack = int(t.get("spell_attack", 5))
	for a in t.get("abilities", []):
		c.abilities.append(String(a))
	for tr_id in t.get("traits", []):
		c.traits.append(String(tr_id))
	_set_uses(c, t)
	c.name = tr_unit("ENEMY", kind)
	c.letter = c.name.left(1).to_lower() if not t.get("boss", false) else c.name.left(1)
	c.color = Color.html(rules().undead_color if c.undead else rules().enemy_color)
	return c


## Имя участника из таблицы перевода: HERO_wizard, COMPANION_irena, ENEMY_zombie.
static func tr_unit(prefix: String, kind: String) -> String:
	return TranslationServer.translate("%s_%s" % [prefix, kind])


## Приёмы «на бой» по данным умений; у спутников с uses_growth — +1 с 3 и с 5 уровня.
static func _set_uses(c: Combatant, t: Dictionary) -> void:
	var growth := 0
	if t.get("uses_growth", false):
		growth = (1 if c.level >= 3 else 0) + (1 if c.level >= 5 else 0)
	for aid in c.abilities:
		var a := ability(aid)
		if a.get("resource", "none") == "use":
			c.uses[aid] = int(a.get("uses", 1)) + (0 if a.get("fixed_uses", false) else growth)


## Оружие героя или спутника: бонус атаки = мастерство + mod, урон + mod.
static func _weapon(w: Dictionary, level: int) -> Dictionary:
	var out := w.duplicate(true)
	var mod: int = int(w.get("mod", 3))
	var p := 0 if w.get("no_prof", false) else prof(level)
	out["to_hit"] = mod + p
	var d := Dice.parse(String(w.damage))
	out["damage"] = Dice.expr(d.count, d.sides, mod)
	out["dice"] = Dice.expr(d.count, d.sides, 0)
	out.erase("mod")
	out.erase("no_prof")
	return out


static func _from_template(t: Dictionary, id: String, kind: String, level: int) -> Combatant:
	var c := Combatant.new()
	c.id = id
	c.kind = kind
	c.level = level
	c.max_hp = int(t.hp) + int(t.hp_per_level) * (level - 1)
	c.hp = c.max_hp
	c.ac = int(t.ac)
	c.speed = int(t.get("speed", 6))
	c.init_mod = int(t.get("init", 0))
	c.saves = {}
	# На 5 уровне мастерство растёт: +1 к спасброскам.
	for k in t.saves:
		c.saves[k] = int(t.saves[k]) + (1 if level >= 5 else 0)
	c.weapon = _weapon(t.weapon, level)
	for a in t.get("abilities", []):
		c.abilities.append(String(a))
	if t.get("caster", false):
		c.slots = slots_for(level)
	c.max_slots = c.slots
	c.spell_attack = 3 + prof(level)
	c.spell_dc = 11 + prof(level)
	for tr_id in t.get("traits", []):
		c.traits.append(String(tr_id))
	c.str_mod = int(t.get("str_mod", 0))
	if t.get("sneak", false):
		c.sneak_dice = sneak_for(level)
	return c


static func _finish(c: Combatant) -> void:
	for tid in c.traits:
		c.attacks_per_action = maxi(c.attacks_per_action, int(trait_def(tid).get("attacks", 1)))
	for a in rules().basic_actions:
		c.abilities.append(String(a))


# --- Бои ------------------------------------------------------------------

static func party_members(level: int, party: String) -> Array[String]:
	var out: Array[String] = ["irena", "garret"]
	if level >= 2:
		out.append("velior")
	match party:
		"no_velior":
			out.erase("velior")
		"no_irena":
			out.erase("irena")
		"duo":
			out = ["garret"]
	return out


## Бой из battles.json: отряд героя того же уровня против врагов боя.
## gear — экипировка отряда: "none", "kit" (гарантированный набор уровня) или "full".
## flags — переменные Ink на момент боя (сюжетные бои пролога читают их: засада, ушедший арбалетчик).
## Ключи сюжетного боя (party, bound, timed, waves, objective, ambush_flag, flag_drop, cannot_lose) —
## docs/COMBAT_DATA.md; они собираются в scenario.stage, который исполняет Battle.
static func scenario(battle_id: String, hero_class: String, archetype: String, party := "full", diff := "trial",
		gear := "kit", flags := {}) -> Dictionary:
	var bt: Dictionary = table("battles")[battle_id]
	var level := int(bt.level)
	var heroes: Array[Combatant] = [make_hero(hero_class, level, archetype)]
	var members: Array[String] = party_members(level, party)
	if bt.has("party"):
		members.assign(bt.party)
	for comp in members:
		heroes.append(make_companion(comp, level))
	var missing := 0 if bt.has("party") else party_members(level, "full").size() + 1 - heroes.size()
	var boost: Dictionary = (boost_override if not boost_override.is_empty() else bt.get("boost", {})).duplicate()
	if hunt_done:
		boost["hp"] = int(boost.get("hp", 0)) + int(rules().hunt_hp)
	var drop: Array = exclude.duplicate()
	for flag in bt.get("flag_drop", {}):
		if flags.get(flag, false):
			drop.append_array(bt.flag_drop[flag])
	var hero_cells: Array[Vector2i] = []
	var bound_cells: Array[Vector2i] = []
	var marks := {}
	var enemies: Array[Combatant] = []
	var obstacles: Array[Vector2i] = []
	var counts := {}
	var rows: Array = bt.map
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var c := Vector2i(x, y)
			if ch == "#":
				obstacles.append(c)
			elif ch == "h":
				hero_cells.append(c)
			elif ch == "b":
				bound_cells.append(c)
			elif ch.is_valid_int():
				# Цифры — места выхода подкреплений (waves[].at).
				marks.get_or_add(ch, []).append([x, y])
			elif bt.legend.has(ch):
				if diff == "story" and bt.get("trial_only", []).has(ch) or drop.has(ch):
					continue
				var kind: String = bt.legend[ch]
				counts[kind] = int(counts.get(kind, 0)) + 1
				var e := make_enemy(kind, counts[kind])
				boost_enemy(e, boost)
				e.cell = c
				enemies.append(e)
	if missing > 0:
		enemies = trim_for_party(enemies, party)
	var stage := {}
	var bound: Array = bt.get("bound", [])
	var hi := 0
	for h in heroes:
		var bi := -1
		for k in bound.size():
			if String(bound[k].unit) == h.kind and not h.is_hero:
				bi = k
		if bi >= 0:
			h.cell = bound_cells[bi]
		else:
			h.cell = hero_cells[hi]
			hi += 1
		if gear != "none":
			Items.equip(h, Items.kit_for(h, level, gear))
	if not bound.is_empty():
		stage["bound"] = bound.duplicate(true)
	for key in ["timed", "objective", "cannot_lose"]:
		if bt.has(key):
			stage[key] = bt[key].duplicate(true) if bt[key] is Array or bt[key] is Dictionary else bt[key]
	if String(bt.get("ambush_flag", "")) != "" and flags.get(String(bt.ambush_flag), false):
		stage["surprise"] = true
	var waves := []
	for w in bt.get("waves", []):
		var kinds: Array = w.units.duplicate()
		if diff == "trial":
			kinds.append_array(w.get("trial_units", []))
		var wave := {"round": int(w.round), "units": kinds, "cells": marks.get(String(w.at), [])}
		if w.has("log"):
			wave["log"] = w.log
		waves.append(wave)
	if not waves.is_empty():
		stage["waves"] = waves
	return {"id": battle_id, "width": String(rows[0]).length(), "height": rows.size(), "units": heroes + enemies,
		"obstacles": obstacles, "level": level, "stage": stage}


## Урезать врагов под неполный отряд по бюджету опыта (без босса).
## Сначала уходят рядовые бойцы ближнего боя, стрелки — в последнюю очередь; босс остаётся, но с меньшими хитами.
static func trim_for_party(enemies: Array[Combatant], party: String) -> Array[Combatant]:
	var en := table("enemies")
	var out: Array[Combatant] = []
	var total := 0
	for e in enemies:
		if en[e.kind].get("boss", false):
			var cut := int(rules().boss_hp_cut.get(party, 0))
			e.max_hp = int(round(e.max_hp * (1.0 - cut / 100.0)))
			e.hp = e.max_hp
		else:
			total += int(en[e.kind].xp)
		out.append(e)
	var target := total * int(rules().party_budget.get(party, 100)) / 100.0
	var sum := float(total)
	while sum > target * 1.05:
		var pick: Combatant = null
		for ranged_pass in [false, true]:
			for e in out:
				if en[e.kind].get("boss", false) or e.is_ranged() != ranged_pass:
					continue
				var xp := float(en[e.kind].xp)
				# Первыми уходят рядовые (самые слабые), пока состав не опускается ниже бюджета больше чем на 15%.
				if sum - xp >= target * 0.85 and (pick == null or xp < float(en[pick.kind].xp)):
					pick = e
			if pick != null:
				break
		if pick == null:
			break
		out.erase(pick)
		sum -= float(en[pick.kind].xp)
	return out


## Усиление врагов под гарантированный набор экипировки отряда: hp — проценты к хитам, hit, dmg, ac — прибавки.
static func boost_enemy(e: Combatant, boost: Dictionary) -> void:
	if boost.is_empty():
		return
	e.max_hp = int(round(e.max_hp * (1.0 + float(boost.get("hp", 0)) / 100.0)))
	e.hp = e.max_hp
	e.ac += int(boost.get("ac", 0))
	var hit := int(boost.get("hit", 0))
	var dmg := int(boost.get("dmg", 0))
	if hit != 0 or dmg != 0:
		e.weapon = Items.boost_weapon(e.weapon, hit, dmg)
