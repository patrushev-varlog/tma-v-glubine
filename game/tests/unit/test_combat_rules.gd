extends GutTest
## Правила боя: перенесены из prototypes/combat/tests/run_tests.gd на данные (B7).
## Проверки отдельных умений — в test_abilities.gd, предметов — в test_items.gd.

const A := preload("res://tests/helpers/arena.gd")


func test_dice() -> void:
	var d := Dice.parse("2d6+3")
	assert_true(d.count == 2 and d.sides == 6 and d.bonus == 3, "parse 2d6+3")
	d = Dice.parse("d8-1")
	assert_true(d.count == 1 and d.sides == 8 and d.bonus == -1, "parse d8-1")
	assert_true(Dice.min_of("2d6+3") == 5 and Dice.max_of("2d6+3") == 15, "min/max 2d6+3")
	assert_almost_eq(Dice.avg_of("1d8+3"), 7.5, 0.001, "avg 1d8+3")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var ok := true
	for i in 500:
		var r := Dice.roll(rng, "1d6+2")
		if r < 3 or r > 8:
			ok = false
	assert_true(ok, "roll 1d6+2 в диапазоне")
	var crit_max := 0
	for i in 500:
		crit_max = maxi(crit_max, Dice.roll(rng, "1d6", true))
	assert_true(crit_max > 6 and crit_max <= 12, "крит удваивает кости")
	assert_eq(Dice.add("1d4", "1d4"), "2d4", "одинаковые кости складываются")
	assert_eq(Dice.add("1d4", "1d6"), "1d4+1d6", "разные кости идут через плюс")
	assert_true(Dice.max_of("1d4+1d6") == 10 and is_equal_approx(Dice.avg_of("1d4+1d6"), 6.0), "кости из двух групп")
	assert_eq(Dice.plus("1d10", 3), "1d10+3")


func test_hit_chance() -> void:
	assert_almost_eq(Dice.hit_chance(5, 15), 0.55, 0.001, "шанс +5 против КД 15")
	assert_almost_eq(Dice.hit_chance(5, 15, 1), 1.0 - 0.45 * 0.45, 0.001, "преимущество")
	assert_almost_eq(Dice.hit_chance(5, 15, -1), 0.55 * 0.55, 0.001, "помеха")
	assert_almost_eq(Dice.hit_chance(20, 5), 0.95, 0.001, "1 всегда промах")
	assert_almost_eq(Dice.hit_chance(-5, 30), 0.05, 0.001, "20 всегда попадание")


func test_setup_and_reachable() -> void:
	var h := A.at(CombatData.make_hero("fighter", 1), Vector2i(0, 0))
	var e := A.at(CombatData.make_enemy("zombie", 1), Vector2i(11, 11))
	var b := A.make([h, e])
	assert_true(b.current() == h and h.speed_left == 6, "ход героя, 6 клеток движения")
	var reach := b.reachable(h)
	assert_true(reach.has(Vector2i(6, 6)), "достаёт по диагонали на 6")
	assert_false(reach.has(Vector2i(7, 0)), "не достаёт на 7")


func test_obstacles_block() -> void:
	var h := A.at(CombatData.make_hero("fighter", 1), Vector2i(0, 1))
	var b := A.make([h])
	for y in 12:
		if y != 11:
			b.obstacles[Vector2i(1, y)] = true
	assert_false(b.reachable(h).has(Vector2i(2, 1)), "стена перекрывает путь")


func test_opportunity_attack() -> void:
	var h := A.at(CombatData.make_hero("wizard", 1), Vector2i(5, 5))
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(6, 5))
	var b := A.make([h, z])
	var path := b.path_to(h, Vector2i(2, 5), b.reachable(h))
	assert_eq(b.count_opportunity(h, path), 1, "прогноз: одна атака при возможности")
	b.move_along(h, path)
	assert_true(z.reaction_used, "зомби потратил реакцию")


func test_down_heal_and_defeat() -> void:
	var h := A.at(CombatData.make_hero("cleric", 1), Vector2i(1, 1))
	var g := A.at(CombatData.make_companion("garret", 1), Vector2i(2, 1))
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(10, 10))
	var b := A.make([h, g, z])
	b.deal_damage(g, 100, "test")
	assert_true(g.down and g.hp == 0 and b.outcome == "", "Гаррет выбыл, бой идёт")
	assert_true(g.has_status("prone"), "выбывший лежит")
	assert_true(b.use_ability(h, "healing_word", g.cell), "слово исцеления по выбывшему")
	assert_true(not g.down and g.hp > 0, "Гаррет снова в строю")
	b.deal_damage(g, 100, "test")
	b.deal_damage(h, 100, "test")
	assert_eq(b.outcome, "defeat", "все выбыли — поражение")


func test_victory() -> void:
	var h := CombatData.make_hero("fighter", 1)
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(5, 5))
	var b := A.make([h, z])
	b.deal_damage(z, 100, "test")
	assert_true(z.dead and b.outcome == "victory", "победа")


func test_story_scaling() -> void:
	var h := CombatData.make_hero("fighter", 1)
	var o := A.at(CombatData.make_enemy("overseer_chief", 1), Vector2i(1, 0))
	var b := A.make([o, h])
	var trial := b.attack_preview(o, h)
	b.difficulty = "story"
	var story := b.attack_preview(o, h)
	assert_lt(int(story.max), int(trial.max), "на «Истории» урон врагов ниже")


func test_darkness_cap() -> void:
	var h := CombatData.make_hero("wizard", 5)
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(3, 0))
	z.max_hp = 999
	z.hp = 999
	var b := A.make([h, z])
	var used := 0
	var slots := h.slots
	for i in 4:
		h.action_used = false
		if b.use_ability(h, "life_drain", z.cell):
			used += 1
	assert_true(b.darkness == 2 and b.darkness_gained == 2, "Тьму даёт только первый дар в бою: +2")
	assert_true(used == 3 and not b.can_use(h, "life_drain"), "не больше трёх тёмных даров за бой")
	assert_eq(h.slots, slots - 3, "дар волшебника тратит ячейку")
	assert_true(b.can_use(h, "fire_bolt"), "обычные заклинания после даров доступны")
	h.slots = 0
	b.dark_gifts_used = 0
	assert_false(b.can_use(h, "life_drain"), "без ячеек дар заклинателя недоступен")
	# Потолок боевой Тьмы за игру.
	var sc := CombatData.scenario("level_2", "wizard", "evoker", "full", "trial")
	sc["combat_darkness"] = 19
	var b2 := Battle.new()
	b2.setup(sc, 3, "trial")
	var w: Combatant = sc.units[0]
	b2.turn_index = b2.order.find(w.id)
	b2._start_turn()
	var t: Combatant = b2.enemies()[-1]
	t.cell = Vector2i(w.cell.x + 2, w.cell.y)
	assert_true(b2.use_ability(w, "life_drain", t.cell), "дар применён")
	assert_eq(b2.darkness_gained, 1, "боевая Тьма упирается в потолок 20 за игру")
	# Дар воина стоит хитов, но не ниже 1.
	var f := A.at(CombatData.make_hero("fighter", 3), Vector2i(5, 5))
	var e2 := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var b3 := A.make([f, e2])
	b3.use_ability(f, "cursed_blade", e2.cell)
	assert_true(A.logged(b3, "−6 хитов") and b3.darkness_gained == 2, "проклятый клинок стоит 6 хитов на 3 уровне")
	f.hp = 2
	assert_eq(b3.dark_hp_cost(f), 1, "дар не опускает ниже 1 хита")


func test_darkness_stages() -> void:
	assert_eq(Battle.darkness_stage(0), "shadow")
	assert_eq(Battle.darkness_stage(24), "shadow")
	assert_eq(Battle.darkness_stage(25), "dusk")
	assert_eq(Battle.darkness_stage(50), "gloom")
	assert_eq(Battle.darkness_stage(100), "abyss")


func test_trial_enemies_pick_fragile() -> void:
	var w := A.at(CombatData.make_hero("wizard", 1), Vector2i(6, 0))
	var g := A.at(CombatData.make_companion("garret", 1), Vector2i(3, 0))
	var o := A.at(CombatData.make_enemy("overseer", 1), Vector2i(4, 0))
	var b := A.make([g, w, o])
	b.difficulty = "trial"
	o.speed_left = o.speed
	assert_eq(CombatAI._pick_target(b, o), w, "на «Испытании» враг идёт к хрупкому волшебнику")
	b.difficulty = "story"
	assert_eq(CombatAI._pick_target(b, o), g, "на «Истории» враг бьёт ближайшего")


func test_line_of_sight_and_range() -> void:
	var a := A.at(CombatData.make_enemy("skeleton_archer", 1), Vector2i(0, 5))
	var w := A.at(CombatData.make_hero("wizard", 1), Vector2i(6, 5))
	var b := A.make([a, w])
	assert_true(b.in_weapon_range(a, w), "лучник стреляет на 6 клеток по открытому полю")
	b.obstacles[Vector2i(3, 5)] = true
	assert_false(b.in_weapon_range(a, w), "стена между лучником и целью перекрывает выстрел")
	assert_false(b.ability_targets(w, "fire_bolt").has(a.cell), "стена перекрывает и заклинание")
	b.obstacles.erase(Vector2i(3, 5))
	b.obstacles[Vector2i(3, 6)] = true
	assert_true(b.in_weapon_range(a, w), "стена сбоку от линии выстрела не мешает")
	w.cell = Vector2i(9, 5)
	assert_false(b.in_weapon_range(a, w), "дальше 8 клеток лук не достаёт")


func test_battle_maps() -> void:
	for level in range(1, 6):
		var bid := "level_%d" % level
		var trial := Battle.new()
		trial.setup(CombatData.scenario(bid, "wizard", "", "full", "trial"), 1, "trial")
		var story := Battle.new()
		story.setup(CombatData.scenario(bid, "wizard", "", "full", "story"), 1, "story")
		assert_true(trial.width == 18 and trial.height == 14, "бой %d: поле 18×14" % level)
		assert_lt(story.enemies().size(), trial.enemies().size(), "бой %d: на «Истории» врагов меньше" % level)
		var walk := trial.walk_distances(Vector2i(0, 6))
		var all_reachable := true
		for e in trial.enemies():
			var near := false
			for c in trial.cells_in_radius(e.cell, 1):
				if walk.has(c):
					near = true
			all_reachable = all_reachable and near
		assert_true(all_reachable, "бой %d: до каждого врага есть проход" % level)
		var hero: Combatant = trial.units.filter(func(u: Combatant) -> bool: return u.is_hero)[0]
		assert_eq(hero.level, level, "бой %d: герой того же уровня" % level)


func test_levels_and_branches() -> void:
	var classes := CombatData.table("classes")
	for cls in CombatData.class_ids():
		var base := CombatData.make_hero(cls, 1)
		assert_eq(base.archetype, "", "%s 1 уровня без ветки" % cls)
		for arch in CombatData.archetypes_of(cls):
			var gains: Dictionary = classes[cls].archetypes[arch].levels
			for lv in range(2, 6):
				var h := CombatData.make_hero(cls, lv, arch)
				var have := 0
				for gl in gains:
					if h.abilities.has(gains[gl]) or h.has_trait(gains[gl]):
						have += 1
				assert_eq(have, lv - 1, "%s/%s %d уровня: %d умений ветки" % [cls, arch, lv, lv - 1])
				for aid in base.abilities:
					assert_true(h.abilities.has(aid), "%s/%s %d уровня сохраняет %s" % [cls, arch, lv, aid])
	assert_gt(CombatData.make_hero("wizard", 5).max_slots, CombatData.make_hero("wizard", 1).max_slots, "с уровнем больше ячеек")
	assert_gt(CombatData.make_hero("fighter", 5).max_hp, CombatData.make_hero("fighter", 1).max_hp, "с уровнем больше хитов")
	assert_eq(CombatData.ability_dice("fire_bolt", 5), "2d10", "заговор усиливается на 5 уровне")
	assert_eq(CombatData.make_hero("fighter", 5).max_hp, 13 + 6 * 4, "воин 5 уровня: 13 + 6 за уровень")
	for cls in CombatData.class_ids():
		var h := CombatData.make_hero(cls, 1)
		assert_true(h.abilities.has("dodge") and h.abilities.has("shove"), "у героя-%s есть уклонение и толчок" % cls)
	assert_true(CombatData.make_companion("irena").abilities.has("dodge"), "у спутников тоже есть уклонение")


func test_hold_the_line() -> void:
	var g := A.at(CombatData.make_companion("garret"), Vector2i(5, 5))
	var z := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var b := A.make([z, g])
	b.move_along(z, b.path_to(z, Vector2i(9, 5), b.reachable(z)))
	assert_true(z.cell == Vector2i(6, 5) and z.speed_left == 0, "Гаррет удерживает проход")


func test_hidden_expiry_and_targeting() -> void:
	var r := A.at(CombatData.make_hero("rogue", 2, "assassin"), Vector2i(0, 5))
	var w2 := A.at(CombatData.make_hero("wizard", 1), Vector2i(0, 9))
	w2.id = "w2"
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(5, 5))
	var b := A.make([r, z, w2])
	b.add_status(r, "hidden", r)
	assert_eq(CombatAI._pick_target(b, z), w2, "враг идёт не к спрятавшемуся плуту")
	b.difficulty = "story"
	assert_eq(CombatAI._pick_target(b, z), w2, "и на «Истории» тоже")
	b.difficulty = "trial"
	b.end_turn()
	assert_true(r.has_status("hidden"), "скрытность держится в ходы врагов")
	b.end_turn()
	b.end_turn()
	assert_true(r.has_status("hidden") and b.current() == r, "в начале своего хода ещё скрыт")
	b.end_turn()
	assert_false(r.has_status("hidden"), "не атаковал и не спрятался снова — скрытность спала")
	b = A.make([r, z])
	b.add_status(r, "hidden", r)
	CombatAI.take_turn(b, z)
	assert_eq(r.hp, r.max_hp, "если все спрятались, враг никого не бьёт")
	r.cell = Vector2i(4, 5)
	b.end_turn()
	assert_false(r.has_status("hidden"), "вплотную к врагу скрытность спадает")


func test_taunt_forces_archers() -> void:
	var g := A.at(CombatData.make_companion("garret"), Vector2i(2, 3))
	var w := A.at(CombatData.make_hero("wizard", 1), Vector2i(6, 3))
	var a := A.at(CombatData.make_enemy("skeleton_archer", 1), Vector2i(4, 1))
	var b := A.make([a, g, w])
	assert_eq(CombatAI._pick_target(b, a), w, "без провокации лучник целит в волшебника")
	b.add_status(a, "taunted", g)
	var from := b.events.size()
	CombatAI.take_turn(b, a)
	var at_g := false
	var at_w := false
	for i in range(from, b.events.size()):
		var e: Dictionary = b.events[i]
		if e.get("type") in ["damage", "miss"]:
			at_g = at_g or e.unit == g.id
			at_w = at_w or e.unit == w.id
	assert_true(at_g and not at_w and w.hp == w.max_hp, "спровоцированный лучник стреляет в Гаррета")


func test_stun_ends_on_down() -> void:
	var c := A.at(CombatData.make_hero("cleric", 1), Vector2i(1, 1))
	var c2 := A.at(CombatData.make_hero("cleric", 1), Vector2i(2, 1))
	c2.id = "c2"
	var b := A.make([c, c2, CombatData.make_enemy("zombie", 2)])
	b.add_status(c2, "stunned", null)
	b.deal_damage(c2, 100, "test")
	assert_true(c2.down and not c2.has_status("stunned"), "выбывший больше не парализован")
	b.use_ability(c, "healing_word", c2.cell)
	assert_true(not c2.down and not c2.has_status("stunned"), "поднятый герой походит как обычно")


func test_ghoul_claws_stun() -> void:
	var g := A.at(CombatData.make_enemy("ghoul", 1), Vector2i(5, 5))
	g.weapon.to_hit = 99
	var f := A.at(CombatData.make_hero("fighter", 1), Vector2i(6, 5))
	f.max_hp = 999
	f.hp = 999
	f.saves["con"] = -30
	var b := A.make([g, f])
	b.attack(g, f)
	assert_true(f.has_status("stunned"), "когти упыря парализуют при проваленном спасброске")
	b.end_turn()
	assert_true(f.action_used and f.speed_left == 0 and not f.has_status("stunned"), "парализованный пропускает ход")


func test_shove_replaces_one_attack() -> void:
	var g5 := A.at(CombatData.make_companion("garret", 5), Vector2i(5, 5))
	var e1 := A.helpless("zombie", 1, Vector2i(6, 5), 99)
	var b := A.make([g5, e1])
	b.attack(g5, e1)
	assert_true(not g5.action_used and b.can_use(g5, "shove"), "после первого удара Гаррет может толкнуть")
	assert_true(b.use_ability(g5, "shove", e1.cell) and g5.action_used, "толчок съел второй удар")
	assert_false(b.can_use(g5, "dodge"), "после действия «Атака» уклониться нельзя")


func test_rage_damage_bonus() -> void:
	var f := A.at(CombatData.make_hero("fighter", 2, "berserker"), Vector2i(5, 5))
	var z := A.at(CombatData.make_enemy("zombie", 1), Vector2i(6, 5))
	var b := A.make([f, z])
	b.add_status(f, "raging", f)
	assert_eq(b._flat_bonus(f, z, false), 1, "ярость: +1 к урону в ближнем бою")
	assert_eq(b._flat_bonus(f, z, true), 0, "в дальнем бою ярость не прибавляет")


func test_save_roundtrip() -> void:
	var b := Battle.new()
	b.setup(CombatData.scenario("level_3", "rogue", "assassin", "full", "story"), 42, "story")
	CombatAI.take_turn(b, b.current())
	b.end_turn()
	b.zones.grease[Vector2i(3, 3)] = 13
	b.zones.spikes[Vector2i(4, 4)] = "2d4"
	b.zones.trap[Vector2i(5, 5)] = {"src": "velior", "dice": "2d6"}
	b.add_status(b.units[0], "guided", b.units[1])
	b.add_status(b.units[1], "slowed", b.units[0], 13)
	b.units[0].counters["rally"] = 1
	var text1 := JSON.stringify(b.to_dict())
	var b2 := Battle.from_dict(JSON.parse_string(text1))
	var text2 := JSON.stringify(b2.to_dict())
	assert_eq(text2, text1, "сохранение и загрузка дают то же состояние")
	assert_eq(b2.rng.randi(), b.rng.randi(), "генератор случайных чисел продолжается одинаково")
	# Бой после загрузки идёт так же, как исходный.
	for i in 6:
		for bb in [b, b2]:
			CombatAI.take_turn(bb, bb.current())
			bb.end_turn()
	assert_eq(JSON.stringify(b2.to_dict()), JSON.stringify(b.to_dict()), "загруженный бой продолжается так же")


func test_party_scaling() -> void:
	var full := CombatData.scenario("level_5", "wizard", "evoker", "full", "trial", "none")
	var duo := CombatData.scenario("level_5", "wizard", "evoker", "duo", "trial", "none")
	var trio := CombatData.scenario("level_5", "wizard", "evoker", "no_velior", "trial", "none")
	var count := func(sc: Dictionary, team: int) -> int:
		return sc.units.filter(func(u: Combatant) -> bool: return u.team == team).size()
	assert_true(count.call(full, 0) == 4 and count.call(trio, 0) == 3 and count.call(duo, 0) == 2, "составы отряда 4, 3 и 2")
	assert_eq(count.call(CombatData.scenario("level_1", "wizard", "", "full", "trial"), 0), 3, "в прологе Велиора ещё нет")
	assert_true(count.call(trio, 1) < count.call(full, 1) and count.call(duo, 1) <= count.call(trio, 1), "врагов меньше под неполный отряд")
	var golem_hp := func(sc: Dictionary) -> int:
		for u in sc.units:
			if u.kind == "flesh_golem":
				return u.max_hp
		return 0
	assert_true(golem_hp.call(duo) < golem_hp.call(trio) and golem_hp.call(trio) < golem_hp.call(full), "босс остаётся, но слабее")
	CombatData.hunt_done = true
	var hunt := CombatData.scenario("level_5", "wizard", "evoker", "full", "trial", "none")
	CombatData.hunt_done = false
	assert_gt(golem_hp.call(hunt), golem_hp.call(full), "после охоты у врагов больше хитов")


func test_simulation_terminates() -> void:
	var ok := true
	var parties: Array = CombatData.rules().parties
	for cls in CombatData.class_ids():
		for level in range(1, 6):
			var arch: String = CombatData.archetypes_of(cls)[level % 2]
			var r := Simulator.run_battle("level_%d" % level, cls, arch, parties[level % parties.size()], "trial",
				level, level % 3 == 0)
			if r.outcome == "timeout":
				ok = false
	assert_true(ok, "симулированные бои заканчиваются")
