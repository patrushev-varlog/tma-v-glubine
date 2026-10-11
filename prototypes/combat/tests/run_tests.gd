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
	test_trap()
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


func test_save_roundtrip() -> void:
	var b := Battle.new()
	b.setup(Content.scenario_column("rogue", true), 42, "story")
	CombatAI.take_turn(b, b.current())
	b.end_turn()
	var text1 := JSON.stringify(b.to_dict())
	var b2 := Battle.from_dict(JSON.parse_string(text1))
	var text2 := JSON.stringify(b2.to_dict())
	check(text1 == text2, "сохранение и загрузка дают то же состояние")
	check(b.rng.randi() == b2.rng.randi(), "генератор случайных чисел продолжается одинаково")


func test_simulation_terminates() -> void:
	var ok := true
	for cls in Content.HERO_CLASSES:
		for i in 5:
			var r := Simulator.run_battle(cls, i % 2 == 0, "trial", i, i % 3 == 0)
			if r.outcome == "timeout":
				ok = false
	check(ok, "симулированные бои заканчиваются")
