extends GutTest
## Бои главы 5 (docs/CHAPTER5_BATTLES.md): гарнизон у главного спуска, стража совета (и с поднятыми узниками),
## финальный бой с Эдриком в фазах; карты спуска и зала печати; глава целиком до каждой из четырёх концовок.

const A := preload("res://tests/helpers/arena.gd")
const CH5 := ["chapter5_1_garrison", "chapter5_2", "chapter5_2_raised", "chapter5_final_master", "chapter5_final_peace"]
const HERO := {"class": "fighter", "hero_f": false, "name": "Ардан", "spouse_f": true, "spouse_id": "eila",
	"spouse_name": "Эйла", "archetype": "guardian"}


func _battle(bid: String, diff := "story", party := "full", flags := {}, seed_value := 3) -> Battle:
	var b := Battle.new()
	b.setup(CombatData.scenario(bid, "fighter", "guardian", party, diff, "kit", flags), seed_value, diff)
	return b


func _kill_enemies(b: Battle) -> void:
	for e in b.enemies():
		if not e.dead:
			b.deal_damage(e, e.hp, "test")


func test_every_chapter5_battle_tag_has_battle() -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../story/ink/chapter5/")
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
	assert_eq(tags, CH5, "гарнизон, стража совета в двух вариантах и финал «Мира» и «Нового хозяина»")
	for t in tags:
		assert_eq(int(CombatData.table("battles")[t].level), 5, "%s на 5 уровне" % t)


func test_party_follows_story() -> void:
	for bid in CH5:
		assert_false(CombatData.table("battles")[bid].has("party"), "%s: отряд из сюжета" % bid)
	var full := _battle("chapter5_2", "trial")
	var duo := _battle("chapter5_2", "trial", "no_velior")
	assert_eq(duo.heroes().size(), full.heroes().size() - 1, "без Велиора на одного меньше")
	assert_lt(duo.enemies().size(), full.enemies().size(), "без Велиора врагов меньше")


func test_irena_stays_out_of_tyrant_fight() -> void:
	var kinds := func(b: Battle) -> Array: return b.heroes().map(func(h: Combatant) -> String: return h.kind)
	var guardian := _battle("chapter5_final_master", "story", "full", {"ending": "guardian"})
	var tyrant := _battle("chapter5_final_master", "story", "full", {"ending": "tyrant"})
	assert_true(kinds.call(guardian).has("irena"), "страж глубин: Ирена в бою")
	assert_false(kinds.call(tyrant).has("irena"), "новый хозяин: Гаррет увёл Ирену к стене")
	assert_eq(tyrant.heroes().size(), guardian.heroes().size() - 1)
	var e_tyr := _battle("chapter5_final_master", "trial", "full", {"ending": "tyrant"})
	var e_gua := _battle("chapter5_final_master", "trial", "full", {"ending": "guardian"})
	var hp := func(b: Battle) -> int: return b.enemies().filter(func(e: Combatant) -> bool: return e.kind == "edric")[0].max_hp
	assert_lt(hp.call(e_tyr), hp.call(e_gua), "без Ирены состав урезан: у Эдрика меньше хитов")


func test_raised_prisoners_fight_for_hero() -> void:
	var b := _battle("chapter5_2_raised")
	var allies := b.units.filter(func(h: Combatant) -> bool: return h.kind == "raised_prisoner")
	assert_eq(allies.size(), 2, "двое поднятых узников: четверо делали бой слишком лёгким")
	assert_true(allies.all(func(h: Combatant) -> bool: return h.ai_ally and h.undead), "под ИИ, нежить")
	var plain := _battle("chapter5_2")
	assert_eq(plain.enemies().size(), b.enemies().size(), "стража та же")


func test_incomplete_party_trims_waves_and_phases() -> void:
	var count := func(sc: Dictionary, key: String) -> int: return sc.stage[key][0].units.size()
	var full := CombatData.scenario("chapter5_2", "fighter", "guardian", "full", "trial")
	var trio := CombatData.scenario("chapter5_2", "fighter", "guardian", "no_irena", "trial")
	assert_eq(count.call(full, "waves"), 3, "полному отряду «Испытание» добавляет стражника в волну")
	assert_eq(count.call(trio, "waves"), 1, "без Ирены волна урезана по бюджету и без добавки «Испытания»")
	var fin := CombatData.scenario("chapter5_final_peace", "fighter", "guardian", "full", "trial")
	var duo := CombatData.scenario("chapter5_final_peace", "fighter", "guardian", "duo", "trial")
	assert_eq(count.call(fin, "phases"), 3)
	assert_eq(count.call(duo, "phases"), 1, "вдвоём из света выходит одна тень")
	assert_eq(int(fin.stage.phases[0].get("heal_heroes", 0)), 0)
	assert_eq(int(duo.stage.phases[0].heal_heroes), int(CombatData.rules().phase_heal.duo), "вдвоём лечить некому: отряд подлечивается в фазах")


func test_hunt_done_adds_enemy_hp() -> void:
	var hp := func(flags: Dictionary) -> int:
		var sc := CombatData.scenario("chapter5_2", "fighter", "guardian", "full", "trial", "kit", flags)
		return sc.units.filter(func(u: Combatant) -> bool: return u.team == 1)[0].max_hp
	assert_gt(hp.call({"ch5_hunt_done": true}), hp.call({}), "после охоты главы у врагов больше хитов")
	assert_eq(hp.call({"ch4_hunt_done": true}), hp.call({}), "охота другой главы не в счёт")


func test_council_guard_halberd_and_formation() -> void:
	var g1 := A.at(CombatData.make_enemy("council_guard", 1), Vector2i(5, 5))
	var g2 := A.at(CombatData.make_enemy("council_guard", 2), Vector2i(6, 5))
	var f := A.at(CombatData.make_hero("fighter", 5, "guardian"), Vector2i(5, 7))
	var b := A.make([f, g1, g2])
	assert_eq(g1.reach(), 2, "алебарда бьёт через клетку")
	assert_true(b.in_weapon_range(g1, f))
	assert_eq(b.ac_of(g1), g1.ac + 2, "строй: +2 к КД")


func test_peace_final_has_two_phases() -> void:
	var b := _battle("chapter5_final_peace")
	assert_eq(b.phase_count(), 2)
	assert_eq(b.phase_num(), 1)
	var first := b.enemies().size()
	_kill_enemies(b)
	assert_eq(b.outcome, "", "после первой фазы бой не кончен")
	assert_eq(b.phase_num(), 2)
	assert_true(b.log_lines.has(tr("BATTLE_LOG_CH5_SLEEPER")))
	var alive := b.enemies().filter(func(e: Combatant) -> bool: return not e.dead)
	assert_eq(alive.filter(func(e: Combatant) -> bool: return e.kind == "sleeper_shade").size(), 2, "из света выходят две тени")
	var risen := alive.filter(func(e: Combatant) -> bool: return e.kind == "council_guard")
	assert_eq(risen.size(), first - 1, "павшие стражи встают, Эдрик — нет")
	assert_true(risen.all(func(e: Combatant) -> bool: return e.hp == maxi(1, e.max_hp / 2)), "с половиной хитов")
	_kill_enemies(b)
	assert_eq(b.outcome, "victory", "после второй фазы — победа")


func test_master_final_third_phase_edric_returns() -> void:
	var b := _battle("chapter5_final_master")
	assert_eq(b.phase_count(), 3)
	_kill_enemies(b)
	_kill_enemies(b)
	assert_eq(b.phase_num(), 3)
	assert_eq(b.outcome, "")
	var edric: Combatant = b.enemies().filter(func(e: Combatant) -> bool: return e.kind == "edric")[0]
	assert_false(edric.dead, "Эдрик встаёт перехватить силу")
	assert_eq(edric.hp, edric.max_hp / 2)
	assert_eq(b.enemies().filter(func(e: Combatant) -> bool: return not e.dead).size(), 1, "в третьей фазе он один")
	_kill_enemies(b)
	assert_eq(b.outcome, "victory")


func test_master_third_phase_heals_party() -> void:
	var b := _battle("chapter5_final_master")
	var h := b.heroes()[0]
	_kill_enemies(b)
	h.hp = 1
	_kill_enemies(b)
	assert_gt(h.hp, 1, "сила Спящего затягивает раны")
	assert_eq(h.hp, 1 + h.max_hp * 25 / 100)


func test_phases_survive_save() -> void:
	var b := _battle("chapter5_final_master")
	_kill_enemies(b)
	var b2 := Battle.from_dict(JSON.parse_string(JSON.stringify(b.to_dict())))
	assert_eq(b2.phase_num(), 2, "фаза сохраняется вместе с боем")
	assert_eq(b2.phase_count(), 3)


func test_ai_finishes_every_chapter5_battle() -> void:
	for bid in CH5:
		for diff in ["story", "trial"]:
			var r := Simulator.run_battle(bid, "wizard", "", "full", diff, 11, false, "kit", {})
			assert_true(["victory", "defeat"].has(String(r.outcome)), "%s (%s) заканчивается: %s" % [bid, diff, r.outcome])


# --- Карты ---------------------------------------------------------------------------

func test_maps_for_descent_and_seal_hall() -> void:
	assert_eq(LocationMap.for_scene("descent"), "deep_descent")
	assert_eq(LocationMap.for_scene("seal_hall"), "deep_seal_hall")
	var m := LocationMap.load_location("deep_seal_hall")
	m.setup_scene("seal_hall")
	assert_eq(int(m.object("seal_center").get("leave_check", 0)), 5, "центр печати — точка невозврата охоты")


func test_crack_only_for_forgiven_velior() -> void:
	var m := LocationMap.load_location("deep_descent")
	var flags := {"velior_fate": "forgiven", "ch5_secret_path": true}
	var check := func(fl: Dictionary) -> Callable:
		return func(c: String) -> bool:
			var neg := c.begins_with("!")
			var k := c.substr(1) if neg else c
			var v := String(fl.get(k.get_slice("=", 0), "")) == k.get_slice("=", 1) if k.contains("=") \
				else LocationMap.truthy(fl.get(k, false))
			return v != neg
	m.setup_scene("descent", check.call(flags))
	assert_true(m.object("crack_stones").is_empty())
	assert_true(m.path_to_object(m.spawn_of("descent"), m.object("ledge_end")).ok, "тайный путь открыт")
	m.setup_scene("descent", check.call({"velior_fate": "exiled"}))
	assert_false(m.object("crack_stones").is_empty(), "трещину заложили")
	assert_false(m.path_to_object(m.spawn_of("descent"), m.object("ledge_end")).ok, "на карниз не пройти")
	assert_true(m.path_to_object(m.spawn_of("descent"), m.object("hall_gate")).ok, "главный спуск открыт")


# --- Глава целиком ----------------------------------------------------------------

func _advance(s: StorySession, pick: Callable, seen: Array, explore := {}) -> bool:
	for i in 20000:
		var item := s.next()
		match String(item.type):
			"battle":
				seen.append(String(item.id))
				s.win_battle(0)
			"levelup":
				s.choose_branch(String(s.state.hero.archetype))
			"shop":
				s.leave_shop([])
			"choices":
				var scene := s.scene_name()
				if s.flow == "" and explore.has(scene) and not explore[scene].is_empty() and item.objects.any(func(o: String) -> bool: return o != ""):
					_check_objects(s, item)
					s.explore(String(explore[scene].pop_front()))
					continue
				if s.chapter_name() == "chapter5":
					_check_objects(s, item)
				s.choose(int(pick.call(item.options)))
			"explore_end":
				pass
			"end":
				return true
	return false


## На карте сцены главы 5 у каждого #obj: есть объект, до которого можно дойти.
func _check_objects(s: StorySession, item: Dictionary) -> void:
	var loc := LocationMap.for_scene(s.scene_name())
	for obj in item.objects:
		if obj == "":
			continue
		assert_ne(loc, "", "#obj:%s в сцене с картой" % obj)
		var m := LocationMap.load_location(loc)
		m.setup_scene(s.scene_name(), func(c: String) -> bool: return _cond(s, c))
		var o := m.object(obj)
		assert_false(o.is_empty(), "объект %s есть на карте" % obj)
		assert_true(m.path_to_object(m.spawn_of(s.scene_name()), o).ok, "до %s можно дойти" % obj)


func _cond(s: StorySession, cond: String) -> bool:
	if cond.contains("|"):
		return Array(cond.split("|")).any(func(p: String) -> bool: return _cond(s, p))
	if cond.contains("&"):
		return Array(cond.split("&")).all(func(p: String) -> bool: return _cond(s, p))
	var neg := cond.begins_with("!")
	var c := cond.substr(1) if neg else cond
	var v: bool
	if c.begins_with("won:"):
		v = s.state.battles.has(c.substr(4))
	elif c.contains("="):
		v = String(s.flag(c.get_slice("=", 0))) == c.get_slice("=", 1)
	else:
		v = LocationMap.truthy(s.flag(c))
	return v != neg


static func _pick_by(prefix: Array) -> Callable:
	return func(options: Array) -> int:
		for p in prefix:
			for k in options.size():
				if String(options[k]).begins_with(String(p)):
					return k
		return 0


func _to_chapter5(pick := _pick_by([])) -> StorySession:
	var s := StorySession.new()
	s.new_game({"hero": HERO, "difficulty": "story"}, "ru")
	for i in 20000:
		var item := s.next()
		if s.chapter_name() == "chapter5":
			return s
		match String(item.type):
			"battle":
				s.win_battle(0)
			"levelup":
				s.choose_branch(String(s.state.hero.archetype))
			"shop":
				s.leave_shop([])
			"choices":
				s.choose(int(pick.call(item.options)))
	fail_test("не дошли до главы 5")
	return s


func test_peace_with_secret_path_and_council_seal() -> void:
	var s := _to_chapter5()
	assert_eq(String(s.flag("velior_fate")), "forgiven", "по первым вариантам Велиора простили")
	var seen := []
	var explore := {"descent": ["ch5_look_plaque"], "seal_hall": ["ch5_look_crests", "ch5_hunt_site"]}
	assert_true(_advance(s, _pick_by(["Оставить их", "Уважить выбор"]), seen, explore), "история дошла до конца")
	assert_true(s.flag("ch5_secret_path"), "прощённый Велиор ведёт тайным путём")
	assert_false(seen.has("chapter5_1_garrison"), "без боя с гарнизоном")
	assert_true(seen.has("chapter5_2"))
	assert_true(seen.has("chapter5_final_peace"))
	assert_true(s.flag("ch5_hunt_done"), "печать совета найдена")
	assert_true(s.state.inventory.any(func(it: Dictionary) -> bool: return it.id == "council_seal"))
	assert_true(s.state.has_journal("ch5_hunt_ready"), "две подсказки — место ясно")
	assert_eq(s.state.ending, "peace")
	assert_eq(String(s.flag("ending")), "peace")
	assert_gt(int(s.flag("saved_count")), 0, "из рудников кто-то вышел")


func test_love_has_no_final_battle() -> void:
	var s := _to_chapter5()
	var seen := []
	_advance(s, _pick_by(["Оставить их", "«Заканчивай ритуал"]), seen)
	assert_eq(s.state.ending, "love")
	assert_false(seen.any(func(x: String) -> bool: return x.begins_with("chapter5_final")), "в «Любви» финального боя нет")


func test_guardian_below_abyss_and_raised_dead() -> void:
	var s := _to_chapter5()
	var dark0 := int(s.darkness())
	assert_lt(dark0 + 10, 75, "светлое прохождение ниже Бездны")
	var seen := []
	_advance(s, _pick_by(["Поднять павших", "«Ни ты, ни мир"]), seen)
	assert_true(seen.has("chapter5_2_raised"), "павшие узники встают на стороне героя")
	assert_eq(int(s.darkness()), dark0 + 10, "тёмное действие главы: +10")
	assert_true(seen.has("chapter5_final_master"))
	assert_eq(s.state.ending, "guardian", "ниже 75 — страж глубин")


func test_tyrant_at_abyss_without_velior() -> void:
	# Тёмное прохождение: колонна, допрос, бараки, сделка с Ренной, кинжал Велиора, шёпот у чанов, «мимо клеток».
	var s := _to_chapter5(_pick_by(["Догнать телегу", "Дать ему умереть", "Тихо пройти", "Заплатить «услугой»",
		"Сдать беглых", "Прислушаться к шёпоту", "Взять кинжал со стола", "Взять кинжал.", "Приказать мёртвым",
		"Пройти мимо", "Оставить перстень", "«Мне нужна эта сила"]))
	assert_eq(String(s.flag("velior_fate")), "killed")
	var seen := []
	_advance(s, _pick_by(["Поднять павших", "«Ни ты, ни мир"]), seen)
	assert_true(seen.has("chapter5_1_garrison"), "без Велиора — бой с гарнизоном")
	assert_gte(int(s.darkness()), 75, "все тёмные выборы сюжета доводят до Бездны и без боевой Тьмы")
	assert_eq(s.state.ending, "tyrant", "75 и выше — новый хозяин")
