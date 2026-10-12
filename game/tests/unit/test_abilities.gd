extends GutTest
## По тесту на каждое умение из data/combat/abilities.json (B7): test_<id умения>.
## test_every_ability_has_test следит, чтобы новое умение не осталось без теста.

const A := preload("res://tests/helpers/arena.gd")


func test_every_ability_has_test() -> void:
	var names := {}
	for m in get_method_list():
		names[String(m.name)] = true
	var missing: Array[String] = []
	for aid in CombatData.table("abilities"):
		if not names.has("test_" + aid):
			missing.append(aid)
	assert_eq(missing, [] as Array[String], "у каждого умения есть тест")


func test_every_ability_is_translated() -> void:
	for aid in CombatData.table("abilities"):
		assert_ne(tr("ABILITY_" + aid), "ABILITY_" + aid, "есть имя умения %s" % aid)
		assert_ne(tr("ABILITY_%s_DESC" % aid), "ABILITY_%s_DESC" % aid, "есть описание умения %s" % aid)


# --- Общие для всех и классы 1 уровня --------------------------------------

func test_dodge() -> void:
	var h := CombatData.make_hero("wizard", 1)
	var o := A.at(CombatData.make_enemy("overseer", 1), Vector2i(1, 0))
	var b := A.make([h, o])
	assert_true(b.use_ability(h, "dodge", h.cell), "уклонение сработало")
	assert_eq(b.attack_preview(o, h).adv, -1, "по уклоняющемуся атаки с помехой")
	b.end_turn()
	b.end_turn()
	assert_false(h.has_status("dodging"), "уклонение кончается в начале своего хода")


func test_shove() -> void:
	var f := A.at(CombatData.make_hero("fighter", 1), Vector2i(2, 2))
	var v := A.at(CombatData.make_companion("velior"), Vector2i(9, 9))
	var z := A.helpless("zombie", 1, Vector2i(3, 2))
	var b := A.make([f, v, z])
	b.zones.trap[Vector2i(4, 2)] = {"src": v.id, "dice": "2d6"}
	assert_true(b.use_ability(f, "shove", z.cell), "толчок применён")
	assert_true(z.cell == Vector2i(4, 2) and z.hp < z.max_hp and not b.zones.trap.has(Vector2i(4, 2)), "толчок в ловушку")
	assert_true(f.action_used, "без дополнительной атаки толчок — всё действие")
	b.obstacles[Vector2i(5, 2)] = true
	f.cell = Vector2i(3, 2)
	f.action_used = false
	f.attacks_left = 0
	b.use_ability(f, "shove", z.cell)
	assert_true(z.cell == Vector2i(4, 2) and z.has_status("prone"), "у стены враг не отлетает, а падает")


func test_second_wind() -> void:
	var f := CombatData.make_hero("fighter", 3)
	var b := A.make([f, A.at(CombatData.make_enemy("zombie", 1), Vector2i(9, 9))])
	f.hp = 1
	assert_true(b.use_ability(f, "second_wind", f.cell), "второе дыхание")
	assert_true(f.hp >= 1 + 1 + 3 and f.bonus_used, "лечит 1d10 + уровень бонусным действием")
	assert_false(b.can_use(f, "second_wind"), "раз за бой")


func test_cursed_blade() -> void:
	var f := A.at(CombatData.make_hero("fighter", 1), Vector2i(5, 5))
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var b := A.make([f, z])
	assert_true(b.use_ability(f, "cursed_blade", z.cell), "проклятый клинок")
	assert_true(z.hp <= 99 - 2 - 2, "удар с 2d8 некротики")
	assert_eq(b.darkness, 2, "первый дар в бою: +2 Тьмы")
	assert_true(A.logged(b, "−2 хитов"), "дар стоит хитов: два за уровень")
	assert_eq(CombatData.ability_dice("cursed_blade", 5), "3d8", "с 5 уровня кость больше")


func test_disengage() -> void:
	var h := A.at(CombatData.make_hero("rogue", 1), Vector2i(5, 5))
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(6, 5))
	var b := A.make([h, z])
	assert_true(b.use_ability(h, "disengage", h.cell), "отход сработал")
	b.move_along(h, b.path_to(h, Vector2i(2, 5), b.reachable(h)))
	assert_true(not z.reaction_used and h.cell == Vector2i(2, 5), "после отхода атаки нет")


func test_shadow_step() -> void:
	var r := A.at(CombatData.make_hero("rogue", 1), Vector2i(5, 5))
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var b := A.make([r, z])
	r.hp = 3
	assert_true(b.use_ability(r, "shadow_step", r.cell), "шаг в тень")
	assert_true(r.has_status("shadow_ready") and r.has_status("hidden") and r.has_status("disengaged"), "скрыт, отходит и готов ударить")
	b.attack(r, z)
	assert_true(not r.has_status("shadow_ready") and r.hp > 1, "удар из тени ранит некротикой и лечит плута")
	assert_false(r.has_status("hidden"), "атака раскрывает")


func test_sacred_flame() -> void:
	var c := CombatData.make_hero("cleric", 1)
	var z := A.helpless("zombie", 1, Vector2i(5, 0))
	var b := A.make([c, z])
	assert_true(b.use_ability(c, "sacred_flame", z.cell), "священное пламя")
	assert_lt(z.hp, z.max_hp, "провал спасброска — урон")
	var s := A.sturdy(CombatData.make_enemy("zombie", 2))
	s.cell = Vector2i(6, 0)
	b.units.append(s)
	c.action_used = false
	b.use_ability(c, "sacred_flame", s.cell)
	assert_eq(s.hp, s.max_hp, "успешный спасбросок — без урона")


func test_healing_word() -> void:
	var c := CombatData.make_hero("cleric", 1)
	var g := A.at(CombatData.make_companion("garret", 1), Vector2i(4, 0))
	var b := A.make([c, g, A.at(CombatData.make_enemy("zombie", 1), Vector2i(9, 9))])
	g.hp = 1
	var slots := c.slots
	assert_true(b.use_ability(c, "healing_word", g.cell), "слово исцеления")
	assert_true(g.hp >= 1 + 4 and c.slots == slots - 1 and c.bonus_used, "1d4+3, ячейка, бонусное действие")


func test_wither() -> void:
	var c := CombatData.make_hero("cleric", 1)
	var g := A.at(CombatData.make_companion("garret", 1), Vector2i(1, 0))
	var z := A.helpless("zombie", 1, Vector2i(5, 0), 99)
	var b := A.make([c, g, z])
	g.hp = 2
	assert_true(b.use_ability(c, "wither", z.cell), "увядание")
	var dealt := 99 - z.hp
	assert_true(dealt >= 2 and g.hp == 2 + dealt / 2, "половина урона лечит самого раненого союзника")
	assert_true(c.slots == CombatData.slots_for(1) - 1 and b.darkness == 2, "дар заклинателя: ячейка и Тьма")


func test_fire_bolt() -> void:
	var w := CombatData.make_hero("wizard", 1)
	var z := A.helpless("zombie", 1, Vector2i(9, 0), 99)
	var b := A.make([w, z])
	assert_true(b.use_ability(w, "fire_bolt", z.cell), "огненный снаряд")
	assert_lt(z.hp, 99, "попадание")
	assert_false(b.ability_targets(w, "fire_bolt").has(Vector2i(11, 11)), "дальше 10 клеток не достаёт")
	assert_eq(b.dice_of(CombatData.make_hero("wizard", 4, "evoker"), "fire_bolt"), "1d10+3", "«Усиленный заговор» Воплотителя")


func test_magic_missile() -> void:
	var w := CombatData.make_hero("wizard", 1)
	var z := A.sturdy(A.at(CombatData.make_enemy("zombie", 1), Vector2i(5, 0)))
	z.max_hp = 99
	z.hp = 99
	var b := A.make([w, z])
	assert_true(b.use_ability(w, "magic_missile", z.cell), "волшебная стрела")
	assert_true(z.hp <= 99 - 6 and z.hp >= 99 - 15, "попадает всегда: 3d4+3")
	assert_eq(w.slots, CombatData.slots_for(1) - 1, "тратит ячейку")


func test_thunderwave() -> void:
	var w := A.at(CombatData.make_hero("wizard", 1), Vector2i(5, 5))
	var g := A.at(CombatData.make_companion("garret", 1), Vector2i(4, 5))
	g.saves["con"] = -30
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var far := A.helpless("zombie", 2, Vector2i(8, 5), 99)
	var b := A.make([w, g, z, far])
	assert_true(b.use_ability(w, "thunderwave", w.cell), "волна грома")
	assert_true(z.hp < 99 and far.hp == 99, "задевает только соседей")
	assert_lt(g.hp, g.max_hp, "и союзника рядом")
	assert_eq(w.hp, w.max_hp, "но не самого волшебника")
	var w2 := A.at(CombatData.make_hero("wizard", 2, "evoker"), Vector2i(5, 5))
	var g2 := A.at(CombatData.make_companion("garret", 2), Vector2i(4, 5))
	g2.saves["con"] = -30
	var b2 := A.make([w2, g2, A.helpless("zombie", 1, Vector2i(6, 5), 99)])
	b2.use_ability(w2, "thunderwave", w2.cell)
	assert_eq(g2.hp, g2.max_hp, "«Ваяние заклинаний» бережёт союзников")


func test_life_drain() -> void:
	var w := CombatData.make_hero("wizard", 1)
	var z := A.helpless("zombie", 1, Vector2i(5, 0), 99)
	var b := A.make([w, z])
	w.hp = 1
	assert_true(b.use_ability(w, "life_drain", z.cell), "высасывание жизни")
	assert_true(z.hp < 99 and w.hp > 1, "урон и половина его — лечение")
	assert_eq(b.darkness, 2, "первый дар: +2 Тьмы")


# --- Спутники ---------------------------------------------------------------

func test_hallowed_ground() -> void:
	var ir := CombatData.make_companion("irena")
	var g := A.at(CombatData.make_companion("garret"), Vector2i(4, 4))
	var z := A.helpless("zombie", 1, Vector2i(5, 4), 99)
	var o := A.helpless("overseer", 1, Vector2i(4, 5), 99)
	var b := A.make([ir, g, z, o])
	g.hp = 1
	assert_true(b.use_ability(ir, "hallowed_ground", Vector2i(4, 4)), "освящённая земля")
	assert_gt(g.hp, 1, "лечит союзников в области")
	assert_true(z.hp < 99 and o.hp == 99, "жжёт только нежить")


func test_shield_of_faith() -> void:
	var ir := CombatData.make_companion("irena")
	var g := A.at(CombatData.make_companion("garret"), Vector2i(3, 0))
	var b := A.make([ir, g, A.at(CombatData.make_enemy("zombie", 1), Vector2i(9, 9))])
	var ac := b.ac_of(g)
	assert_true(b.use_ability(ir, "shield_of_faith", g.cell), "щит веры")
	assert_eq(b.ac_of(g), ac + 2, "+2 КД")
	assert_false(b.ability_targets(ir, "shield_of_faith").has(g.cell), "второй щит на того же нельзя")
	var c := CombatData.make_hero("cleric", 3, "life")
	Items.equip(c, ["forge_mace"])
	assert_eq(int(b.params_of(c, "shield_of_faith").ac), 3, "булава литейной: щит +3")


func test_trip() -> void:
	var g := CombatData.make_companion("garret")
	var z := A.helpless("zombie", 1, Vector2i(1, 0), 99)
	var b := A.make([g, z])
	assert_true(b.use_ability(g, "trip", z.cell), "подсечка")
	assert_true(z.hp < 99 and z.has_status("prone"), "удар и сбит с ног")
	assert_eq(g.uses_left("trip"), 1, "два раза за бой")
	assert_eq(b.attack_preview(g, z).adv, 1, "по лежащему вплотную — с преимуществом")


func test_taunt() -> void:
	var g := CombatData.make_companion("garret")
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(3, 0))
	var far := A.at(CombatData.make_enemy("zombie", 2), Vector2i(6, 0))
	var b := A.make([g, z, far])
	assert_true(b.use_ability(g, "taunt", g.cell), "провокация")
	assert_true(z.has_status("taunted") and not far.has_status("taunted"), "враги в 3 клетках")
	assert_eq(CombatAI._pick_target(b, z), g, "спровоцированный идёт к Гаррету")


func test_bomb() -> void:
	var v := CombatData.make_companion("velior")
	var g := A.at(CombatData.make_companion("garret"), Vector2i(4, 1))
	g.saves["dex"] = -30
	var z := A.helpless("zombie", 1, Vector2i(4, 0), 99)
	var b := A.make([v, g, z])
	assert_true(b.use_ability(v, "bomb", Vector2i(4, 0)), "бомба")
	assert_true(z.hp < 99 and g.hp < g.max_hp, "задевает всех в области, своих тоже")
	assert_eq(CombatData.make_companion("velior", 5).uses_left("bomb"), 2, "бомб две и с ростом уровня")
	assert_eq(CombatData.ability_dice("bomb", 5), "3d6", "с 5 уровня 3d6")


func test_trap() -> void:
	var v := CombatData.make_companion("velior")
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(5, 0))
	var b := A.make([v, z])
	assert_true(b.use_ability(v, "trap", Vector2i(3, 0)), "ловушка поставлена")
	assert_false(b.ability_targets(v, "trap").has(Vector2i(3, 0)), "на ловушку вторую не ставят")
	b.end_turn()
	assert_eq(b.current(), z, "ход зомби")
	b.move_along(z, b.path_to(z, Vector2i(2, 0), b.reachable(z)))
	assert_true(z.cell == Vector2i(3, 0) and z.hp < z.max_hp, "зомби застрял в ловушке")


# --- Воин -------------------------------------------------------------------

func test_action_surge() -> void:
	var f := A.at(CombatData.make_hero("fighter", 2, "guardian"), Vector2i(5, 4))
	var z := A.helpless("zombie", 1, Vector2i(6, 4), 99)
	var b := A.make([f, z])
	assert_false(b.can_use(f, "action_surge"), "всплеск только после потраченного действия")
	b.attack(f, z)
	assert_true(b.use_ability(f, "action_surge", f.cell), "всплеск действий")
	assert_true(not f.action_used and not f.bonus_used and f.uses_left("action_surge") == 0, "всплеск вернул действие, бонус цел")
	b.attack(f, z)
	assert_true(f.action_used and not b.can_use(f, "action_surge"), "второй всплеск за бой нельзя")


func test_rage() -> void:
	var f := A.at(CombatData.make_hero("fighter", 2, "berserker"), Vector2i(5, 5))
	var b := A.make([f, A.at(CombatData.make_enemy("overseer", 1), Vector2i(6, 5))])
	assert_true(b.use_ability(f, "rage", f.cell) and f.has_status("raging"), "ярость")
	assert_eq(b._mitigate(f, 10), 8, "в ярости урон от оружия меньше на 2")
	assert_false(b.can_use(f, "rage"), "второй раз не включить")
	var k := CombatData.make_hero("fighter", 2, "berserker")
	Items.equip(k, ["eshmur_cleaver"])
	b.add_status(k, "raging", k)
	assert_eq(b.mod_sum(k, "melee_dmg"), 2, "тесак Эшмура: ярость +2 к урону")


func test_reckless() -> void:
	var f := A.at(CombatData.make_hero("fighter", 4, "berserker"), Vector2i(5, 5))
	var o := A.at(CombatData.make_enemy("overseer", 1), Vector2i(6, 5))
	var b := A.make([f, o])
	assert_true(b.use_ability(f, "reckless", f.cell), "безрассудная атака")
	assert_eq(b.attack_preview(f, o).adv, 1, "свои удары с преимуществом")
	assert_eq(b.attack_preview(o, f).adv, 1, "и по нему тоже")
	b.attack(f, o)
	assert_false(b.can_use(f, "reckless"), "только до действия")


# --- Плут -------------------------------------------------------------------

func test_hide() -> void:
	var r := A.at(CombatData.make_hero("rogue", 2, "assassin"), Vector2i(0, 5))
	var a := A.at(CombatData.make_enemy("skeleton_archer", 1), Vector2i(7, 5))
	var b := A.make([r, a])
	b.obstacles[Vector2i(1, 5)] = true
	assert_false(b.seen_by_foes(r), "за стеной не видно")
	assert_true(b.use_ability(r, "hide", r.cell) and r.has_status("hidden"), "за стеной плут прячется наверняка")
	assert_false(b.use_ability(r, "disengage", r.cell), "отход и прятки делят одно бонусное действие")
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(1, 4))
	b.units.append(z)
	r.statuses.clear()
	r.bonus_used = false
	assert_false(b.can_use(r, "hide"), "рядом с врагом не спрятаться")


func test_poison_blade() -> void:
	var r := A.at(CombatData.make_hero("rogue", 3, "assassin"), Vector2i(5, 5))
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var b := A.make([r, z])
	assert_true(b.use_ability(r, "poison_blade", r.cell), "яд на клинок")
	assert_false(b.can_use(r, "poison_blade"), "второй слой не нанести")
	b.attack(r, z)
	assert_true(z.has_status("poisoned") and not r.has_status("poison_ready"), "попадание отравляет, яд потрачен")
	assert_eq(b.attack_preview(z, r).adv, -1, "отравленный атакует с помехой")
	var r2 := CombatData.make_hero("rogue", 3, "assassin")
	Items.equip(r2, ["archivist_fang"])
	assert_eq(r2.uses_left("poison_blade"), 4, "клык архивариуса: ещё один яд")


func test_shoot() -> void:
	var t := A.at(CombatData.make_hero("rogue", 2, "trickster"), Vector2i(0, 5))
	var a := A.at(CombatData.make_enemy("skeleton_archer", 1), Vector2i(7, 5))
	var b := A.make([t, a])
	b.add_status(t, "hidden", t)
	assert_true(b.ability_targets(t, "shoot").has(a.cell), "ловкач достаёт луком на 7 клеток")
	var p := b.attack_preview(t, a, "", t.ranged_weapon)
	assert_true(p.adv == 1 and p.max == 9 + 6, "из укрытия выстрел с преимуществом и скрытой атакой")
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(1, 5))
	b.units.append(z)
	assert_eq(b.ability_preview(t, "shoot", a.cell).adv, 0, "враг вплотную даёт помеху, скрытность — преимущество")
	var t2 := CombatData.make_hero("rogue", 2, "trickster")
	Items.equip(t2, ["silver_bow"])
	assert_true(t2.has_trait("bow_close"), "серебряный лук: без помехи вплотную")


func test_dash() -> void:
	var t := CombatData.make_hero("rogue", 4, "trickster")
	var b := A.make([t, A.at(CombatData.make_enemy("zombie", 1), Vector2i(9, 9))])
	assert_true(b.use_ability(t, "dash", t.cell), "рывок")
	assert_eq(t.speed_left, t.speed * 2, "движение удвоено")


func test_knife_fan() -> void:
	var t := A.at(CombatData.make_hero("rogue", 5, "trickster"), Vector2i(5, 5))
	var es: Array[Combatant] = []
	for i in 4:
		es.append(A.helpless("zombie", i + 1, Vector2i(7 + i % 2, 3 + i), 99))
	var b := A.make([t] + es)
	assert_eq(b.ability_area(t, "knife_fan", t.cell).size(), 3, "до трёх ближайших врагов")
	assert_true(b.use_ability(t, "knife_fan", t.cell), "веер кинжалов")
	var hit := es.filter(func(e: Combatant) -> bool: return e.hp < 99).size()
	assert_between(hit, 2, 3, "кинжалы летят в трёх")
	var t2 := CombatData.make_hero("rogue", 5, "trickster")
	t2.traits.append("fan_wide")
	assert_eq(int(b.params_of(t2, "knife_fan").count), 4, "Шёпот Ловкача: четыре кинжала")


# --- Жрец -------------------------------------------------------------------

func test_mass_healing_word() -> void:
	var c := CombatData.make_hero("cleric", 4, "life")
	var g := A.at(CombatData.make_companion("garret"), Vector2i(2, 0))
	var ir := A.at(CombatData.make_companion("irena"), Vector2i(3, 0))
	var b := A.make([c, g, ir, A.at(CombatData.make_enemy("zombie", 1), Vector2i(9, 9))])
	g.hp = 1
	var slots := c.slots
	assert_true(b.use_ability(c, "mass_healing_word", c.cell), "массовое слово")
	assert_true(g.hp >= 1 + 4 + 2 and ir.hp == ir.max_hp, "лечит раненых, «Ученик жизни» +2")
	assert_eq(c.slots, slots - 2, "ячейка 2 уровня")


func test_preserve_life() -> void:
	var c := CombatData.make_hero("cleric", 5, "life")
	var g := A.at(CombatData.make_companion("garret", 5), Vector2i(2, 0))
	var ir := A.at(CombatData.make_companion("irena", 5), Vector2i(3, 0))
	var b := A.make([c, g, ir, A.at(CombatData.make_enemy("zombie", 1), Vector2i(11, 11))])
	g.hp = 1
	ir.hp = 2
	assert_true(b.use_ability(c, "preserve_life", c.cell), "сохранение жизни")
	assert_true(g.hp == g.max_hp / 2 and ir.hp == ir.max_hp / 2, "каждого — до половины хитов")


func test_guiding_bolt() -> void:
	var c := CombatData.make_hero("cleric", 2, "light")
	var w := A.at(CombatData.make_hero("wizard", 1), Vector2i(0, 2))
	w.id = "w"
	var o := A.helpless("overseer", 1, Vector2i(4, 0), 99)
	var b := A.make([c, o, w])
	assert_true(b.use_ability(c, "guiding_bolt", o.cell), "направляющий снаряд")
	assert_true(o.hp < 99 and o.has_status("guided"), "попадание метит цель")
	assert_eq(b.attack_preview(w, o).adv, 1, "по меченой цели — преимущество")
	b._spell_attack(w, o, "1d4")
	assert_false(o.has_status("guided"), "метка снимается первой атакой")
	b.add_status(o, "guided", c)
	b.end_turn()
	b.end_turn()
	b.end_turn()
	assert_false(o.has_status("guided"), "метка кончается в начале хода жреца")


func test_turn_undead() -> void:
	var c := A.at(CombatData.make_hero("cleric", 3, "light"), Vector2i(5, 5))
	var z := A.helpless("zombie", 1, Vector2i(6, 5))
	var o := A.helpless("overseer", 1, Vector2i(4, 5))
	var b := A.make([c, z, o])
	assert_true(b.use_ability(c, "turn_undead", c.cell), "изгнание нежити")
	assert_true(z.has_status("turned") and not o.has_status("turned"), "бежит только нежить")
	b.end_turn()
	CombatAI.take_turn(b, z)
	assert_true(Battle.dist(z.cell, c.cell) > 1 and c.hp == c.max_hp, "изгнанный зомби убегает и не бьёт")
	b.deal_damage(z, 1, "test")
	assert_false(z.has_status("turned"), "урон снимает изгнание")
	var c2 := CombatData.make_hero("cleric", 3, "light")
	Items.equip(c2, ["warden_mace"])
	assert_eq(b.radius_of(c2, "turn_undead"), 3, "булава смотрителя: изгнание шире")


func test_spiritual_weapon() -> void:
	var c := CombatData.make_hero("cleric", 4, "light")
	var z := A.helpless("zombie", 1, Vector2i(4, 0), 99)
	var b := A.make([c, z])
	var slots := c.slots
	assert_true(b.use_ability(c, "spiritual_weapon", z.cell), "духовное оружие")
	assert_true(c.slots == slots - 1 and c.has_status("spirit_weapon"), "первый призыв стоит ячейку")
	c.bonus_used = false
	assert_true(b.use_ability(c, "spiritual_weapon", z.cell), "второй удар")
	assert_eq(c.slots, slots - 1, "дальше удары бесплатны")
	assert_lt(z.hp, 99, "оружие бьёт")


func test_spirit_guardians() -> void:
	var c := A.at(CombatData.make_hero("cleric", 5, "light"), Vector2i(5, 5))
	var z := A.helpless("zombie", 1, Vector2i(7, 5), 99)
	var far := A.helpless("zombie", 2, Vector2i(10, 5), 99)
	var b := A.make([c, z, far])
	assert_true(b.use_ability(c, "spirit_guardians", c.cell), "духовные стражи")
	assert_false(b.can_use(c, "spirit_guardians"), "вторые стражи не нужны")
	b.end_turn()
	assert_true(z.hp < 99 and far.hp == 99, "враг, начавший ход рядом, получает урон")


# --- Волшебник --------------------------------------------------------------

func test_scorching_ray() -> void:
	var w := CombatData.make_hero("wizard", 3, "evoker")
	var z := A.helpless("zombie", 1, Vector2i(4, 0), 2)
	var z2 := A.helpless("zombie", 2, Vector2i(5, 0), 99)
	var b := A.make([w, z, z2])
	assert_true(b.use_ability(w, "scorching_ray", z.cell), "палящий луч")
	assert_true(z.dead and z2.hp < 99, "лучи после убитой цели уходят в следующую")
	var w2 := CombatData.make_hero("wizard", 3, "evoker")
	Items.equip(w2, ["master_seal"])
	assert_eq(int(b.params_of(w2, "scorching_ray").repeat), 4, "печать мастера: четыре луча")


func test_fireball() -> void:
	var w := A.at(CombatData.make_hero("wizard", 5, "evoker"), Vector2i(0, 0))
	var g := A.at(CombatData.make_companion("garret", 5), Vector2i(6, 5))
	g.saves["dex"] = -30
	var z := A.helpless("zombie", 1, Vector2i(6, 6), 99)
	var b := A.make([w, g, z])
	assert_true(b.use_ability(w, "fireball", z.cell), "огненный шар")
	assert_true(z.hp <= 99 - 7, "7d6 по области")
	assert_eq(g.hp, g.max_hp, "Воплотитель не задевает своих")
	assert_false(b.can_use(w, "fireball"), "раз за бой")


func test_grease() -> void:
	var w := CombatData.make_hero("wizard", 2, "binder")
	var z := A.helpless("zombie", 1, Vector2i(6, 0))
	var z2 := A.helpless("zombie", 2, Vector2i(9, 0))
	var b := A.make([w, z, z2])
	assert_true(b.use_ability(w, "grease", Vector2i(6, 0)), "жир разлит")
	assert_true(z.has_status("prone") and b.zones.grease.has(Vector2i(7, 1)), "враг в жиру падает, зона остаётся")
	b.order = [w.id, z2.id, z.id]
	b.turn_index = 0
	b.end_turn()
	b.move_along(z2, b.path_to(z2, Vector2i(5, 0), b.reachable(z2)))
	assert_true(z2.has_status("prone") and z2.cell.x == 7, "входящий в жир падает и останавливается")


func test_spike_growth() -> void:
	var w := CombatData.make_hero("wizard", 3, "binder")
	var z := A.helpless("zombie", 1, Vector2i(8, 0), 99)
	var b := A.make([w, z])
	assert_true(b.use_ability(w, "spike_growth", Vector2i(5, 0)), "шипы выросли")
	b.end_turn()
	b.move_along(z, b.path_to(z, Vector2i(4, 0), b.reachable(z)))
	assert_lt(z.hp, 99, "шаги по шипам ранят")


func test_web() -> void:
	var w := CombatData.make_hero("wizard", 4, "binder")
	var z := A.helpless("zombie", 1, Vector2i(4, 6), 99)
	var b := A.make([w, z])
	assert_true(b.use_ability(w, "web", Vector2i(4, 6)) and z.has_status("restrained"), "паутина опутывает")
	assert_eq(b.attack_preview(w, z).adv, 1, "по опутанному — с преимуществом")
	b.end_turn()
	assert_eq(z.speed_left, 0, "опутанный не двигается")


func test_slow() -> void:
	var w := CombatData.make_hero("wizard", 5, "binder")
	var d := A.helpless("wight", 1, Vector2i(5, 0))
	var b := A.make([w, d])
	var ac := b.ac_of(d)
	assert_true(b.use_ability(w, "slow", d.cell) and d.has_status("slowed"), "замедление")
	assert_true(b.ac_of(d) == ac - 2 and not b.can_react(d), "замедленный: −2 КД и без атак при возможности")
	b.end_turn()
	assert_eq(d.speed_left, d.speed / 2, "вдвое медленнее")
	w.cell = Vector2i(4, 0)
	b.attack(d, w)
	assert_true(d.action_used, "один удар за действие вместо двух")
