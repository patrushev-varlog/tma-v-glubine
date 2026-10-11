extends SceneTree
## Тесты правил боя. Запуск:
## godot --headless --path prototypes/combat -s res://tests/run_tests.gd

var passed := 0
var failed := 0


func _init() -> void:
	test_dice()
	test_hit_chance()
	test_setup_and_reachable()
	test_obstacles_block()
	test_opportunity_attack()
	test_disengage()
	test_down_heal_and_defeat()
	test_victory()
	test_story_scaling()
	test_darkness_cap()
	test_trial_enemies_pick_fragile()
	test_line_of_sight_and_range()
	test_battle_maps()
	test_levels_and_branches()
	test_trap()
	test_basic_actions()
	test_shove()
	test_fighter_surge_and_cleave()
	test_rogue_hide_and_bow()
	test_turn_undead()
	test_guiding_bolt_and_ray()
	test_grease()
	test_hold_the_line()
	test_rage_and_relentless()
	test_spikes_and_web()
	test_slow()
	test_shadow_step()
	test_save_roundtrip()
	test_simulation_terminates()
	print("Тесты: прошло %d, упало %d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func check(cond: bool, what: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + what)
		print("FAIL: " + what)


## Пустое поле 12×12 с заданными участниками; ход у первого из них.
func arena(list: Array) -> Battle:
	var b := Battle.new()
	var units: Array[Combatant] = []
	for u in list:
		units.append(u)
	b.setup({"width": 12, "height": 12, "units": units, "obstacles": []}, 7, "trial")
	b.order.clear()
	for u in units:
		b.order.append(u.id)
	b.turn_index = 0
	b._start_turn()
	return b


func test_dice() -> void:
	var d := Dice.parse("2d6+3")
	check(d.count == 2 and d.sides == 6 and d.bonus == 3, "parse 2d6+3")
	d = Dice.parse("d8-1")
	check(d.count == 1 and d.sides == 8 and d.bonus == -1, "parse d8-1")
	check(Dice.min_of("2d6+3") == 5 and Dice.max_of("2d6+3") == 15, "min/max 2d6+3")
	check(is_equal_approx(Dice.avg_of("1d8+3"), 7.5), "avg 1d8+3")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var ok := true
	for i in 500:
		var r := Dice.roll(rng, "1d6+2")
		if r < 3 or r > 8:
			ok = false
	check(ok, "roll 1d6+2 в диапазоне")
	var crit_max := 0
	for i in 500:
		crit_max = maxi(crit_max, Dice.roll(rng, "1d6", true))
	check(crit_max > 6 and crit_max <= 12, "крит удваивает кости")


func test_hit_chance() -> void:
	check(is_equal_approx(Dice.hit_chance(5, 15), 0.55), "шанс +5 против КД 15")
	check(is_equal_approx(Dice.hit_chance(5, 15, 1), 1.0 - 0.45 * 0.45), "преимущество")
	check(is_equal_approx(Dice.hit_chance(5, 15, -1), 0.55 * 0.55), "помеха")
	check(is_equal_approx(Dice.hit_chance(20, 5), 0.95), "1 всегда промах")
	check(is_equal_approx(Dice.hit_chance(-5, 30), 0.05), "20 всегда попадание")


func test_setup_and_reachable() -> void:
	var h := Content.make_hero("fighter")
	h.cell = Vector2i(0, 0)
	var e := Content.make_enemy("zombie", 1)
	e.cell = Vector2i(11, 11)
	var b := arena([h, e])
	check(b.current() == h and h.speed_left == 6, "ход героя, 6 клеток движения")
	var reach := b.reachable(h)
	check(reach.has(Vector2i(6, 6)), "достаёт по диагонали на 6")
	check(not reach.has(Vector2i(7, 0)), "не достаёт на 7")


func test_obstacles_block() -> void:
	var h := Content.make_hero("fighter")
	h.cell = Vector2i(0, 1)
	var b := arena([h])
	for y in 12:
		if y != 11:
			b.obstacles[Vector2i(1, y)] = true
	var reach := b.reachable(h)
	check(not reach.has(Vector2i(2, 1)), "стена перекрывает путь")


func test_opportunity_attack() -> void:
	var h := Content.make_hero("wizard")
	h.cell = Vector2i(5, 5)
	var z := Content.make_enemy("zombie", 1)
	z.cell = Vector2i(6, 5)
	var b := arena([h, z])
	var reach := b.reachable(h)
	var path := b.path_to(h, Vector2i(2, 5), reach)
	check(b.count_opportunity(h, path) == 1, "прогноз: одна атака при возможности")
	b.move_along(h, path)
	check(z.reaction_used, "зомби потратил реакцию")


func test_disengage() -> void:
	var h := Content.make_hero("rogue")
	h.cell = Vector2i(5, 5)
	var z := Content.make_enemy("zombie", 1)
	z.cell = Vector2i(6, 5)
	var b := arena([h, z])
	check(b.use_ability(h, "disengage", h.cell), "отход сработал")
	var path := b.path_to(h, Vector2i(2, 5), b.reachable(h))
	b.move_along(h, path)
	check(not z.reaction_used and h.cell == Vector2i(2, 5), "после отхода атаки нет")


func test_down_heal_and_defeat() -> void:
	var h := Content.make_hero("cleric")
	h.cell = Vector2i(1, 1)
	var g := Content.make_companion("garret")
	g.cell = Vector2i(2, 1)
	var z := Content.make_enemy("zombie", 1)
	z.cell = Vector2i(10, 10)
	var b := arena([h, g, z])
	b.deal_damage(g, 100, "test")
	check(g.down and g.hp == 0 and b.outcome == "", "Гаррет выбыл, бой идёт")
	check(b.use_ability(h, "healing_word", g.cell), "слово исцеления по выбывшему")
	check(not g.down and g.hp > 0, "Гаррет снова в строю")
	b.deal_damage(g, 100, "test")
	b.deal_damage(h, 100, "test")
	check(b.outcome == "defeat", "все выбыли — поражение")


func test_victory() -> void:
	var h := Content.make_hero("fighter")
	var z := Content.make_enemy("zombie", 1)
	z.cell = Vector2i(5, 5)
	var b := arena([h, z])
	b.deal_damage(z, 100, "test")
	check(z.dead and b.outcome == "victory", "победа")


func test_story_scaling() -> void:
	var h := Content.make_hero("fighter")
	var o := Content.make_enemy("overseer_chief", 1)
	o.cell = Vector2i(1, 0)
	var b := arena([o, h])
	var trial := b.attack_preview(o, h)
	b.difficulty = "story"
	var story := b.attack_preview(o, h)
	check(story.max < trial.max, "на «Истории» урон врагов ниже")


func test_darkness_cap() -> void:
	var h := Content.make_hero("wizard")
	var z := Content.make_enemy("zombie", 1)
	z.cell = Vector2i(3, 0)
	z.max_hp = 999
	z.hp = 999
	var b := arena([h, z])
	var used := 0
	for i in 4:
		h.action_used = false
		if b.use_ability(h, "life_drain", z.cell):
			used += 1
	check(b.darkness == 6 and b.darkness_gained == 6, "за бой не больше 6 Тьмы")
	check(used == 3 and not b.can_use(h, "life_drain"), "не больше трёх тёмных даров за бой")
	check(b.can_use(h, "fire_bolt"), "обычные заклинания после даров доступны")


func test_trial_enemies_pick_fragile() -> void:
	var w := Content.make_hero("wizard")
	var g := Content.make_companion("garret")
	var o := Content.make_enemy("overseer", 1)
	o.cell = Vector2i(4, 0)
	g.cell = Vector2i(3, 0)
	w.cell = Vector2i(6, 0)
	var b := arena([g, w, o])
	b.difficulty = "trial"
	o.speed_left = o.speed
	check(CombatAI._pick_target(b, o) == w, "на «Испытании» враг идёт к хрупкому волшебнику")
	b.difficulty = "story"
	check(CombatAI._pick_target(b, o) == g, "на «Истории» враг бьёт ближайшего")


func test_line_of_sight_and_range() -> void:
	var a := Content.make_enemy("skeleton_archer", 1)
	var w := Content.make_hero("wizard")
	a.cell = Vector2i(0, 5)
	w.cell = Vector2i(6, 5)
	var b := arena([a, w])
	check(b.in_weapon_range(a, w), "лучник стреляет на 6 клеток по открытому полю")
	b.obstacles[Vector2i(3, 5)] = true
	check(not b.in_weapon_range(a, w), "стена между лучником и целью перекрывает выстрел")
	check(not b.ability_targets(w, "fire_bolt").has(a.cell), "стена перекрывает и заклинание")
	b.obstacles.erase(Vector2i(3, 5))
	b.obstacles[Vector2i(3, 6)] = true
	check(b.in_weapon_range(a, w), "стена сбоку от линии выстрела не мешает")
	w.cell = Vector2i(9, 5)
	check(not b.in_weapon_range(a, w), "дальше 8 клеток лук не достаёт")


func test_battle_maps() -> void:
	for level in range(1, 6):
		var trial := Battle.new()
		trial.setup(Content.scenario(level, "wizard", "", false, "trial"), 1, "trial")
		var story := Battle.new()
		story.setup(Content.scenario(level, "wizard", "", false, "story"), 1, "story")
		check(trial.width == 18 and trial.height == 14, "бой %d: поле 18×14" % level)
		check(story.enemies().size() < trial.enemies().size(), "бой %d: на «Истории» врагов меньше" % level)
		var walk := trial.walk_distances(Vector2i(0, 6))
		var all_reachable := true
		for e in trial.enemies():
			var near := false
			for c in trial.cells_in_radius(e.cell, 1):
				if walk.has(c):
					near = true
			all_reachable = all_reachable and near
		check(all_reachable, "бой %d: до каждого врага есть проход" % level)
		check(trial.units.filter(func(u: Combatant) -> bool: return u.is_hero)[0].level == level,
			"бой %d: герой того же уровня" % level)


func test_levels_and_branches() -> void:
	for cls in Content.HERO_CLASSES:
		var base := Content.make_hero(cls, 1)
		check(base.archetype == "", "%s 1 уровня без ветки" % cls)
		for arch in Content.archetypes_of(cls):
			var gains: Dictionary = Content.HERO_CLASSES[cls].archetypes[arch].levels
			for lv in range(2, 6):
				var h := Content.make_hero(cls, lv, arch)
				var have := 0
				for gl in gains:
					if h.abilities.has(gains[gl]) or h.has_trait(gains[gl]):
						have += 1
				check(have == lv - 1, "%s/%s %d уровня: %d умений ветки" % [cls, arch, lv, lv - 1])
				for aid in base.abilities:
					check(h.abilities.has(aid), "%s/%s %d уровня сохраняет %s" % [cls, arch, lv, aid])
	check(Content.make_hero("wizard", 5).max_slots > Content.make_hero("wizard", 1).max_slots, "с уровнем больше ячеек")
	check(Content.make_hero("fighter", 5).max_hp > Content.make_hero("fighter", 1).max_hp, "с уровнем больше хитов")
	check(Content.ability_dice("fire_bolt", 5) == "2d10", "заговор усиливается на 5 уровне")


func test_trap() -> void:
	var v := Content.make_companion("velior")
	v.cell = Vector2i(0, 0)
	var z := Content.make_enemy("zombie", 1)
	z.cell = Vector2i(5, 0)
	var b := arena([v, z])
	check(b.use_ability(v, "trap", Vector2i(3, 0)), "ловушка поставлена")
	b.end_turn()
	check(b.current() == z, "ход зомби")
	var path := b.path_to(z, Vector2i(2, 0), b.reachable(z))
	b.move_along(z, path)
	check(z.cell == Vector2i(3, 0) and z.hp < z.max_hp, "зомби застрял в ловушке")


## Враг, который никогда не проходит спасброски и по которому не промахнуться (кроме 1 на кубике).
func helpless(kind: String, idx: int, cell: Vector2i) -> Combatant:
	var e := Content.make_enemy(kind, idx)
	e.cell = cell
	e.ac = -50
	for k in ["str", "dex", "con", "wis"]:
		e.saves[k] = -30
	return e


func test_basic_actions() -> void:
	for cls in Content.HERO_CLASSES:
		var h := Content.make_hero(cls)
		check(h.abilities.has("dodge") and h.abilities.has("shove"), "у героя-%s есть уклонение и толчок" % cls)
	check(Content.make_companion("irena").abilities.has("dodge"), "у спутников тоже есть уклонение")
	var h2 := Content.make_hero("wizard")
	var o := Content.make_enemy("overseer", 1)
	o.cell = Vector2i(1, 0)
	var b := arena([h2, o])
	check(b.use_ability(h2, "dodge", h2.cell), "уклонение сработало")
	check(b.attack_preview(o, h2).adv == -1, "по уклоняющемуся атаки с помехой")
	b.end_turn()
	b.end_turn()
	check(not h2.dodging, "уклонение кончается в начале своего хода")


func test_shove() -> void:
	var f := Content.make_hero("fighter")
	f.cell = Vector2i(2, 2)
	var v := Content.make_companion("velior")
	v.cell = Vector2i(9, 9)
	var z := helpless("zombie", 1, Vector2i(3, 2))
	var b := arena([f, v, z])
	b.traps[Vector2i(4, 2)] = v.id
	check(b.use_ability(f, "shove", z.cell), "толчок применён")
	check(z.cell == Vector2i(4, 2) and z.hp < z.max_hp and not b.traps.has(Vector2i(4, 2)), "толчок в ловушку")
	b.obstacles[Vector2i(5, 2)] = true
	f.cell = Vector2i(3, 2)
	f.action_used = false
	b.use_ability(f, "shove", z.cell)
	check(z.cell == Vector2i(4, 2) and z.prone, "у стены враг не отлетает, а падает")


func test_fighter_surge_and_cleave() -> void:
	var f := Content.make_hero("fighter", 3, "berserker")
	f.cell = Vector2i(5, 5)
	var z1 := helpless("zombie", 1, Vector2i(6, 5))
	var z2 := helpless("zombie", 2, Vector2i(6, 6))
	z1.max_hp = 99
	z1.hp = 99
	z2.max_hp = 99
	z2.hp = 99
	var b := arena([f, z1, z2])
	check(not b.can_use(f, "action_surge"), "всплеск только после потраченного действия")
	b.attack(f, z1)
	check(f.cleave_used and z2.hp < 99, "рассечение задевает второго врага рядом")
	f = Content.make_hero("fighter", 2, "guardian")
	f.cell = Vector2i(5, 4)
	b = arena([f, z1])
	check(not b.can_use(f, "action_surge"), "всплеск только после потраченного действия")
	b.attack(f, z1)
	check(b.can_use(f, "action_surge") and b.use_ability(f, "action_surge", f.cell), "всплеск действий")
	check(not f.action_used and not f.bonus_used and f.uses_left("action_surge") == 0, "всплеск вернул действие, бонус цел")
	b.attack(f, z1)
	check(f.action_used and not b.can_use(f, "action_surge"), "второй всплеск за бой нельзя")


func test_rogue_hide_and_bow() -> void:
	var r := Content.make_hero("rogue", 2, "assassin")
	r.cell = Vector2i(0, 5)
	var a := Content.make_enemy("skeleton_archer", 1)
	a.cell = Vector2i(7, 5)
	var b := arena([r, a])
	b.obstacles[Vector2i(1, 5)] = true
	check(not b.seen_by_foes(r) and b.use_ability(r, "hide", r.cell) and r.hidden, "за стеной плут прячется наверняка")
	check(b.use_ability(r, "disengage", r.cell) == false, "отход и прятки делят одно бонусное действие")
	var t := Content.make_hero("rogue", 2, "trickster")
	t.cell = Vector2i(0, 5)
	t.hidden = true
	b = arena([t, a])
	check(b.ability_targets(t, "shoot").has(a.cell), "ловкач достаёт луком на 7 клеток")
	var p := b.attack_preview(t, a, "", t.ranged_weapon)
	check(p.adv == 1 and p.max == 9 + 6, "из укрытия выстрел с преимуществом и скрытой атакой")
	var z := Content.make_enemy("zombie", 1)
	z.cell = Vector2i(1, 4)
	b.units.append(z)
	b.obstacles.erase(Vector2i(1, 5))
	r.hidden = false
	r.bonus_used = false
	check(not b.can_use(r, "hide"), "рядом с врагом не спрятаться")


func test_turn_undead() -> void:
	var c := Content.make_hero("cleric", 3, "light")
	c.cell = Vector2i(5, 5)
	var z := helpless("zombie", 1, Vector2i(6, 5))
	var o := helpless("overseer", 1, Vector2i(4, 5))
	var b := arena([c, z, o])
	check(b.use_ability(c, "turn_undead", c.cell), "изгнание нежити")
	check(z.turned and not o.turned, "бежит только нежить")
	b.end_turn()
	CombatAI.take_turn(b, z)
	check(Battle.dist(z.cell, c.cell) > 1 and c.hp == c.max_hp, "изгнанный зомби убегает и не бьёт")
	b.deal_damage(z, 1, "test")
	check(not z.turned, "урон снимает изгнание")


func test_guiding_bolt_and_ray() -> void:
	var c := Content.make_hero("cleric", 2, "light")
	var w := Content.make_hero("wizard")
	var o := Content.make_enemy("overseer", 1)
	o.cell = Vector2i(4, 0)
	w.cell = Vector2i(0, 2)
	var b := arena([c, o, w])
	o.guided_by = c.id
	check(b.attack_preview(w, o).adv == 1, "по меченой цели — преимущество")
	b._spell_attack(w, o, "1d4")
	check(o.guided_by == "", "метка снимается первой атакой")
	o.guided_by = c.id
	o.slowed_by = w.id
	b.end_turn()
	check(b.current() == o and o.speed_left == o.speed - 2, "луч холода отнимает 2 клетки")
	b.end_turn()
	check(o.slowed_by == "", "замедление кончается в начале хода волшебника")
	b.end_turn()
	check(o.guided_by == "", "метка кончается в начале хода жреца")


func test_grease() -> void:
	var w := Content.make_hero("wizard", 2, "binder")
	var z := helpless("zombie", 1, Vector2i(6, 0))
	var z2 := helpless("zombie", 2, Vector2i(9, 0))
	var b := arena([w, z, z2])
	check(b.use_ability(w, "grease", Vector2i(6, 0)), "жир разлит")
	check(z.prone and b.grease.has(Vector2i(7, 1)), "враг в жиру падает, зона остаётся")
	b.order = [w.id, z2.id, z.id]
	b.turn_index = 0
	b.end_turn()
	b.move_along(z2, b.path_to(z2, Vector2i(5, 0), b.reachable(z2)))
	check(z2.prone and z2.cell == Vector2i(7, 0), "входящий в жир падает и останавливается")


func test_hold_the_line() -> void:
	var g := Content.make_companion("garret")
	g.cell = Vector2i(5, 5)
	var z := helpless("zombie", 1, Vector2i(6, 5))
	z.max_hp = 99
	z.hp = 99
	var b := arena([z, g])
	b.move_along(z, b.path_to(z, Vector2i(9, 5), b.reachable(z)))
	check(z.cell == Vector2i(6, 5) and z.speed_left == 0, "Гаррет удерживает проход")


func test_save_roundtrip() -> void:
	var b := Battle.new()
	b.setup(Content.scenario(3, "rogue", "assassin", true, "story"), 42, "story")
	CombatAI.take_turn(b, b.current())
	b.end_turn()
	b.grease[Vector2i(3, 3)] = 13
	b.spikes[Vector2i(4, 4)] = "2d4"
	b.units[0].guided_by = "x"
	b.units[1].turned = true
	var text1 := JSON.stringify(b.to_dict())
	var b2 := Battle.from_dict(JSON.parse_string(text1))
	var text2 := JSON.stringify(b2.to_dict())
	check(text1 == text2, "сохранение и загрузка дают то же состояние")
	check(b.rng.randi() == b2.rng.randi(), "генератор случайных чисел продолжается одинаково")


func test_simulation_terminates() -> void:
	var ok := true
	for cls in Content.HERO_CLASSES:
		for level in range(1, 6):
			var arch: String = Content.archetypes_of(cls)[level % 2]
			var r := Simulator.run_battle(level, cls, arch, level % 2 == 0, "trial", level, level % 3 == 0)
			if r.outcome == "timeout":
				ok = false
	check(ok, "симулированные бои заканчиваются")


func test_rage_and_relentless() -> void:
	var f := Content.make_hero("fighter", 5, "berserker")
	f.cell = Vector2i(5, 5)
	var o := Content.make_enemy("overseer", 1)
	o.cell = Vector2i(6, 5)
	var b := arena([f, o])
	check(b.use_ability(f, "rage", f.cell) and f.raging, "ярость")
	check(b._mitigate(f, 10) == 8, "в ярости урон от оружия меньше на 2")
	b.deal_damage(f, f.hp + 5, "test")
	check(f.hp == 1 and not f.down and f.relentless_used, "неудержимый остаётся с 1 хитом")
	b.deal_damage(f, 5, "test")
	check(f.down, "второй раз не спасает")


func test_spikes_and_web() -> void:
	var w := Content.make_hero("wizard", 4, "binder")
	var z := helpless("zombie", 1, Vector2i(8, 0))
	z.max_hp = 99
	z.hp = 99
	var z2 := helpless("zombie", 2, Vector2i(4, 6))
	var b := arena([w, z, z2])
	check(b.use_ability(w, "spike_growth", Vector2i(5, 0)), "шипы выросли")
	b.order = [w.id, z.id, z2.id]
	b.turn_index = 0
	b.end_turn()
	b.move_along(z, b.path_to(z, Vector2i(4, 0), b.reachable(z)))
	check(z.hp < 99, "шаги по шипам ранят")
	b.end_turn()
	b.end_turn()
	check(b.use_ability(w, "web", Vector2i(4, 6)) and z2.restrained, "паутина опутывает")
	check(b.attack_preview(w, z2).adv == 1, "по опутанному — с преимуществом")


func test_slow() -> void:
	var w := Content.make_hero("wizard", 5, "binder")
	var d := helpless("wight", 1, Vector2i(5, 0))
	var b := arena([w, d])
	var ac := b.ac_of(d)
	check(b.use_ability(w, "slow", d.cell) and d.slow_spell, "замедление")
	check(b.ac_of(d) == ac - 2 and not d.can_react(), "замедленный: −2 КД и без атак при возможности")


func test_shadow_step() -> void:
	var r := Content.make_hero("rogue", 1)
	r.cell = Vector2i(5, 5)
	var z := helpless("zombie", 1, Vector2i(6, 5))
	z.max_hp = 99
	z.hp = 99
	var b := arena([r, z])
	r.hp = 3
	check(b.use_ability(r, "shadow_step", r.cell) and r.shadow_ready, "шаг в тень")
	b.attack(r, z)
	check(not r.shadow_ready and r.hp > 3, "удар из тени ранит некротикой и лечит плута")
