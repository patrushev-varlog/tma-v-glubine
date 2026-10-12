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
##   dark — Тьма за каждый бой в предмете; ring — тёмные дары носителя не тратят лимит «три за бой»;
##   reach — досягаемость оружия ближнего боя; rule — именное правило легендарки (приём в traits);
##   branch — свойство ветки: {ветка или спутник: приём}, работает только у них.
## Кости по нежити от разных предметов складываются.
## variants — вид предмета под класс, ветку или спутника (ключи: ветка, класс или спутник, затем
## "caster" / "other"); вариант заменяет name и fx.

const ITEMS := {
	# --- Оружие.
	"gate_sword": {"name": "Меч стражи ворот", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1}},
	"tracker_sting": {"name": "Жало следопыта", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1}},
	"mine_greatsword": {"name": "Рудничный двуручник", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1}},
	"eshmur_hunter_bow": {"name": "Лук охотника из Эшмура", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1}},
	"sutler_censer": {"name": "Походное кадило", "slot": "weapon", "tier": "fine", "fx": {"heal": 1}},
	"chapel_mace": {"name": "Булава причетника", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1, "heal": 1}},
	"workshop_weapon": {"name": "Оружие из мастерских Короля", "slot": "weapon", "tier": "fine", "fx": {"hit": 1, "dmg": 1},
		"variants": {"wizard": {"name": "Посох из мастерских Короля", "fx": {"spell": 1}}}},
	"eshmur_cleaver": {"name": "Тесак Эшмура", "slot": "weapon", "tier": "rare",
		"fx": {"hit": 1, "dmg": 2, "branch": {"berserker": "rage_plus"}}},
	"silver_bow": {"name": "Серебряный лук контрабандистов", "slot": "weapon", "tier": "rare",
		"fx": {"hit": 1, "dmg": 1, "undead": "1d4", "branch": {"trickster": "bow_close"}}},
	"archivist_fang": {"name": "Клык архивариуса", "slot": "weapon", "tier": "rare",
		"fx": {"hit": 1, "dmg": 1, "undead": "1d4", "branch": {"assassin": "poison_more"}}},
	"warden_mace": {"name": "Молот-кадило Молчащих", "slot": "weapon", "tier": "rare",
		"fx": {"hit": 1, "dmg": 1, "undead": "1d4", "branch": {"irena": "hallowed_plus", "light": "turn_wide"}}},
	"guard_blade": {"name": "Клинок эльдмарской гвардии", "slot": "weapon", "tier": "rare",
		"fx": {"hit": 1, "dmg": 1, "undead": "1d4", "branch": {"guardian": "oa_adv", "garret": "oa_adv"}}},
	"forge_mace": {"name": "Булава литейной", "slot": "weapon", "tier": "rare",
		"fx": {"hit": 1, "dmg": 1, "undead": "1d4", "branch": {"life": "shield_plus"}}},
	"foundry_maul": {"name": "Молот литейщика", "slot": "weapon", "tier": "rare", "fx": {"hit": 1, "dmg": 1, "fire": "1d4"}},
	"black_steel": {"name": "Чёрная сталь", "slot": "weapon", "tier": "rare", "dark_item": true,
		"fx": {"hit": 1, "dmg": 1, "drain": "1d4", "dark": 1}},
	# --- Доспехи.
	"ambush_armor": {"name": "Доспех засады", "slot": "armor", "tier": "fine", "fx": {"ac": 1},
		"variants": {"fighter": {"name": "Кольчуга надсмотрщика", "fx": {"ac": 1}},
			"cleric": {"name": "Кольчуга надсмотрщика", "fx": {"ac": 1}},
			"rogue": {"name": "Кожанка разведчика", "fx": {"ac": 1}},
			"wizard": {"name": "Мантия с оберегами", "fx": {"ac": 1}}}},
	"sutler_quilt": {"name": "Стёганка обозника", "slot": "armor", "tier": "fine", "fx": {"ac": 1}},
	"smuggler_jacket": {"name": "Куртка контрабандиста", "slot": "armor", "tier": "fine", "fx": {"ac": 1}},
	"village_mail": {"name": "Кольчуга деревенской кузни", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "hp": 5}},
	"cloak_underwater": {"name": "Плащ подводного хода", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "save": 1}},
	"blackwater_scale": {"name": "Чешуя Чёрной воды", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "dr": 1}},
	"silent_armor": {"name": "Доспех Молчащих", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "dr": 1},
		"variants": {"wizard": {"name": "Мантия Молчащих", "fx": {"ac": 1, "save": 1}}}},
	"forge_cloak": {"name": "Плащ литейщика", "slot": "armor", "tier": "rare",
		"fx": {"ac": 1, "save": 1, "branch": {"trickster": "uncanny_two"}}},
	"foundry_plate": {"name": "Латы литейной", "slot": "armor", "tier": "rare", "fx": {"ac": 1, "hp": 5}},
	"drowned_shroud": {"name": "Саван утопленника", "slot": "armor", "tier": "rare", "dark_item": true,
		"fx": {"ac": 1, "dr": 1, "dark": 1}},
	# --- Амулеты.
	"sutler_amulet": {"name": "Ладанка обозника", "slot": "amulet", "tier": "fine", "fx": {"save": 1}},
	"ashmoor_beads": {"name": "Чётки храма Эшмура", "slot": "amulet", "tier": "fine", "fx": {"spell": 1}},
	"foreman_token": {"name": "Жетон десятника", "slot": "amulet", "tier": "fine", "fx": {"save": 1}},
	"miner_charm": {"name": "Оберег рудокопа", "slot": "amulet", "tier": "fine", "fx": {"hp": 3}},
	"dwarf_ward": {"name": "Дварфийский оберег", "slot": "amulet", "tier": "rare", "fx": {"ac": 1, "save": 1}},
	"master_seal": {"name": "Печать мастера", "slot": "amulet", "tier": "rare",
		"fx": {"spell": 1, "slot": 1, "branch": {"evoker": "rays_four"}}},
	"forge_heart": {"name": "Сердце горна", "slot": "amulet", "tier": "rare", "fx": {"save": 1, "hp": 5},
		"variants": {"caster": {"name": "Сердце горна", "fx": {"spell": 1, "slot": 1}}}},
	"slag_ward": {"name": "Оберег из окалины", "slot": "amulet", "tier": "rare", "fx": {"dr": 1, "hp": 3}},
	"bone_focus": {"name": "Костяной фокус", "slot": "amulet", "tier": "rare", "dark_item": true,
		"fx": {"spell": 1, "slot": 1, "dark": 1}},
	# --- Легендарные.
	"silent_legacy": {"name": "Наследие Молчащих", "slot": "weapon", "tier": "legendary", "fx": {},
		"variants": {
			"fighter": {"name": "Клятва Молчащих", "fx": {"hit": 2, "dmg": 2, "rally": true,
				"branch": {"guardian": "protector_plus", "berserker": "cleave_full"}}},
			"rogue": {"name": "Шёпот Молчащих", "fx": {"hit": 2, "dmg": 2, "sneak": 1, "rule": "whisper",
				"branch": {"assassin": "assassinate_long", "trickster": "fan_wide"}}},
			"cleric": {"name": "Светильник Молчащих", "slot": "amulet", "fx": {"spell": 2, "heal": 2, "rule": "lamp",
				"branch": {"life": "preserve_plus", "light": "guardians_plus"}}},
			"wizard": {"name": "Посох Молчащих", "fx": {"spell": 2, "slot": 1,
				"branch": {"evoker": "bolt_splash", "binder": "zones_long"}}}}},
	"garret_tag": {"name": "Бирка жены", "slot": "amulet", "tier": "legendary", "fx": {"save": 1, "hp": 5, "rule": "wife_waits"}},
	"irena_bell": {"name": "Колокол разрушенного храма", "slot": "amulet", "tier": "legendary",
		"fx": {"spell": 1, "heal": 3, "rule": "bell_ring"}},
	"crown_dagger": {"name": "Кинжал с короной", "slot": "weapon", "tier": "legendary",
		"fx": {"hit": 2, "dmg": 2, "sneak": 1, "rule": "king_gift"}},
	"crown_dagger_taken": {"name": "Кинжал с короной (забран)", "slot": "weapon", "tier": "legendary", "dark_item": true,
		"fx": {"hit": 2, "dmg": 2, "sneak": 1, "rule": "king_gift", "dark": 1}},
	"silent_crown": {"name": "Венец Молчащих", "slot": "amulet", "tier": "legendary", "fx": {"save": 2, "rule": "silence"}},
	"shadowskin": {"name": "Тенекожа", "slot": "armor", "tier": "legendary", "fx": {"ac": 2, "rule": "shadow_start"}},
	"pale_ring": {"name": "Перстень Бледного Короля", "slot": "amulet", "tier": "legendary", "dark_item": true,
		"fx": {"hit": 1, "spell": 1, "ring": true, "dark": 3}},
	# --- Скрытые легендарки охот (по охоте на главу).
	"foreman_lantern": {"name": "Фонарь первого штейгера", "slot": "amulet", "tier": "legendary",
		"fx": {"save": 1, "hp": 5, "rule": "miner_light"}},
	"sunken_shrine_spear": {"name": "Острога затопленного святилища", "slot": "weapon", "tier": "legendary",
		"fx": {"hit": 1, "dmg": 1, "undead": "1d6", "reach": 2}},
	"nameless_chain": {"name": "Цепь Безымянных", "slot": "armor", "tier": "legendary", "fx": {"ac": 1, "save": 1, "rescue": true}},
}
## Печать совета (council_seal) — сюжетная реликвия без боевых свойств, в боевые предметы не входит.

## Гарантированные наборы: что есть у отряда на бою этого уровня, если брать гарантированную добычу.
## Ключи: "hero" и спутники. Под эти наборы балансируются бои.
const KITS := {
	1: {"hero": [], "irena": [], "garret": [], "velior": []},
	2: {"hero": ["ambush_armor"], "irena": ["ashmoor_beads"], "garret": ["gate_sword"], "velior": ["tracker_sting"]},
	3: {"hero": ["ambush_armor", "workshop_weapon"], "irena": ["ashmoor_beads", "chapel_mace"],
		"garret": ["gate_sword", "foreman_token"], "velior": ["tracker_sting", "smuggler_jacket"]},
	4: {"hero": ["silent_legacy", "silent_armor", "workshop_weapon"], "irena": ["ashmoor_beads", "warden_mace"],
		"garret": ["gate_sword", "dwarf_ward"], "velior": ["archivist_fang", "smuggler_jacket"]},
	5: {"hero": ["silent_legacy", "silent_armor", "workshop_weapon", "forge_heart"], "irena": ["warden_mace", "master_seal"],
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
			c.undead_dice = add_dice(c.undead_dice, String(fx.undead))
		if fx.has("fire"):
			c.fire_dice = String(fx.fire)
		if fx.has("reach") and not c.weapon.get("kind", "melee") == "ranged":
			c.weapon = c.weapon.duplicate()
			c.weapon["reach"] = int(fx.reach)
		if fx.has("rule") and not c.traits.has(String(fx.rule)):
			c.traits.append(String(fx.rule))
		var br: Dictionary = fx.get("branch", {})
		for key in [c.archetype, c.kind]:
			if key != "" and br.has(key) and not c.traits.has(String(br[key])):
				c.traits.append(String(br[key]))
		if c.traits.has("poison_more") and c.uses.has("poison_blade"):
			c.uses["poison_blade"] = 4
		if fx.has("drain"):
			c.drain_dice = String(fx.drain)
		if int(fx.get("sneak", 0)) > 0 and c.sneak_dice != "":
			var d := Dice.parse(c.sneak_dice)
			c.sneak_dice = "%dd%d" % [d.count + int(fx.sneak), d.sides]
		c.rally = c.rally or fx.get("rally", false)
		c.rescue = c.rescue or fx.get("rescue", false)
		c.ring = c.ring or fx.get("ring", false)
		c.item_dark += int(fx.get("dark", 0))


## Сложить кости: одинаковые грани объединяются («1d4» + «1d4» = «2d4»), разные идут через «+».
static func add_dice(have: String, more: String) -> String:
	if have == "":
		return more
	var a := Dice.parse(have)
	var b := Dice.parse(more)
	if not Dice._multi(have) and a.sides == b.sides and a.bonus == 0 and b.bonus == 0:
		return "%dd%d" % [a.count + b.count, a.sides]
	return have + "+" + more


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
