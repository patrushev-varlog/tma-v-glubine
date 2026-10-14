extends GutTest
## Бои главы 1 (docs/CHAPTER1_BATTLES.md): свои карты, узники-союзники под ИИ, засада под видом конвоя,
## подкрепления по флагам выбора в бараках, добыча серебра.

const CH1 := ["chapter1_1", "chapter1_2_riot", "chapter1_2_patrol", "chapter1_3", "ch1_hunt_foreman"]


func _battle(bid: String, diff := "story", flags := {}, seed_value := 3) -> Battle:
	var b := Battle.new()
	b.setup(CombatData.scenario(bid, "fighter", "", "full", diff, "kit", flags), seed_value, diff)
	return b


func _allies(b: Battle) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for u in b.units:
		if u.ai_ally:
			out.append(u)
	return out


func test_every_chapter1_battle_tag_has_battle() -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../story/ink/chapter1/")
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
	assert_eq(tags.size(), 7, "семь тегов боя в главе 1 (у ворот три пути к одному бою)")
	for t in tags:
		assert_true(CombatData.table("battles").has(t), "бой %s из главы 1 есть в battles.json" % t)


func test_party_with_velior_after_cage() -> void:
	assert_eq(_battle("chapter1_1").heroes().size(), 3, "у поста Велиора ещё нет")
	for bid in ["chapter1_2_riot", "chapter1_2_patrol", "chapter1_3", "ch1_hunt_foreman"]:
		var kinds := []
		for h in _battle(bid).heroes():
			kinds.append(h.kind)
		assert_true(kinds.has("velior"), "Велиор в бою %s" % bid)


func test_riot_prisoners_are_ai_allies() -> void:
	var b := _battle("chapter1_2_riot")
	var al := _allies(b)
	assert_eq(al.size(), 4, "четверо узников")
	for u in al:
		assert_eq(u.team, 0, "узник на стороне отряда")
		assert_true(b.ai_turn(u), "узник ходит сам")
		assert_false(b.heroes().has(u), "узник не в отряде игрока")
	assert_false(b.ai_turn(b.heroes()[0]), "героя ведёт игрок")
	# Отряд выбыл, узники ещё стоят — поражение.
	for h in b.heroes():
		h.hp = 0
		h.down = true
	b._check_outcome()
	assert_eq(b.outcome, "defeat", "узники не спасают от поражения")


func test_lift_riot_adds_guards_and_prisoners() -> void:
	var slip := _battle("chapter1_3", "story", {"ch1_choice": "slip"})
	var riot := _battle("chapter1_3", "story", {"ch1_choice": "riot"})
	assert_eq(_allies(slip).size(), 0, "при тихом проходе помощи нет")
	assert_eq(_allies(riot).size(), 3, "при бунте узники идут следом")
	assert_eq(riot.enemies().size(), slip.enemies().size() + 2, "при бунте стражи больше")


func test_gate_disguise_surprises_post() -> void:
	var b := _battle("chapter1_1", "story", {"ch1_gate_disguise": true})
	for e in b.enemies():
		assert_true(e.has_status("surprised"), "%s застигнут врасплох" % e.name)
	var plain := _battle("chapter1_1")
	assert_false(plain.enemies()[0].has_status("surprised"))


func test_ai_finishes_every_chapter1_battle() -> void:
	for bid in CH1:
		for diff in ["story", "trial"]:
			var r := Simulator.run_battle(bid, "wizard", "", "full", diff, 11, false, "kit", {"ch1_choice": "riot"})
			assert_true(["victory", "defeat"].has(String(r.outcome)), "%s (%s) заканчивается: %s" % [bid, diff, r.outcome])


func test_battle_loot_silver() -> void:
	for bid in CH1:
		assert_gt(int(CombatData.table("battles")[bid].get("silver", 0)), 0, "добыча за %s" % bid)
