extends GutTest
## Экипировка в бою (data/combat/items.json): наборы уровней, свойства и именные правила легендарок.

const A := preload("res://tests/helpers/arena.gd")


func test_every_item_is_translated_and_valid() -> void:
	var slots := ["weapon", "armor", "amulet"]
	for id in Items.catalog():
		var it: Dictionary = Items.catalog()[id]
		assert_has(slots, it.slot, "%s: слот" % id)
		assert_has(Items.TIER_RANK, it.tier, "%s: ступень" % id)
		assert_ne(tr("ITEM_" + id), "ITEM_" + id, "есть имя предмета %s" % id)
		for tid in it.fx.get("traits", []):
			assert_true(CombatData.table("traits").has(tid), "%s: приём %s есть в traits.json" % [id, tid])
		for key in it.get("variants", {}):
			for tid in it.variants[key].fx.get("traits", []):
				assert_true(CombatData.table("traits").has(tid), "%s/%s: приём %s есть" % [id, key, tid])
	var data := CombatData.table("items")
	for lv in data.kits:
		for who in data.kits[lv]:
			for id in data.kits[lv][who] + data.extra.get(lv, {}).get(who, []):
				assert_true(Items.has_item(id), "набор %s/%s: предмет %s есть в каталоге" % [lv, who, id])


func test_kit_level_4() -> void:
	var bare := CombatData.make_hero("wizard", 4, "evoker")
	var sc := CombatData.scenario("level_4", "wizard", "evoker", "full", "trial")
	var w: Combatant = sc.units[0]
	assert_has(w.items, "silent_legacy", "волшебник 4 уровня получает посох Молчащих")
	assert_true(w.spell_dc == bare.spell_dc + 2 and w.max_slots == bare.max_slots + 1, "посох: СЛ +2 и ячейка")
	assert_eq(w.ac, bare.ac + 1, "мантия Молчащих: +1 КД")
	assert_does_not_have(w.items, "workshop_weapon", "легендарка вытесняет добротное оружие из слота")
	var g: Combatant = sc.units[2]
	assert_true(g.items.has("gate_sword") and g.items.has("dwarf_ward"), "набор Гаррета 4 уровня")
	var plain: Combatant = CombatData.scenario("level_4", "wizard", "evoker", "no_velior", "trial", "none").units[0]
	assert_eq(plain.items.size(), 0, "без экипировки предметов нет")
	assert_false(Array(CombatData.table("items").kits["5"].hero).has("forge_mace"), "булава литейной не в общем наборе 5 уровня")


func test_undead_dice_and_dr() -> void:
	var f := CombatData.make_hero("fighter", 3, "guardian")
	Items.equip(f, ["guard_blade", "silent_armor"])
	assert_true(f.undead_dice == "1d4" and f.dr == 1, "клинок гвардии и доспех Молчащих")
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(3, 2))
	f.cell = Vector2i(2, 2)
	var b := A.make([f, z])
	var p := b.attack_preview(f, z)
	var p0 := b.attack_preview(CombatData.make_hero("fighter", 3, "guardian"), z)
	assert_gt(float(p.avg), float(p0.avg) + 3.0, "прогноз учитывает +1 урона и 1d4 по нежити")
	assert_eq(b._mitigate(f, 5), 4, "снижение урона 1")
	assert_true(f.has_trait("oa_adv"), "клинок гвардии Стражу: атака при возможности с преимуществом")


func test_silent_oath_rally() -> void:
	var k := CombatData.make_hero("fighter", 4, "berserker")
	Items.equip(k, ["silent_legacy"])
	var b := A.make([k, CombatData.make_enemy("zombie", 1)])
	b.deal_damage(k, k.max_hp / 2 + 1, "weapon")
	assert_true(int(k.counters.get("rally", 0)) == 1 and k.hp > k.max_hp / 2 - 1, "клятва лечит при падении до половины")
	assert_true(k.has_trait("cleave_full"), "Берсерку — полное рассечение")


func test_pale_ring() -> void:
	var r := CombatData.make_hero("wizard", 4, "evoker")
	var to_hit: int = r.weapon.to_hit
	var dc := r.spell_dc
	Items.equip(r, ["pale_ring"])
	assert_true(r.weapon.to_hit == to_hit + 1 and r.spell_dc == dc + 1 and r.has_trait("ring"), "перстень: +1 к попаданию и заклинаниям")
	var b := A.make([r, CombatData.make_enemy("zombie", 1)])
	assert_true(b.darkness == 3 and b.item_darkness == 3, "перстень: +3 Тьмы за бой")
	b.dark_gifts_used = int(CombatData.rules().dark_gifts_per_battle)
	assert_true(b.can_use(r, "life_drain"), "с перстнем тёмный дар доступен сверх лимита")
	var sc := {"width": 12, "height": 12, "units": [] as Array[Combatant], "obstacles": [], "combat_darkness": 19}
	var r2 := CombatData.make_hero("wizard", 4, "evoker")
	Items.equip(r2, ["pale_ring"])
	sc.units.append(r2)
	var b2 := Battle.new()
	b2.setup(sc, 1, "trial")
	assert_eq(b2.item_darkness, 1, "Тьма предметов тоже упирается в потолок")


func test_nameless_chain() -> void:
	var c1 := A.at(CombatData.make_companion("garret", 5), Vector2i(2, 2))
	Items.equip(c1, ["nameless_chain"])
	var c2 := A.at(CombatData.make_companion("irena", 5), Vector2i(3, 2))
	var b := A.make([c1, c2, CombatData.make_enemy("zombie", 1)])
	b.deal_damage(c2, c2.hp, "weapon")
	assert_true(c2.conscious() and int(c1.counters.get("rescue", 0)) == 1, "цепь поднимает выбывшего соседа")
	assert_eq(Items.resolve("nameless_chain", CombatData.make_hero("wizard", 4, "evoker")).slot, "armor", "цепь Безымянных — доспех")


func test_spear_reach_and_dice() -> void:
	var g := CombatData.make_companion("garret", 3)
	Items.equip(g, ["sunken_shrine_spear", "guard_blade"])
	assert_true(g.reach() == 2 and g.undead_dice == "1d6+1d4", "острога: досягаемость 2, кости по нежити складываются")
	assert_true(g.has_trait("oa_adv"), "клинок гвардии даёт Гаррету атаку при возможности с преимуществом")
	assert_false(Items.has_item("council_seal"), "печать совета — реликвия, не боевой предмет")


func test_guardian_oath_and_wife_tag() -> void:
	var st := A.at(CombatData.make_hero("fighter", 4, "guardian"), Vector2i(2, 2))
	Items.equip(st, ["silent_legacy"])
	var ir := A.at(CombatData.make_companion("irena", 4), Vector2i(3, 2))
	var b := A.make([st, ir, CombatData.make_enemy("zombie", 1)])
	assert_eq(b.ac_of(ir), ir.ac + 3, "Клятва Стража: защитник +3 к КД")
	var g2 := A.at(CombatData.make_companion("garret", 3), Vector2i(5, 5))
	Items.equip(g2, ["garret_tag"])
	var ir2 := A.at(CombatData.make_companion("irena", 3), Vector2i(4, 5))
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(6, 5))
	b = A.make([g2, ir2, z])
	assert_eq(b.ac_of(ir2), ir2.ac + 1, "«Жена ждёт»: сосед Гаррета +1 к КД, пока тот у врага")
	z.cell = Vector2i(9, 9)
	assert_eq(b.ac_of(ir2), ir2.ac, "без врага рядом с Гарретом бонуса нет")


func test_bell_and_shadowskin() -> void:
	var ir3 := CombatData.make_companion("irena", 4)
	Items.equip(ir3, ["irena_bell"])
	var b := A.make([ir3, CombatData.make_enemy("zombie", 1)])
	assert_eq(b.radius_of(ir3, "hallowed_ground"), 2, "колокол: освящённая земля 5×5")
	var r := CombatData.make_hero("rogue", 4, "assassin")
	Items.equip(r, ["shadowskin"])
	var b3 := Battle.new()
	var list: Array[Combatant] = [r, CombatData.make_enemy("zombie", 2)]
	b3.setup({"width": 12, "height": 12, "units": list, "obstacles": []}, 1, "trial")
	assert_true(r.has_status("hidden"), "тенекожа: в начале боя носитель спрятан")


func test_item_variants() -> void:
	var w := CombatData.make_hero("wizard", 3, "binder")
	var f := CombatData.make_hero("fighter", 3, "guardian")
	assert_eq(Items.resolve("workshop_weapon", w).name_key, "ITEM_workshop_weapon_wizard", "вариант для волшебника")
	assert_eq(Items.resolve("workshop_weapon", f).name_key, "ITEM_workshop_weapon", "основной вид")
	var c := CombatData.make_hero("cleric", 4, "light")
	assert_eq(Items.resolve("silent_legacy", c).slot, "amulet", "жрецу легендарка Молчащих — амулет")
	assert_eq(Items.resolve("forge_heart", w).name_key, "ITEM_forge_heart_caster", "заклинателю — вариант caster")


func test_items_survive_save() -> void:
	var w: Combatant = CombatData.scenario("level_4", "wizard", "evoker", "full", "trial").units[0]
	var w2 := Combatant.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	assert_eq(w2.items, w.items, "предметы сохраняются")
	assert_eq(w2.heal_bonus, w.heal_bonus)
	assert_eq(w2.traits, w.traits)
