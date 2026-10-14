extends GutTest
## Бои главы 2 (docs/CHAPTER2_BATTLES.md): вода по пояс, укрытия, страж шлюза на цепи, беглые-союзники
## в насосной, добыча; лавка контрабандистов с платой «услугой»; глава целиком до уровня 3.

const A := preload("res://tests/helpers/arena.gd")
const CH2 := ["chapter2_1", "chapter2_2_smugglers", "chapter2_2_flooded", "chapter2_3", "ch2_hunt_priest"]
const HERO := {"class": "fighter", "hero_f": false, "name": "Ардан", "spouse_f": true, "spouse_id": "eila",
	"spouse_name": "Эйла", "archetype": "guardian"}


func _battle(bid: String, diff := "story", flags := {}, seed_value := 3) -> Battle:
	var b := Battle.new()
	b.setup(CombatData.scenario(bid, "fighter", "guardian", "full", diff, "kit", flags), seed_value, diff)
	return b


func _allies(b: Battle) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for u in b.units:
		if u.ai_ally:
			out.append(u)
	return out


func test_every_chapter2_battle_tag_has_battle() -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../story/ink/chapter2/")
	if not DirAccess.dir_exists_absolute(dir):
		pass_test("исходников Ink рядом нет (сборка без story/)")
		return
	var tags := []
	for f in DirAccess.get_files_at(dir):
		for line in FileAccess.get_file_as_string(dir + f).split("\n"):
			var at := line.find("# battle:")
			var id := line.substr(at + 9).strip_edges().split(" ")[0] if at >= 0 else ""
			if id.is_valid_ascii_identifier():
				tags.append(id)
	tags.sort()
	var want := CH2.duplicate()
	want.sort()
	assert_eq(tags, want, "пять боёв главы 2: два варианта в насосной и страж охоты")
	for t in tags:
		assert_eq(int(CombatData.table("battles")[t].level), 2, "%s на 2 уровне: уровень 3 — в лагере после шлюза" % t)


func test_full_party_with_velior() -> void:
	for bid in CH2:
		var kinds := []
		for h in _battle(bid).heroes():
			kinds.append(h.kind)
		assert_eq(kinds.size(), 4, "%s: герой и трое спутников" % bid)
		assert_true(kinds.has("velior"), "Велиор в бою %s" % bid)


func test_fugitives_help_only_in_pump_fight() -> void:
	var b := _battle("chapter2_2_smugglers")
	var al := _allies(b)
	assert_eq(al.size(), 3, "трое беглых дерутся рядом")
	for u in al:
		assert_true(b.ai_turn(u), "беглый ходит сам")
	assert_eq(_allies(_battle("chapter2_2_flooded")).size(), 0, "беглых сдали — помощи нет")
	assert_eq(_allies(_battle("chapter2_3")).size(), 0, "у шлюза беглые не вмешиваются")


func test_wade_costs_two_steps() -> void:
	var b := _battle("chapter2_1")
	var h := b.heroes()[0]
	assert_eq(String(b.decor.get(Vector2i(5, 1), "")), "wade", "знак - на карте — вода по пояс")
	assert_eq(b.step_cost(Vector2i(5, 1)), 2)
	assert_eq(b.step_cost(Vector2i(5, 1), true), 1, "утопленнику — шаг за один")
	assert_eq(b.step_cost(Vector2i(3, 1)), 1, "сухой пол — шаг за один")
	# Путь по воде тратит два движения на клетку.
	h.cell = Vector2i(4, 2)
	h.speed_left = 6
	var reach := b.reachable(h)
	assert_eq(int(reach[Vector2i(5, 2)].cost), 2)
	b.move_along(h, b.path_to(h, Vector2i(5, 2), reach))
	assert_eq(h.speed_left, 4, "вошёл в воду — минус два")
	assert_true(b.log_lines.has(tr("BATTLE_LOG_CH2_WATER")), "в начале боя подсказка о воде и укрытиях")


func test_cover_from_shots() -> void:
	var shooter := A.at(CombatData.make_enemy("crossbowman", 1), Vector2i(2, 5))
	var target := A.at(CombatData.make_hero("fighter", 2, "guardian"), Vector2i(8, 5))
	var b := A.make([shooter, target])
	b.obstacles[Vector2i(7, 5)] = true
	assert_false(b.in_cover(shooter, target), "без правила cover укрытий нет (пролог, глава 1)")
	b.stage["cover"] = true
	assert_true(b.in_cover(shooter, target), "колонна вплотную к цели — укрытие")
	assert_eq(b.ac_against(shooter, target, true), b.ac_of(target) + Battle.COVER_AC)
	assert_eq(b.ac_against(shooter, target, false), b.ac_of(target), "от удара вплотную не укрывает")
	shooter.cell = Vector2i(6, 5)
	assert_false(b.in_cover(shooter, target), "стрелок прижат к той же колонне — укрытия нет")
	shooter.cell = Vector2i(8, 1)
	assert_false(b.in_cover(shooter, target), "колонна не на линии выстрела")
	var pv := b.attack_preview(A.at(CombatData.make_enemy("crossbowman", 2), Vector2i(2, 5)), target)
	shooter.cell = Vector2i(2, 5)
	b.obstacles.erase(Vector2i(7, 5))
	assert_lt(float(pv.chance), float(b.attack_preview(shooter, target).chance), "прогноз учитывает укрытие")


func test_sluice_guardian_chained() -> void:
	var b := _battle("chapter2_3")
	var g: Combatant = null
	for e in b.enemies():
		if e.kind == "sluice_guardian":
			g = e
	assert_not_null(g, "страж шлюза в бою")
	var t: Dictionary = b.stage.tether[g.id]
	var anchor := Vector2i(int(t.cell[0]), int(t.cell[1]))
	assert_eq(anchor, g.cell, "цепь держит у места, где он сидел")
	g.speed_left = 20
	for c in b.reachable(g):
		if c is Vector2i:
			assert_true(Battle.dist(c, anchor) <= int(t.r), "страж не отходит дальше цепи: %s" % c)
	# Цепь сохраняется вместе с боем.
	var copy := Battle.from_dict(b.to_dict())
	assert_eq(copy.stage.tether.keys(), b.stage.tether.keys())


func test_ai_finishes_every_chapter2_battle() -> void:
	for bid in CH2:
		for diff in ["story", "trial"]:
			var r := Simulator.run_battle(bid, "wizard", "", "full", diff, 11, false, "kit", {})
			assert_true(["victory", "defeat"].has(String(r.outcome)), "%s (%s) заканчивается: %s" % [bid, diff, r.outcome])


func test_battle_loot_silver() -> void:
	for bid in CH2:
		assert_gt(int(CombatData.table("battles")[bid].get("silver", 0)), 0, "добыча за %s" % bid)


# --- Лавка контрабандистов и глава целиком -------------------------------------------

## История до главы 2 с выбором по умолчанию (первый вариант); бои выиграны, лавки без покупок.
func _to_chapter2() -> StorySession:
	var s := StorySession.new()
	s.new_game({"hero": HERO, "difficulty": "story"}, "ru")
	for i in 6000:
		var item := s.next()
		if s.chapter_name() == "chapter2":
			return s
		match String(item.type):
			"battle":
				s.win_battle(0)
			"levelup":
				s.choose_branch(String(s.state.hero.archetype))
			"shop":
				s.leave_shop([])
			"choices":
				s.choose(0)
	fail_test("не дошли до главы 2")
	return s


## Пройти главу 2: pick(текст вариантов) → номер; shop(id) → покупки.
func _play_chapter2(s: StorySession, pick: Callable, shop: Callable) -> Array:
	var seen := []
	for i in 6000:
		var item := s.next()
		if s.chapter_name() == "chapter3":
			return seen
		match String(item.type):
			"battle":
				seen.append(String(item.id))
				s.win_battle(0)
			"levelup":
				seen.append("levelup:%d" % int(item.level))
				s.choose_branch(String(s.state.hero.archetype))
			"shop":
				seen.append("shop:" + String(item.id))
				s.leave_shop(shop.call(String(item.id)))
			"choices":
				s.choose(int(pick.call(item.options)))
			"end":
				break
	fail_test("не дошли до главы 3")
	return seen


static func _pick_by(prefix: Array) -> Callable:
	return func(options: Array) -> int:
		for k in options.size():
			for p in prefix:
				if String(options[k]).begins_with(String(p)):
					return k
		return 0


func test_chapter2_fight_path_and_level3() -> void:
	var s := _to_chapter2()
	s.state.silver = 200
	var seen := _play_chapter2(s, _pick_by(["Купить только", "«Нет. Мы заплатим", "Проводить их"]),
		func(id: String) -> Array: return [["silver_bow", "velior"]] if id == "smugglers" else [])
	assert_true(seen.has("chapter2_2_smugglers"), "отказали Ренне — бой в насосной")
	assert_false(seen.has("chapter2_2_flooded"))
	assert_eq(String(s.flag("ch2_choice")), "fight")
	assert_true(seen.has("levelup:3"), "в лагере над шлюзом — уровень 3")
	assert_eq(s.state.level, 3)
	assert_true(s.state.items_of("velior").has("silver_bow"), "серебряный лук куплен Велиору")
	assert_true(s.flag("ch2_fugitives_led"), "беглых довели наверх")
	assert_false(seen.has("shop:smugglers_favor"), "без «услуги» тёмной лавки нет")


func test_chapter2_favor_and_hand_over() -> void:
	var s := _to_chapter2()
	var dark0 := int(s.darkness())
	var seen := _play_chapter2(s, _pick_by(["Заплатить «услугой»", "Сдать беглых"]),
		func(id: String) -> Array:
			return [["black_steel", "garret"], ["drowned_shroud", "hero"]] if id == "smugglers_favor" else [])
	assert_true(seen.has("shop:smugglers_favor"), "за «услугу» Ренна открывает тёмный ящик")
	assert_true(s.flag("ch2_favor_owed"))
	assert_true(s.state.items_of("garret").has("black_steel"), "чёрная сталь — без серебра")
	assert_false(s.state.items_of("hero").has("drowned_shroud"), "за услугу — только одна вещь")
	assert_true(seen.has("chapter2_2_flooded"), "сдали беглых — бой в обходном канале")
	assert_eq(int(s.darkness()) - dark0, 15, "услуга +5 и беглые +10")
