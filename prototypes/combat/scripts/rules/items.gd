class_name Items
extends RefCounted
## Экипировка: предметы и гарантированные наборы по уровням.
## Полный каталог с местами находки и ценами — design/equipment-catalog.md в файлах проекта;
## здесь те же цифры для боя. Расходники пояса в прототип пока не входят.
##
## fx — свойства предмета:
##   hit, dmg — к попаданию и урону оружием (ближним и дальним); ac — к КД; save — ко всем спасброскам;
##   hp — к максимуму хитов; spell — к атаке заклинаниями и СЛ; slot — ячейки заклинаний;
##   heal — к каждому лечению; dr — снижение урона от оружия; undead — кости по нежити при попадании оружием;
##   drain — кости некротикой при попадании оружием, лечит носителя на половину;
##   sneak — кости d6 к скрытой атаке; rally — раз за бой при падении до половины хитов лечит 2 × уровень;
##   rescue — раз за бой, когда союзник рядом выбывает, лечит его на 2 × уровень носителя;
##   dark — Тьма за каждый бой в предмете; ring — тёмные дары носителя не тратят лимит «три за бой».
## variants — вид предмета под класс, ветку или спутника (ключи: ветка, класс или спутник, затем
## "caster" / "other"); вариант заменяет name и fx.

const ITEMS := {
	# --- Оружие.
	"gate_sword": {"name": "Меч стражи ворот", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1}},
	"tracker_sting": {"name": "Жало следопыта", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1}},
	"mine_greatsword": {"name": "Рудничный двуручник", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1}},
	"eshmur_hunter_bow": {"name": "Лук охотника из Эшмура", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1}},
	"chapel_mace": {"name": "Булава причетника", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1, "heal": 1}},
	"workshop_weapon": {"name": "Оружие из мастерских Короля", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1},
		"variants": {"wizard": {"name": "Посох из мастерских Короля", "fx": {"spell": 1}}}},
	"eshmur_cleaver": {"name": "Тесак Эшмура", "slot": "weapon", "tier": "rare", "fx": {"hit": 1, "dmg": 2}},
	"silver_bow": {"name": "Серебряный лук контрабандистов", "slot": "weapon", "tier": "rare",
		"fx": {"hit": 1, "dmg": 1, "undead": "1d4"}},
	"archivist_fang": {"name": "Клык архивариуса", "slot": "weapon", "tier": "rare", "fx": {"hit": 1, "dmg": 1, "undead": "1d4"}},
	"warden_mace": {"name": "Молот-кадило Молчащих", "slot": "weapon", "tier": "rare", "fx": {"hit": 1, "dmg": 1, "undead": "1d4"}},
	"guard_blade": {"name": "Клинок эльдмарской гвардии", "slot": "weapon", "tier": "rare",
		"fx": {"hit": 1, "dmg": 1, "undead": "1d4"}},
	"forge_mace": {"name": "Булава литейной", "slot": "weapon", "tier": "rare", "fx": {"hit": 1, "dmg": 1, "undead": "1d4"}},
	"black_steel": {"name": "Чёрная сталь", "slot": "weapon", "tier": "rare", "dark_item": true,
		"fx": {"hit": 1, "dmg": 1, "drain": "1d6", "dark": 1}},
	# --- Доспехи.
	"ambush_armor": {"name": "Доспех засады", "slot": "armor", "tier": "fine", "fx": {"ac": 1},
		"variants": {"fighter": {"name": "Кольчуга надсмотрщика", "fx": {"ac": 1}},
			"cleric": {"name": "Кольчуга надсмотрщика", "fx": {"ac": 1}},
			"rogue": {"name": "Кожанка разведчика", "fx": {"ac": 1}},
			"wizard": {"name": "Мантия с оберегами", "fx": {"ac": 1}}}},
	"smuggler_jacket": {"name": "Куртка контрабандиста", "slot": "armor", "tier": "fine", "fx": {"ac": 1}},
	"village_mail": {"name": "Кольчуга деревенской кузни", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "hp": 5}},
	"cloak_underwater": {"name": "Плащ подводного хода", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "save": 1}},
	"silent_armor": {"name": "Доспех Молчащих", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "dr": 1},
		"variants": {"wizard": {"name": "Мантия Молчащих", "fx": {"ac": 1, "save": 1}}}},
	"forge_cloak": {"name": "Плащ литейщика", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "save": 1}},
	"foundry_plate": {"name": "Латы литейной", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "hp": 5}},
	"drowned_shroud": {"name": "Саван утопленника", "slot": "armor", "tier": "rare", "dark_item": true, "fx": {"ac": 2, "dark": 1}},
	# --- Амулеты.
	"ashmoor_beads": {"name": "Чётки храма Эшмура", "slot": "amulet", "tier": "fine", "fx": {"spell": 1}},
	"foreman_token": {"name": "Жетон десятника", "slot": "amulet", "tier": "fine", "fx": {"save": 1}},
	"miner_charm": {"name": "Оберег рудокопа", "slot": "amulet", "tier": "fine", "fx": {"hp": 3}},
	"dwarf_ward": {"name": "Дварфийский оберег", "slot": "amulet", "tier": "rare", "fx": {"ac": 1, "save": 1}},
	"master_seal": {"name": "Печать мастера", "slot": "amulet", "tier": "rare", "fx": {"spell": 1, "slot": 1}},
	"forge_heart": {"name": "Сердце горна", "slot": "amulet", "tier": "rare", "fx": {"save": 1, "hp": 5},
		"variants": {"caster": {"name": "Сердце горна", "fx": {"spell": 1, "slot": 1}}}},
	"bone_focus": {"name": "Костяной фокус", "slot": "amulet", "tier": "rare", "dark_item": true, "fx": {"spell": 2, "dark": 1}},
	# --- Легендарные.
	"silent_legacy": {"name": "Наследие Молчащих", "slot": "weapon", "tier": "legendary", "fx": {},
		"variants": {
			"fighter": {"name": "Клятва Молчащих", "fx": {"hit": 2, "dmg": 2, "rally": true}},
			"rogue": {"name": "Шёпот Молчащих", "fx": {"hit": 2, "dmg": 2, "sneak": 1}},
			"cleric": {"name": "Светильник Молчащих", "slot": "amulet", "fx": {"spell": 2, "heal": 2}},
			"wizard": {"name": "Посох Молчащих", "fx": {"spell": 2, "slot": 1}}}},
	"garret_tag": {"name": "Бирка жены", "slot": "amulet", "tier": "legendary", "fx": {"save": 2, "ac": 1}},
	"irena_bell": {"name": "Колокол разрушенного храма", "slot": "amulet", "tier": "legendary", "fx": {"spell": 1, "heal": 3}},
	"crown_dagger": {"name": "Кинжал с короной", "slot": "weapon", "tier": "legendary", "fx": {"hit": 2, "dmg": 2, "sneak": 1}},
	"crown_dagger_taken": {"name": "Кинжал с короной (забран)", "slot": "weapon", "tier": "legendary", "dark_item": true,
		"fx": {"hit": 2, "dmg": 2, "sneak": 1, "dark": 1}},
	"silent_crown": {"name": "Венец Молчащих", "slot": "amulet", "tier": "legendary", "fx": {"save": 2, "ac": 1}},
	"shadowskin": {"name": "Тенекожа", "slot": "armor", "tier": "legendary", "fx": {"ac": 2}},
	"pale_ring": {"name": "Перстень Бледного Короля", "slot": "amulet", "tier": "legendary", "dark_item": true,
		"fx": {"ring": true, "dark": 3}},
	# --- Скрытые легендарки для охот (число не утверждено).
	"foreman_lantern": {"name": "Фонарь первого штейгера", "slot": "amulet", "tier": "legendary", "fx": {"save": 2, "hp": 5}},
	"sunken_shrine_spear": {"name": "Острога затопленного святилища", "slot": "weapon", "tier": "legendary",
		"fx": {"hit": 2, "dmg": 2, "undead": "1d6"}},
	"nameless_chain": {"name": "Цепь Безымянных", "slot": "amulet", "tier": "legendary", "fx": {"ac": 1, "save": 1, "rescue": true}},
	"council_seal": {"name": "Печать совета", "slot": "amulet", "tier": "legendary", "fx": {"save": 2},
		"variants": {"caster": {"name": "Печать совета", "fx": {"save": 2, "spell": 1}}}},
}

## Гарантированные наборы: что есть у отряда на бою этого уровня, если брать гарантированную добычу.
## Ключи: "hero" и спутники. Под эти наборы балансируются бои.
const KITS := {
	1: {"hero": [], "irena": [], "garret": [], "velior": []},
	2: {"hero": ["ambush_armor"], "irena": ["ashmoor_beads"], "garret": ["gate_sword"], "velior": ["tracker_sting"]},
	3: {"hero": ["ambush_armor", "workshop_weapon"], "irena": ["ashmoor_beads", "chapel_mace"],
		"garret": ["gate_sword", "foreman_token"], "velior": ["tracker_sting", "smuggler_jacket"]},
	4: {"hero": ["silent_legacy", "silent_armor", "workshop_weapon"], "irena": ["ashmoor_beads", "warden_mace"],
		"garret": ["gate_sword", "dwarf_ward"], "velior": ["archivist_fang", "smuggler_jacket"]},
	5: {"hero": ["silent_legacy", "silent_armor", "workshop_weapon", "forge_heart", "forge_mace"], "irena": ["warden_mace", "master_seal"],
		"garret": ["guard_blade", "dwarf_ward"], "velior": ["archivist_fang", "forge_cloak"]},
}

## Сверх бюджета, лучший случай: скрытые легендарки охот, бирка Гаррета (бунт), колокол Ирены (Тьма ниже 50),
## кинжал Велиора (прощён). Добавляются к гарантированному набору в режиме "full".
const EXTRA := {
	1: {},
	2: {"hero": ["foreman_lantern"], "garret": ["garret_tag"]},
	3: {"hero": ["foreman_lantern"], "garret": ["garret_tag", "sunken_shrine_spear"]},
	4: {"hero": ["foreman_lantern"], "irena": ["irena_bell"], "garret": ["garret_tag", "sunken_shrine_spear"],
		"velior": ["crown_dagger", "silent_crown"]},
	5: {"hero": ["foreman_lantern"], "irena": ["irena_bell"], "garret": ["garret_tag", "sunken_shrine_spear"],
		"velior": ["crown_dagger", "silent_crown"]},
}

## Экипировка в бою: "none" — без неё, "kit" — гарантированный набор, "full" — набор и всё сверх бюджета.
static var mode := "kit"


## Вид предмета для участника: имя, слот и свойства.
static func resolve(item_id: String, c: Combatant) -> Dictionary:
	var it: Dictionary = ITEMS[item_id]
	var out := {"id": item_id, "name": it.name, "slot": it.slot, "tier": it.tier, "fx": it.fx,
		"dark_item": it.get("dark_item", false)}
	var v: Dictionary = it.get("variants", {})
	for key in [c.archetype, c.kind, "caster" if c.max_slots > 0 else "other"]:
		if key != "" and v.has(key):
			out.name = v[key].name
			out.fx = v[key].fx
			out.slot = v[key].get("slot", it.slot)
			break
	return out


const TIER_RANK := {"common": 0, "fine": 1, "rare": 2, "legendary": 3}


## Набор участника на уровне: по одному предмету на слот, в слоте остаётся предмет высшей ступени.
static func kit_for(c: Combatant, level: int) -> Array[String]:
	var key := "hero" if c.is_hero else c.kind
	var by_slot := {}
	var ids: Array = KITS[level].get(key, []).duplicate()
	if mode == "full":
		ids += EXTRA[level].get(key, [])
	for id in ids:
		var it := resolve(id, c)
		var cur: String = by_slot.get(it.slot, "")
		if cur == "" or TIER_RANK[it.tier] >= TIER_RANK[resolve(cur, c).tier]:
			by_slot[it.slot] = id
	var out: Array[String] = []
	for slot in ["weapon", "armor", "amulet"]:
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
			c.weapon = _boost(c.weapon, hit, dmg)
			if not c.ranged_weapon.is_empty():
				c.ranged_weapon = _boost(c.ranged_weapon, hit, dmg)
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
			c.undead_dice = String(fx.undead)
		if fx.has("drain"):
			c.drain_dice = String(fx.drain)
		if int(fx.get("sneak", 0)) > 0 and c.sneak_dice != "":
			var d := Dice.parse(c.sneak_dice)
			c.sneak_dice = "%dd%d" % [d.count + int(fx.sneak), d.sides]
		c.rally = c.rally or fx.get("rally", false)
		c.rescue = c.rescue or fx.get("rescue", false)
		c.ring = c.ring or fx.get("ring", false)
		c.item_dark += int(fx.get("dark", 0))


static func _boost(w: Dictionary, hit: int, dmg: int) -> Dictionary:
	var out := w.duplicate()
	out["to_hit"] = int(w.get("to_hit", 0)) + hit
	var d := Dice.parse(String(w.damage))
	var bonus: int = d.bonus + dmg
	var expr := "%dd%d" % [d.count, d.sides]
	if bonus > 0:
		expr += "+%d" % bonus
	elif bonus < 0:
		expr += "%d" % bonus
	out["damage"] = expr
	return out


## Имена надетых предметов для интерфейса.
static func names_of(c: Combatant) -> Array[String]:
	var out: Array[String] = []
	for id in c.items:
		out.append(resolve(id, c).name)
	return out
