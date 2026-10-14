extends GutTest
## По тесту на каждый пассивный приём из data/combat/traits.json: test_<id приёма>.

const A := preload("res://tests/helpers/arena.gd")


func test_every_trait_has_test() -> void:
	var names := {}
	for m in get_method_list():
		names[String(m.name)] = true
	var missing: Array[String] = []
	for tid in CombatData.table("traits"):
		if not names.has("test_" + tid):
			missing.append(tid)
	assert_eq(missing, [] as Array[String], "у каждого приёма есть тест")


## Пустое поле: атакующий и цель рядом.
func _pair(u: Combatant, foe: Combatant) -> Battle:
	u.cell = Vector2i(5, 5)
	foe.cell = Vector2i(6, 5)
	return A.make([u, foe])


func test_protector() -> void:
	var g := A.at(CombatData.make_hero("fighter", 3, "guardian"), Vector2i(2, 2))
	var ir := A.at(CombatData.make_companion("irena", 3), Vector2i(3, 2))
	var b := A.make([g, ir, CombatData.make_enemy("zombie", 1)])
	assert_eq(b.ac_of(ir), ir.ac + 2, "сосед Стража +2 к КД")
	assert_eq(b.ac_of(g), g.ac, "себе бонуса нет")
	ir.cell = Vector2i(5, 5)
	assert_eq(b.ac_of(ir), ir.ac, "не рядом — без бонуса")


func test_protector_plus() -> void:
	var g := A.at(CombatData.make_hero("fighter", 4, "guardian"), Vector2i(2, 2))
	g.traits.append("protector_plus")
	var ir := A.at(CombatData.make_companion("irena", 4), Vector2i(3, 2))
	var b := A.make([g, ir, CombatData.make_enemy("zombie", 1)])
	assert_eq(b.ac_of(ir), ir.ac + 3, "с Клятвой +3")
	var k := A.at(CombatData.make_hero("fighter", 4, "berserker"), Vector2i(2, 2))
	k.traits.append("protector_plus")
	b = A.make([k, ir, CombatData.make_enemy("zombie", 1)])
	assert_eq(b.ac_of(ir), ir.ac, "без «Защитника» прибавка не действует")


func test_hold_the_line() -> void:
	var g := CombatData.make_hero("fighter", 4, "guardian")
	assert_true(g.has_trait("hold_the_line"), "Страж 4 уровня держит проход")
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	g.cell = Vector2i(5, 5)
	var b := A.make([z, g])
	b.move_along(z, b.path_to(z, Vector2i(9, 5), b.reachable(z)))
	assert_eq(z.cell, Vector2i(6, 5), "попадание при возможности останавливает")


func test_stalwart() -> void:
	var g := CombatData.make_hero("fighter", 5, "guardian")
	var b := _pair(g, CombatData.make_enemy("zombie", 1))
	assert_eq(b._mitigate(g, 10), 7, "стойкость: урон от оружия −3")


func test_cleave() -> void:
	var f := A.at(CombatData.make_hero("fighter", 3, "berserker"), Vector2i(5, 5))
	var z1 := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var z2 := A.helpless("zombie", 2, Vector2i(6, 6), 99)
	var b := A.make([f, z1, z2])
	b.attack(f, z1)
	assert_true(f.cleave_used and z2.hp < 99, "рассечение задевает второго врага рядом")


func test_cleave_full() -> void:
	assert_true(CombatData.trait_def("cleave_full").has("note"), "только для описания: рассечение и так полным уроном")


func test_relentless() -> void:
	var f := CombatData.make_hero("fighter", 5, "berserker")
	var b := _pair(f, CombatData.make_enemy("overseer", 1))
	b.use_ability(f, "rage", f.cell)
	b.deal_damage(f, f.hp + 5, "test")
	assert_true(f.hp == 1 and not f.down, "неудержимый остаётся с 1 хитом")
	b.deal_damage(f, 5, "test")
	assert_true(f.down and not f.has_status("raging"), "второй раз не спасает, ярость спадает")


func test_assassinate() -> void:
	var r := CombatData.make_hero("rogue", 5, "assassin")
	var z := CombatData.make_enemy("zombie", 1)
	var b := _pair(r, z)
	var p := b.attack_preview(r, z)
	assert_eq(p.adv, 1, "в первом раунде по не ходившему — с преимуществом")
	z.acted = true
	assert_lt(int(b.attack_preview(r, z).max), int(p.max), "и с прибавкой урона, пока цель не ходила")


func test_assassinate_long() -> void:
	var r := CombatData.make_hero("rogue", 5, "assassin")
	r.traits.append("assassinate_long")
	var z := CombatData.make_enemy("zombie", 1)
	var b := _pair(r, z)
	z.acted = true
	b.round_num = 2
	assert_eq(b.attack_preview(r, z).adv, 1, "Шёпот Убийце: «Убийство» и во втором раунде")
	b.round_num = 3
	assert_eq(b.attack_preview(r, z).adv, 0, "но не в третьем")


func test_finisher() -> void:
	var r := CombatData.make_hero("rogue", 4, "assassin")
	var z := CombatData.make_enemy("zombie", 1)
	var b := _pair(r, z)
	var full := b.sneak_expr(r, z)
	z.hp = z.max_hp / 2
	assert_eq(Dice.parse(b.sneak_expr(r, z)).count, Dice.parse(full).count * 2, "по раненому вдвое больше костей скрытой атаки")


func test_uncanny_dodge() -> void:
	var t := CombatData.make_hero("rogue", 3, "trickster")
	var b := _pair(t, CombatData.make_enemy("zombie", 1))
	assert_eq(b._mitigate(t, 10), 5, "первый удар за ход вдвое слабее")
	assert_eq(b._mitigate(t, 10), 10, "второй — полностью")


func test_uncanny_two() -> void:
	var t := CombatData.make_hero("rogue", 3, "trickster")
	t.traits.append("uncanny_two")
	var b := _pair(t, CombatData.make_enemy("zombie", 1))
	b._mitigate(t, 10)
	assert_eq(b._mitigate(t, 10), 5, "плащ литейщика: уворот дважды за ход")


func test_life_disciple() -> void:
	var c := CombatData.make_hero("cleric", 2, "life")
	var g := A.at(CombatData.make_companion("garret"), Vector2i(1, 0))
	var b := A.make([c, g, A.at(CombatData.make_enemy("zombie", 1), Vector2i(9, 9))])
	g.hp = 1
	b.use_ability(c, "healing_word", g.cell)
	assert_gte(g.hp, 1 + 4 + 2, "лечение заклинаниями +2")


func test_sculpt() -> void:
	var w := A.at(CombatData.make_hero("wizard", 2, "evoker"), Vector2i(5, 5))
	var g := A.at(CombatData.make_companion("garret"), Vector2i(4, 5))
	g.saves["con"] = -30
	var b := A.make([w, g, A.helpless("zombie", 1, Vector2i(6, 5), 99)])
	b.use_ability(w, "thunderwave", w.cell)
	assert_eq(g.hp, g.max_hp, "заклинания по области не задевают своих")


func test_empowered() -> void:
	var w := CombatData.make_hero("wizard", 4, "evoker")
	assert_eq(CombatData.params_for(w, "fire_bolt").dice, "1d10+3", "огненный снаряд +3")


func test_extra_attack() -> void:
	var g := CombatData.make_companion("garret", 5)
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var b := _pair(g, z)
	b.attack(g, z)
	assert_false(g.action_used, "после первого удара действие не кончилось")
	b.attack(g, z)
	assert_true(g.action_used, "второй удар его закончил")


func test_rage_plus() -> void:
	var k := CombatData.make_hero("fighter", 2, "berserker")
	k.traits.append("rage_plus")
	var b := _pair(k, CombatData.make_enemy("zombie", 1))
	assert_eq(b.mod_sum(k, "melee_dmg"), 0, "без ярости прибавки нет")
	b.use_ability(k, "rage", k.cell)
	assert_eq(b.mod_sum(k, "melee_dmg"), 2, "в ярости +2")


func test_bow_close() -> void:
	var t := CombatData.make_hero("rogue", 2, "trickster")
	var z := CombatData.make_enemy("zombie", 1)
	var b := _pair(t, z)
	assert_eq(b.advantage_for(t, z, true), -1, "из лука вплотную — помеха")
	t.traits.append("bow_close")
	assert_eq(b.advantage_for(t, z, true), 0, "серебряный лук — без помехи")


func test_poison_more() -> void:
	var r := CombatData.make_hero("rogue", 3, "assassin")
	Items._add_trait(r, "poison_more")
	assert_eq(r.uses_left("poison_blade"), 4, "ещё один яд за бой")


func test_oa_adv() -> void:
	var g := CombatData.make_companion("garret")
	g.traits.append("oa_adv")
	var z := A.helpless("zombie", 1, Vector2i(0, 0), 999)
	var b := _pair(z, g)
	z.ac = 99
	b.rng.seed = 5
	var hits := 0
	for i in 40:
		hits += 1 if b._weapon_attack(g, z, {"oa": true}) > 0 else 0
	var plain := 0
	for i in 40:
		plain += 1 if b._weapon_attack(g, z, {}) > 0 else 0
	assert_gt(hits, plain, "атака при возможности с преимуществом чаще критует по неуязвимой цели")


func test_shield_plus() -> void:
	var c := CombatData.make_hero("cleric", 3, "life")
	c.traits.append("shield_plus")
	assert_eq(int(CombatData.params_for(c, "shield_of_faith").ac), 3, "щит веры +3")


func test_hallowed_plus() -> void:
	var ir := CombatData.make_companion("irena", 4)
	ir.traits.append("hallowed_plus")
	assert_eq(CombatData.params_for(ir, "hallowed_ground").undead_dice, "3d6", "освящённая земля бьёт нежить сильнее")


func test_turn_wide() -> void:
	var c := CombatData.make_hero("cleric", 3, "light")
	c.traits.append("turn_wide")
	assert_eq(int(CombatData.params_for(c, "turn_undead").radius), 3, "изгнание на 3 клетки")


func test_bell_ring() -> void:
	var ir := CombatData.make_companion("irena", 4)
	ir.traits.append("bell_ring")
	assert_eq(int(CombatData.params_for(ir, "hallowed_ground").radius), 2, "освящённая земля 5×5")


func test_fan_wide() -> void:
	var t := CombatData.make_hero("rogue", 5, "trickster")
	t.traits.append("fan_wide")
	var p := CombatData.params_for(t, "knife_fan")
	assert_true(int(p.radius) == 5 and int(p.count) == 4, "четыре кинжала на 5 клеток")


func test_rays_four() -> void:
	var w := CombatData.make_hero("wizard", 3, "evoker")
	w.traits.append("rays_four")
	assert_eq(int(CombatData.params_for(w, "scorching_ray").repeat), 4, "четыре луча")


func test_preserve_plus() -> void:
	var c := CombatData.make_hero("cleric", 5, "life")
	c.traits.append("preserve_plus")
	assert_eq(int(CombatData.params_for(c, "preserve_life").per_level), 10, "сохранение жизни 10 × уровень")


func test_guardians_plus() -> void:
	var c := CombatData.make_hero("cleric", 5, "light")
	c.traits.append("guardians_plus")
	assert_eq(CombatData.params_for(c, "spirit_guardians").extra_dice, "1d8", "стражи 3d8 вместо 2d8")


func test_king_gift() -> void:
	var r := CombatData.make_hero("rogue", 3, "assassin")
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 999)
	r.traits.append("king_gift")
	var b := _pair(r, z)
	z.cell = Vector2i(6, 5)
	assert_eq(b.mod_sum(r, "crit_on"), 19, "крит на 19–20")


func test_shadow_start() -> void:
	var r := CombatData.make_hero("rogue", 4, "assassin")
	r.traits.append("shadow_start")
	var b := Battle.new()
	var list: Array[Combatant] = [r, CombatData.make_enemy("zombie", 2)]
	b.setup({"width": 12, "height": 12, "units": list, "obstacles": []}, 1, "trial")
	assert_true(r.has_status("hidden"), "в начале боя спрятан")


func test_silence() -> void:
	var w := CombatData.make_hero("wizard", 3, "binder")
	w.traits.append("silence")
	var g := A.at(CombatData.make_companion("garret"), Vector2i(1, 0))
	g.saves["wis"] = 0
	var b := A.make([w, g, A.at(CombatData.make_enemy("zombie", 1), Vector2i(9, 9))])
	var rerolls := 0
	for i in 30:
		b.saving_throw(g, "wis", 30)
	rerolls = int(w.counters.get("save_reroll", 0))
	assert_eq(rerolls, 1, "переброс раз за бой")
	assert_true(A.logged(b, "Молчание"), "в журнале")


func test_miner_light() -> void:
	var c := A.at(CombatData.make_hero("cleric", 3, "light"), Vector2i(5, 5))
	c.traits.append("miner_light")
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(6, 5))
	var far := A.at(CombatData.make_enemy("zombie", 2), Vector2i(10, 5))
	var b := A.make([c, z, far])
	b.saving_throw(z, "wis", 10)
	b.saving_throw(far, "wis", 10)
	assert_true(b.light_saved.has(z.id) and not b.light_saved.has(far.id), "первый спасбросок нежити рядом — с помехой")


func test_wife_waits() -> void:
	var g := A.at(CombatData.make_companion("garret", 3), Vector2i(5, 5))
	g.traits.append("wife_waits")
	var ir := A.at(CombatData.make_companion("irena", 3), Vector2i(4, 5))
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(6, 5))
	var b := A.make([g, ir, z])
	assert_eq(b.ac_of(ir), ir.ac + 1, "пока Гаррет у врага, сосед +1 к КД")
	z.cell = Vector2i(9, 9)
	assert_eq(b.ac_of(ir), ir.ac, "иначе без бонуса")


func test_whisper() -> void:
	var r := CombatData.make_hero("rogue", 4, "assassin")
	r.traits.append("whisper")
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 999)
	var b := _pair(r, z)
	var g := A.at(CombatData.make_companion("garret"), Vector2i(7, 5))
	b.units.append(g)
	var speed := r.speed_left
	b.attack(r, z)
	assert_true(r.sneak_used and r.has_status("disengaged") and r.speed_left == speed + 2, "после скрытой атаки — отход и 2 клетки")


func test_lamp() -> void:
	var c := A.at(CombatData.make_hero("cleric", 4, "light"), Vector2i(5, 5))
	c.traits.append("lamp")
	var g := A.at(CombatData.make_companion("garret"), Vector2i(6, 6))
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(11, 11))
	var b := A.make([g, c, z])
	g.hp = 1
	b.end_turn()
	assert_gt(g.hp, 1, "в начале хода носителя самый раненый рядом лечится")


func test_bolt_splash() -> void:
	var w := CombatData.make_hero("wizard", 4, "evoker")
	w.traits.append("bolt_splash")
	var z := A.helpless("zombie", 1, Vector2i(5, 0), 999)
	var z2 := A.helpless("zombie", 2, Vector2i(6, 0), 999)
	var b := A.make([w, z, z2])
	b.use_ability(w, "fire_bolt", z.cell)
	assert_true(z.hp < 999 and z2.hp == 999 - (999 - z.hp) / 2, "сосед цели получает половину урона")


func test_rally() -> void:
	var k := CombatData.make_hero("fighter", 4, "berserker")
	k.traits.append("rally")
	var b := _pair(k, CombatData.make_enemy("zombie", 1))
	b.deal_damage(k, k.max_hp / 2 + 1, "weapon")
	assert_gt(k.hp, k.max_hp / 2 - 1, "при падении до половины лечит 2 × уровень")
	var hp := k.hp
	b.deal_damage(k, 1, "weapon")
	assert_eq(k.hp, hp - 1, "раз за бой")


func test_rescue() -> void:
	var g := A.at(CombatData.make_companion("garret", 5), Vector2i(2, 2))
	g.traits.append("rescue")
	var ir := A.at(CombatData.make_companion("irena", 5), Vector2i(3, 2))
	var b := A.make([g, ir, CombatData.make_enemy("zombie", 1)])
	b.deal_damage(ir, ir.hp, "weapon")
	assert_true(ir.conscious(), "сосед встаёт")
	b.deal_damage(ir, ir.hp, "weapon")
	assert_true(ir.down, "раз за бой")


func test_ring() -> void:
	var w := CombatData.make_hero("wizard", 4, "evoker")
	w.traits.append("ring")
	var b := _pair(w, A.helpless("zombie", 1, Vector2i(6, 5), 999))
	b.dark_gifts_used = 3
	assert_true(b.can_use(w, "life_drain"), "дар сверх лимита")
	b.use_ability(w, "life_drain", Vector2i(6, 5))
	assert_eq(b.dark_gifts_used, 3, "дар с перстнем не тратит лимит")


func test_zones_long() -> void:
	assert_true(CombatData.trait_def("zones_long").has("note"), "только для описания: зоны и так до конца боя")


func test_swimmer() -> void:
	var f := A.at(CombatData.make_hero("fighter", 2, "guardian"), Vector2i(2, 2))
	var z := A.at(CombatData.make_enemy("drowned", 1), Vector2i(8, 8))
	var b := A.make([f, z])
	for x in 12:
		for y in 12:
			b.decor[Vector2i(x, y)] = "wade"
	assert_true(z.has_trait("swimmer"), "утопленник в воде как дома")
	f.speed_left = 6
	z.speed_left = 6
	assert_false(b.reachable(f).has(Vector2i(6, 2)), "герою вода по пояс — шаг за два")
	assert_true(b.reachable(f).has(Vector2i(5, 2)), "на три клетки по воде хватает")
	assert_true(b.reachable(z).has(Vector2i(2, 8)), "утопленнику вода не мешает")


func test_stone_armor() -> void:
	var f := A.at(CombatData.make_hero("fighter", 3, "guardian"), Vector2i(5, 5))
	var g := A.at(CombatData.make_enemy("stone_guardian", 1), Vector2i(6, 5))
	var b := A.make([f, g])
	assert_true(g.has_trait("stone_armor"), "страж Молчащих — каменный")
	assert_eq(b.stone_armor_against(f, g, f.weapon), 4, "длинный меч теряет 4 урона")
	assert_eq(int(b.attack_preview(f, g).stone), 4, "прогноз пишет, сколько гасит камень")
	assert_eq(b.stone_armor_against(f, g, {"id": "mace"}), 0, "булава бьёт в полную силу")
	var c := A.at(CombatData.make_hero("cleric", 3, "life"), Vector2i(7, 5))
	b = A.make([f, g, c])
	assert_true(b.flanked(f, g), "жрица с другой стороны — страж обойдён")
	assert_eq(b.stone_armor_against(f, g, f.weapon), 0, "обойдённого бьют в полную силу")
	c.cell = Vector2i(6, 4)
	assert_false(b.flanked(f, g), "сбоку — ещё не обход")
	# Заклинания камень не держит: броня считается только в атаке оружием.
	assert_eq(b._mitigate(g, 10), 10)


func test_keeper_oath() -> void:
	var t := CombatData.make_enemy("torvin", 1)
	var b := _pair(CombatData.make_hero("fighter", 3, "guardian"), t)
	assert_eq(b._mitigate(t, 10), 8, "клятва хранителя: урон от оружия −2")
