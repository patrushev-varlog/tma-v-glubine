extends GutTest
## Бои главы 4 (docs/CHAPTER4_BATTLES.md): строй мертвецов-солдат, надсмотрщики и Гессар поднимают павших,
## желоба с жидким железом и ковши литейной; лавка в лагере; глава целиком до уровня 5.

const A := preload("res://tests/helpers/arena.gd")
const CH4 := ["chapter4_1", "chapter4_2", "chapter4_3", "chapter4_3_refuse"]
const HERO := {"class": "fighter", "hero_f": false, "name": "Ардан", "spouse_f": true, "spouse_id": "eila",
	"spouse_name": "Эйла", "archetype": "guardian"}


func _battle(bid: String, diff := "story", party := "full", seed_value := 3) -> Battle:
	var b := Battle.new()
	b.setup(CombatData.scenario(bid, "fighter", "guardian", party, diff, "kit", {}), seed_value, diff)
	return b


func _first(b: Battle, kind: String) -> Combatant:
	for e in b.enemies():
		if e.kind == kind:
			return e
	return null


func test_every_chapter4_battle_tag_has_battle() -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../story/ink/chapter4/")
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
	assert_eq(tags, CH4, "цеха, мастер плоти и литейная в двух вариантах")
	for t in tags:
		assert_eq(int(CombatData.table("battles")[t].level), 4, "%s на 4 уровне: уровень 5 — в лагере главы" % t)


func test_party_follows_story() -> void:
	for bid in CH4:
		assert_false(CombatData.table("battles")[bid].has("party"), "%s: отряд из сюжета — Велиор только прощённый" % bid)
	var full := _battle("chapter4_1", "trial")
	var duo := _battle("chapter4_1", "trial", "no_velior")
	assert_eq(duo.heroes().size(), full.heroes().size() - 1, "без Велиора на одного меньше")
	assert_lt(duo.enemies().size(), full.enemies().size(), "без Велиора врагов меньше")


func test_soldiers_hold_formation() -> void:
	var s1 := A.at(CombatData.make_enemy("dead_soldier", 1), Vector2i(5, 5))
	var s2 := A.at(CombatData.make_enemy("dead_soldier", 2), Vector2i(6, 5))
	var f := A.at(CombatData.make_hero("fighter", 4, "guardian"), Vector2i(2, 2))
	var b := A.make([f, s1, s2])
	assert_eq(b.ac_of(s1), s1.ac + 2, "сосед по строю даёт +2 к КД")
	s2.cell = Vector2i(9, 9)
	assert_eq(b.ac_of(s1), s1.ac, "один — без строя")


func test_overseer_raises_fallen() -> void:
	var o := A.at(CombatData.make_enemy("vat_overseer", 1), Vector2i(5, 5))
	var z := A.at(CombatData.make_enemy("dead_soldier", 1), Vector2i(6, 6))
	var f := A.at(CombatData.make_hero("fighter", 4, "guardian"), Vector2i(1, 1))
	var b := A.make([f, o, z])
	b.difficulty = "story"
	z.hp = 0
	z.dead = true
	b._raise_fallen(o, b.mod_get(o, "raise"))
	assert_false(z.dead, "надсмотрщик поднял мертвеца")
	assert_eq(z.hp, z.max_hp / 2, "с половиной хитов")
	z.dead = true
	b._raise_fallen(o, b.mod_get(o, "raise"))
	assert_true(z.dead, "на «Истории» — только раз за бой")


func test_gessar_raises_on_trial_more() -> void:
	var g := A.at(CombatData.make_enemy("gessar", 1), Vector2i(5, 5))
	var k := A.at(CombatData.make_enemy("stitched", 1), Vector2i(6, 6))
	var b := A.make([A.at(CombatData.make_hero("fighter", 4, "guardian"), Vector2i(1, 1)), g, k])
	b.difficulty = "trial"
	for i in 3:
		k.dead = true
		b._raise_fallen(g, b.mod_get(g, "raise"))
	assert_true(k.dead, "на «Испытании» Гессар сшивает дважды, третьего раза нет")
	assert_eq(int(g.counters.raise), 2)


func test_raise_skips_living_and_bosses() -> void:
	var o := A.at(CombatData.make_enemy("vat_overseer", 1), Vector2i(5, 5))
	var o2 := A.at(CombatData.make_enemy("vat_overseer", 2), Vector2i(6, 5))
	var b := A.make([A.at(CombatData.make_hero("fighter", 4, "guardian"), Vector2i(1, 1)), o, o2])
	o2.dead = true
	b._raise_fallen(o, b.mod_get(o, "raise"))
	assert_true(o2.dead, "живого надсмотрщика не поднять")


func test_molten_channel() -> void:
	var b := _battle("chapter4_3")
	var molten := Vector2i(1, 3)
	assert_true(b.is_molten(molten), "знак ! — желоб с жидким железом")
	assert_false(b.is_obstacle(molten), "желоб не стена: стрелять через него можно")
	var h := b.heroes()[0]
	for c in b.reachable(h):
		if c is Vector2i:
			assert_false(b.is_molten(c), "своими ногами в желоб не идут")
	# Толчок в желоб жжёт.
	var f := A.at(CombatData.make_hero("fighter", 4, "guardian"), Vector2i(3, 2))
	var d := A.at(CombatData.make_enemy("foundry_dead", 1), Vector2i(3, 1))
	f.saves = {"str": -30, "dex": -30, "con": 0, "wis": 0}
	d.weapon["to_hit"] = 99
	var ar := A.make([d, f])
	ar.decor[Vector2i(3, 3)] = "molten"
	var hp0 := f.hp
	ar.attack(d, f)
	assert_eq(f.cell, Vector2i(3, 3), "крюк литейщика отбросил в желоб")
	assert_true(ar.log_lines.has(tr("BATTLE_LOG_MOLTEN").format({"name": f.name})), "в журнале — ожог")
	assert_lt(f.hp, hp0)


func test_ladles_pour_on_schedule() -> void:
	var b := _battle("chapter4_3")
	assert_eq(b.stage.ladles.size(), 2, "два ковша")
	assert_eq(b.ladle_cells_next().size(), b.stage.ladles[0].cells.size(), "в 1-м раунде подсвечен ковш, что льёт во 2-м")
	var cell := Vector2i(int(b.stage.ladles[0].cells[0][0]), int(b.stage.ladles[0].cells[0][1]))
	var h := b.heroes()[0]
	h.cell = cell
	h.saves = {"str": 0, "dex": -30, "con": 0, "wis": 0}
	var hp0 := h.hp
	b.round_num = 2
	b._new_round()
	assert_lt(h.hp, hp0, "расплав из ковша обжёг героя на подсвеченной клетке")
	assert_true(b.log_lines.has(tr("BATTLE_LOG_LADLE_POUR")))


func test_refuse_is_harder() -> void:
	var a: Dictionary = CombatData.table("battles")["chapter4_3"]
	var r: Dictionary = CombatData.table("battles")["chapter4_3_refuse"]
	var kinds := []
	for w in r.waves:
		kinds.append_array(w.units)
	assert_true(kinds.has("executioner"), "в варианте отказа казнители идут следом")
	assert_eq(a.map, r.map, "та же литейная")


func test_ai_finishes_every_chapter4_battle() -> void:
	for bid in CH4:
		for diff in ["story", "trial"]:
			var r := Simulator.run_battle(bid, "wizard", "", "full", diff, 11, false, "kit", {})
			assert_true(["victory", "defeat"].has(String(r.outcome)), "%s (%s) заканчивается: %s" % [bid, diff, r.outcome])


func test_battle_loot_silver() -> void:
	for bid in CH4:
		assert_gt(int(CombatData.table("battles")[bid].get("silver", 0)), 0, "добыча за %s" % bid)


func test_camp_shop_sells_foundry_goods() -> void:
	for id in ["sutler_ch4", "smith_ch4"]:
		var ids := Shops.stock(id).map(func(s: Dictionary) -> String: return String(s.id))
		assert_true(ids.has("foundry_maul"), "%s: молот литейщика" % id)
		assert_true(ids.has("slag_ward"), "%s: оберег из окалины" % id)
	assert_eq(Shops.price("smith_ch4", "foundry_maul"), 75, "кузнец из Эшмура на 25% дешевле")


# --- Глава целиком ----------------------------------------------------------------

func _advance(s: StorySession, stop: String, pick: Callable, seen: Array) -> bool:
	for i in 12000:
		var item := s.next()
		if s.chapter_name() == stop:
			return true
		match String(item.type):
			"battle":
				seen.append(String(item.id))
				s.win_battle(0)
			"levelup":
				seen.append("levelup:%d" % int(item.level))
				s.choose_branch(String(s.state.hero.archetype))
			"shop":
				seen.append("shop:" + String(item.id))
				s.leave_shop([])
			"choices":
				s.choose(int(pick.call(item.options)))
			"end":
				return false
	return false


static func _pick_by(prefix: Array) -> Callable:
	return func(options: Array) -> int:
		for k in options.size():
			for p in prefix:
				if String(options[k]).begins_with(String(p)):
					return k
		return 0


func _to_chapter4() -> StorySession:
	var s := StorySession.new()
	s.new_game({"hero": HERO, "difficulty": "story"}, "ru")
	assert_true(_advance(s, "chapter4", _pick_by([]), []), "дошли до главы 4")
	return s


func test_chapter4_refuse_and_ring_destroyed() -> void:
	var s := _to_chapter4()
	var dark0 := int(s.darkness())
	var seen := []
	var ok := _advance(s, "chapter5", _pick_by(["Ломать краны", "Открыть папку", "Взять перстень", "«Я не играю",
		"Бросить перстень"]), seen)
	assert_true(ok, "глава 4 пройдена до главы 5")
	for bid in ["chapter4_1", "chapter4_2", "chapter4_3_refuse"]:
		assert_true(seen.has(bid), "бой %s" % bid)
	assert_false(seen.has("chapter4_3"), "при отказе — только вариант с казнителями")
	assert_true(seen.has("levelup:5"), "в лагере — уровень 5")
	assert_eq(s.state.level, 5)
	assert_true(seen.any(func(x: String) -> bool: return x.begins_with("shop:") and x.ends_with("_ch4")), "в лагере торговец")
	assert_eq(String(s.flag("ch4_arithmetic")), "refuse")
	assert_true(s.flag("ring_destroyed"), "перстень в печи")
	assert_false(s.state.items_of("hero").has("pale_ring"), "перстня больше нет")
	assert_true(s.flag("ch4_report_read"))
	# Руками и отказ — без Тьмы, перстень −10; Ирена при Тьме ниже 25 только остаётся.
	assert_eq(int(s.darkness()), maxi(0, dark0 - 10), "искупление перстнем: −10 Тьмы")


func test_chapter4_whisper_and_pass() -> void:
	var s := _to_chapter4()
	var dark0 := int(s.darkness())
	var seen := []
	_advance(s, "chapter5", _pick_by(["Приказать мёртвым", "Не открывать", "Оставить перстень", "Пройти мимо"]), seen)
	assert_true(seen.has("chapter4_3"), "мимо клеток — обычная литейная")
	assert_eq(String(s.flag("ch4_vats")), "whisper")
	assert_false(s.flag("ring_taken"))
	assert_gte(int(s.darkness()) - dark0, 15, "шёпот +5 и «пройти мимо» +10")
