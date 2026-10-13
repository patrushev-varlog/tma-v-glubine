extends GutTest
## Сюжетные бои пролога (B8): цель «продержаться», подкрепления по раундам, связанный Гаррет,
## Ирена, которая два раунда не поднимает руку, засада и бой, который нельзя проиграть.

const A := preload("res://tests/helpers/arena.gd")
const PROLOGUE := ["prologue_1", "prologue_2", "prologue_3", "prologue_4_camp", "prologue_4_gate"]


func _battle(bid: String, diff := "story", flags := {}, seed_value := 3) -> Battle:
	var b := Battle.new()
	b.setup(CombatData.scenario(bid, "fighter", "", "full", diff, "kit", flags), seed_value, diff)
	return b


## Пропустить ходы до начала раунда n (никто ничего не делает).
func _skip_to_round(b: Battle, n: int) -> void:
	var guard := 0
	while b.round_num < n and b.outcome == "" and guard < 200:
		b.end_turn()
		guard += 1


func _count(b: Battle, kind: String) -> int:
	var n := 0
	for e in b.enemies():
		if e.kind == kind and not e.dead:
			n += 1
	return n


func test_every_prologue_battle_tag_has_battle() -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../story/ink/prologue/")
	var tags := []
	for f in DirAccess.get_files_at(dir):
		for line in FileAccess.get_file_as_string(dir + f).split("\n"):
			var at := line.find("# battle:")
			var id := line.substr(at + 9).strip_edges().split(" ")[0] if at >= 0 else ""
			if id.is_valid_ascii_identifier():
				tags.append(id)
	if tags.is_empty():
		pass_test("исходников Ink рядом нет (сборка без story/)")
		return
	for t in tags:
		assert_true(CombatData.table("battles").has(t), "бой %s из пролога есть в battles.json" % t)


func test_party_comes_from_battle() -> void:
	var b1 := _battle("prologue_1")
	assert_eq(b1.heroes().size(), 1, "облава: герой один")
	var b2 := _battle("prologue_2")
	assert_eq(b2.heroes().map(func(h: Combatant) -> String: return h.kind), ["fighter", "irena"], "храм: герой и Ирена")


func test_trial_adds_enemies() -> void:
	for bid in PROLOGUE:
		assert_true(_battle(bid, "trial").enemies().size() >= _battle(bid, "story").enemies().size(),
			"%s: на «Испытании» врагов не меньше" % bid)


func test_cannot_lose() -> void:
	var b := _battle("prologue_1")
	var h := b.heroes()[0]
	b.deal_damage(h, 999, "test")
	assert_eq(b.outcome, "victory", "облаву нельзя проиграть")
	assert_true(b.stage.get("rescued", false), "соседи добили мертвецов")
	assert_true(b.enemies().all(func(e: Combatant) -> bool: return e.dead), "враги повержены")


func test_irena_hesitates_two_rounds() -> void:
	var b := _battle("prologue_2")
	var ir := b.get_unit("irena")
	assert_true(ir.has_status("hesitant"), "в начале боя Ирена не поднимает руку")
	assert_false(b.can_use(ir, "sacred_flame"), "священное пламя нельзя")
	assert_false(b.can_use(ir, "hallowed_ground"), "освящённую землю нельзя")
	assert_true(b.can_use(ir, "shield_of_faith"), "щит веры можно")
	var z := b.enemies()[0]
	z.cell = ir.cell + Vector2i(1, 0)
	assert_false(b.can_attack(ir, z), "ударить нельзя")
	_skip_to_round(b, 2)
	assert_true(ir.has_status("hesitant"), "во втором раунде ещё нет")
	_skip_to_round(b, 3)
	assert_false(ir.has_status("hesitant"), "с третьего раунда сражается")
	assert_true(A.logged(b, tr("BATTLE_LOG_IRENA_FIGHTS").format({"name": ir.name})), "в журнале её слова")


func test_garret_bound_until_round_two() -> void:
	var b := _battle("prologue_3")
	var g := b.get_unit("garret")
	assert_true(g.has_status("bound"), "Гаррет связан")
	assert_false(b.foes_of(b.enemies()[0]).has(g), "связанного враги не трогают")
	assert_ne(b.current(), g, "связанный не ходит")
	_skip_to_round(b, 2)
	assert_false(g.has_status("bound"), "во втором раунде рвёт верёвки")


func test_garret_cut_free_by_hero() -> void:
	var b := _battle("prologue_3")
	var g := b.get_unit("garret")
	var h := b.heroes()[0]
	h.speed_left = 99
	var spot := g.cell + Vector2i(-1, 0)
	for e in b.enemies():
		if e.cell == spot:
			e.cell = Vector2i(0, 9)
	h.cell = spot + Vector2i(-1, 0)
	b.move_along(h, [spot] as Array[Vector2i])
	assert_false(g.has_status("bound"), "герой встал рядом и разрезал верёвки")
	assert_true(A.logged(b, tr("BATTLE_LOG_CUT_FREE").format({"name": g.name, "by": h.name})), "в журнале")


func test_ambush_and_scared_crossbowman() -> void:
	var plain := _battle("prologue_3")
	assert_eq(_count(plain, "crossbowman"), 1, "без разговора арбалетчик на месте")
	var scared := _battle("prologue_3", "story", {"garret_hunters_scared": true})
	assert_eq(_count(scared, "crossbowman"), 0, "напуганный арбалетчик ушёл до боя")
	var amb := _battle("prologue_3", "story", {"garret_ambush": true})
	assert_true(amb.enemies().all(func(e: Combatant) -> bool: return e.has_status("surprised")), "засада: враги врасплох")
	var e := amb.enemies()[0]
	amb.turn_index = amb.order.find(e.id)
	amb._start_turn()
	assert_true(e.action_used and e.speed_left == 0 and not e.has_status("surprised"), "застигнутый пропускает первый ход")


func test_reinforcements_by_round() -> void:
	var b := _battle("prologue_4_gate")
	var before := b.enemies().size()
	assert_eq(b.next_wave_round(), 3, "подкрепление ждут в третьем раунде")
	_skip_to_round(b, 2)
	assert_eq(b.enemies().size(), before, "во втором раунде ещё никого")
	_skip_to_round(b, 3)
	assert_eq(b.enemies().size(), before + 2, "в третьем раунде из ворот вышли двое мертвецов")
	assert_eq(_count(b, "raised"), 2, "это поднятые")
	assert_eq(b.next_wave_round(), 0, "больше подкреплений нет")
	var ids := {}
	for u in b.units:
		assert_false(ids.has(u.id), "id участников не повторяются: %s" % u.id)
		ids[u.id] = true
		assert_true(b.order.has(u.id), "новички в очереди ходов")


func test_no_victory_while_waves_pending() -> void:
	var b := _battle("prologue_4_gate")
	for e in b.enemies():
		b.deal_damage(e, 999, "test")
	assert_eq(b.outcome, "", "все враги на поле повержены, но подкрепление ещё впереди")
	_skip_to_round(b, 3)
	for e in b.enemies():
		b.deal_damage(e, 999, "test")
	assert_eq(b.outcome, "victory", "после последней волны — победа")


func test_survive_objective() -> void:
	var b := _battle("prologue_4_camp")
	assert_eq(String(b.stage.objective.type), "survive", "у костров цель — продержаться")
	_skip_to_round(b, 4)
	assert_eq(b.outcome, "", "четвёртый раунд ещё идёт")
	assert_true(_count(b, "brandt") == 1, "Брандт прибежал от ворот")
	_skip_to_round(b, 5)
	assert_eq(b.outcome, "victory", "продержались четыре раунда — победа")


func test_stage_survives_save() -> void:
	var b := _battle("prologue_4_gate")
	_skip_to_round(b, 2)
	var c := Battle.from_dict(JSON.parse_string(JSON.stringify(b.to_dict())))
	assert_eq(c.next_wave_round(), 3, "подкрепление после загрузки на месте")
	_skip_to_round(c, 3)
	assert_eq(_count(c, "raised"), 2, "и выходит в свой раунд")
	var p := _battle("prologue_3")
	var q := Battle.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_true(q.get_unit("garret").has_status("bound"), "связанный остаётся связанным")
	_skip_to_round(q, 2)
	assert_false(q.get_unit("garret").has_status("bound"), "и освобождается во втором раунде")


func test_ai_finishes_every_prologue_battle() -> void:
	for bid in PROLOGUE:
		for diff in ["story", "trial"]:
			var r := Simulator.run_battle(bid, "wizard", "", "full", diff, 11)
			assert_true(["victory", "defeat"].has(String(r.outcome)), "%s (%s) заканчивается: %s" % [bid, diff, r.outcome])
