class_name Items
extends RefCounted
## Экипировка в бою: свойства предметов из data/combat/items.json складываются в характеристики участника.
## Имена предметов — в таблице перевода (ITEM_<id>, вариант — ITEM_<id>_<ключ варианта>).

const TIER_RANK := {"common": 0, "fine": 1, "rare": 2, "legendary": 3}
const SLOTS: Array[String] = ["weapon", "armor", "amulet"]


static func catalog() -> Dictionary:
	return CombatData.table("items").items


static func has_item(item_id: String) -> bool:
	return catalog().has(item_id)


## Вид предмета для участника: слот, ступень и свойства с учётом варианта под ветку, класс или спутника.
static func resolve(item_id: String, c: Combatant) -> Dictionary:
	var it: Dictionary = catalog()[item_id]
	var out := {"id": item_id, "name_key": "ITEM_" + item_id, "slot": it.slot, "tier": it.tier, "fx": it.fx,
		"dark_item": it.get("dark_item", false)}
	var v: Dictionary = it.get("variants", {})
	for key in [c.archetype, c.kind, "caster" if c.max_slots > 0 else "other"]:
		if key != "" and v.has(key):
			out.fx = v[key].fx
			out.slot = v[key].get("slot", it.slot)
			out.name_key = "ITEM_%s_%s" % [item_id, key]
			break
	return out


## Набор участника на уровне: по одному предмету на слот, в слоте остаётся предмет высшей ступени.
## gear: "kit" — гарантированный набор, "full" — набор и всё сверх бюджета (скрытые легендарки и т. п.).
static func kit_for(c: Combatant, level: int, gear := "kit") -> Array[String]:
	var key := "hero" if c.is_hero else c.kind
	var data: Dictionary = CombatData.table("items")
	var ids: Array = data.kits[str(level)].get(key, []).duplicate()
	if gear == "full":
		ids += data.extra[str(level)].get(key, [])
	return pick_best(c, ids)


## Из списка предметов — по одному на слот, лучший по ступени (при равенстве — последний).
static func pick_best(c: Combatant, ids: Array) -> Array[String]:
	var by_slot := {}
	for id in ids:
		var it := resolve(String(id), c)
		var cur: String = by_slot.get(it.slot, "")
		if cur == "" or TIER_RANK[it.tier] >= TIER_RANK[resolve(cur, c).tier]:
			by_slot[it.slot] = String(id)
	var out: Array[String] = []
	for slot in SLOTS:
		if by_slot.has(slot):
			out.append(by_slot[slot])
	return out


## Надевает предметы: свойства складываются в характеристики участника.
static func equip(c: Combatant, ids: Array) -> void:
	for id in ids:
		var it := resolve(String(id), c)
		c.items.append(String(id))
		var fx: Dictionary = it.fx
		var hit := int(fx.get("hit", 0))
		var dmg := int(fx.get("dmg", 0))
		if hit != 0 or dmg != 0:
			c.weapon = boost_weapon(c.weapon, hit, dmg)
			if not c.ranged_weapon.is_empty():
				c.ranged_weapon = boost_weapon(c.ranged_weapon, hit, dmg)
		c.ac += int(fx.get("ac", 0))
		var sv := int(fx.get("save", 0))
		for k in c.saves:
			c.saves[k] = int(c.saves[k]) + sv
		c.max_hp += int(fx.get("hp", 0))
		c.hp = c.max_hp
		c.spell_attack += int(fx.get("spell", 0))
		c.spell_dc += int(fx.get("spell", 0))
		if c.max_slots > 0:
			c.slots += int(fx.get("slot", 0))
			c.max_slots = c.slots
		c.heal_bonus += int(fx.get("heal", 0))
		c.dr += int(fx.get("dr", 0))
		if fx.has("undead"):
			c.undead_dice = Dice.add(c.undead_dice, String(fx.undead))
		if fx.has("fire"):
			c.fire_dice = String(fx.fire)
		if fx.has("drain"):
			c.drain_dice = String(fx.drain)
		if fx.has("reach") and not c.is_ranged():
			c.weapon["reach"] = int(fx.reach)
		for tid in fx.get("traits", []):
			_add_trait(c, String(tid))
		var br: Dictionary = fx.get("branch", {})
		for key in [c.archetype, c.kind]:
			if key != "" and br.has(key):
				_add_trait(c, String(br[key]))
		if int(fx.get("sneak", 0)) > 0 and c.sneak_dice != "":
			var d := Dice.parse(c.sneak_dice)
			c.sneak_dice = "%dd%d" % [d.count + int(fx.sneak), d.sides]
		c.item_dark += int(fx.get("dark", 0))


static func _add_trait(c: Combatant, tid: String) -> void:
	if c.traits.has(tid):
		return
	c.traits.append(tid)
	# Приём может добавить приёмов «на бой» (клык архивариуса: ещё один яд на клинке).
	var more: Dictionary = CombatData.trait_def(tid).get("uses_add", {})
	for aid in more:
		if c.uses.has(aid):
			c.uses[aid] = int(c.uses[aid]) + int(more[aid])


static func boost_weapon(w: Dictionary, hit: int, dmg: int) -> Dictionary:
	var out := w.duplicate(true)
	out["to_hit"] = int(w.get("to_hit", 0)) + hit
	out["damage"] = Dice.plus(String(w.damage), dmg)
	return out


## Имена надетых предметов для интерфейса.
static func names_of(c: Combatant) -> Array[String]:
	var out: Array[String] = []
	for id in c.items:
		out.append(TranslationServer.translate(resolve(id, c).name_key))
	return out
