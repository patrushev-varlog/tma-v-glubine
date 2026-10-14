extends GutTest
## Бои главы 3 (docs/CHAPTER3_BATTLES.md): каменная броня стражей, архивариусы, которые не уходят из зала,
## Торвин с отбрасывающим молотом; кузница Молчащих (перенос свойства); глава целиком до уровня 4.

const A := preload("res://tests/helpers/arena.gd")
const CH3 := ["chapter3_1", "chapter3_2", "chapter3_3"]
const HERO := {"class": "fighter", "hero_f": false, "name": "Ардан", "spouse_f": true, "spouse_id": "eila",
	"spouse_name": "Эйла", "archetype": "guardian"}


func _battle(bid: String, diff := "story", flags := {}, seed_value := 3) -> Battle:
	var b := Battle.new()
	b.setup(CombatData.scenario(bid, "fighter", "guardian", "full", diff, "kit", flags), seed_value, diff)
	return b


func test_every_chapter3_battle_tag_has_battle() -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../story/ink/chapter3/")
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
	assert_eq(tags, CH3, "три боя главы 3: арки, архив, хранитель")
	for t in tags:
		assert_eq(int(CombatData.table("battles")[t].level), 3, "%s на 3 уровне: уровень 4 — в лагере после суда" % t)


func test_full_party_with_velior() -> void:
	for bid in CH3:
		var kinds := []
		for h in _battle(bid).heroes():
			kinds.append(h.kind)
		assert_eq(kinds.size(), 4, "%s: герой и трое спутников — суд над Велиором после боёв" % bid)
		assert_true(kinds.has("velior"), "Велиор в бою %s" % bid)


func test_wardens_are_stone() -> void:
	var b := _battle("chapter3_1")
	var g: Combatant = null
	for e in b.enemies():
		if e.kind == "stone_guardian":
			g = e
	assert_not_null(g, "в зале арок стражи Молчащих")
	assert_false(g.undead, "стражи — камень, а не нежить: изгнание нежити их не берёт")
	assert_true(b.log_lines.has(tr("BATTLE_LOG_CH3_STONE")), "в начале боя подсказка о каменной броне")
	var f := b.heroes()[0]
	assert_eq(b.stone_armor_against(f, g, f.weapon), 4, "меч воина теряет 4 урона")
	var wiz := CombatData.make_hero("wizard", 3, "evoker")
	assert_eq(b.stone_armor_against(wiz, g, wiz.weapon), 0, "посох — дробящее")


func test_archivists_stay_in_hall() -> void:
	var b := _battle("chapter3_2")
	var n := 0
	for e in b.enemies():
		if e.kind == "dwarf_archivist":
			n += 1
			assert_true(b.stage.tether.has(e.id), "архивариус не уходит от своих полок")
	assert_gt(n, 0)


func test_torvin_knocks_back() -> void:
	var b := _battle("chapter3_3")
	var t: Combatant = null
	for e in b.enemies():
		if e.kind == "torvin":
			t = e
	assert_not_null(t, "Торвин на галерее")
	var on_hit: Array = t.weapon.get("on_hit", [])
	assert_eq(String(on_hit[0].op), "shove", "молот отбрасывает")
	var f := A.at(CombatData.make_hero("fighter", 3, "guardian"), Vector2i(5, 5))
	f.saves = {"str": -30, "dex": -30, "con": 0, "wis": 0}
	var tv := A.at(CombatData.make_enemy("torvin", 1), Vector2i(4, 5))
	tv.weapon["to_hit"] = 99
	var ar := A.make([tv, f])
	ar.attack(tv, f)
	assert_eq(f.cell, Vector2i(6, 5), "после удара герой на клетку дальше")


func test_ai_finishes_every_chapter3_battle() -> void:
	for bid in CH3:
		for diff in ["story", "trial"]:
			var r := Simulator.run_battle(bid, "wizard", "", "full", diff, 11, false, "kit", {})
			assert_true(["victory", "defeat"].has(String(r.outcome)), "%s (%s) заканчивается: %s" % [bid, diff, r.outcome])


func test_battle_loot_silver() -> void:
	for bid in CH3:
		assert_gt(int(CombatData.table("battles")[bid].get("silver", 0)), 0, "добыча за %s" % bid)


# --- Кузница Молчащих ------------------------------------------------------------

func test_forge_item_properties() -> void:
	var h := CombatData.make_hero("fighter", 3, "guardian")
	assert_true(Items.forgeable("mine_greatsword"), "добротный двуручник можно ковать")
	assert_false(Items.forgeable("silent_legacy"), "легендарку — нельзя")
	assert_false(Items.forgeable("black_steel"), "тёмную вещь — нельзя")
	assert_false(Items.forgeable("mine_greatsword" + Items.FORGED), "второй перенос — нельзя")
	var it := Items.resolve("mine_greatsword" + Items.FORGED, h)
	assert_eq(String(it.fx.undead), "1d4", "оружию — +1d4 по нежити")
	var before := h.undead_dice
	Items.equip(h, ["mine_greatsword" + Items.FORGED])
	assert_ne(h.undead_dice, before, "кость по нежити встала на героя")
	var arm := Items.resolve("village_mail" + Items.FORGED, h)
	assert_eq(int(arm.fx.get("dr", 0)), int(Items.catalog().village_mail.fx.get("dr", 0)) + 1, "доспеху — снижение 1")


func test_forge_price_with_smith() -> void:
	assert_eq(Shops.forge_price("dwarf_forge", {}), 40)
	assert_eq(Shops.forge_price("dwarf_forge", {"column_choice": "neighbors"}), 30, "кузнец из Эшмура на 25% дешевле")


# --- Глава целиком ----------------------------------------------------------------

func _advance(s: StorySession, stop: String, pick: Callable, shop: Callable, seen: Array) -> bool:
	for i in 8000:
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
				var r: Array = shop.call(String(item.id))
				s.leave_shop(r[0], r[1])
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


func _to_chapter3() -> StorySession:
	var s := StorySession.new()
	s.new_game({"hero": HERO, "difficulty": "story"}, "ru")
	assert_true(_advance(s, "chapter3", _pick_by([]), func(_id: String) -> Array: return [[], []], []), "дошли до главы 3")
	return s


func test_chapter3_forgive_and_forge() -> void:
	var s := _to_chapter3()
	s.state.silver = 100
	s.state.inventory.append({"id": "dwarf_steel", "owner": "hero"})
	s.state.inventory.append({"id": "mine_greatsword", "owner": "garret"})
	var idx := s.state.inventory.size() - 1
	var seen := []
	var dark0 := int(s.darkness())
	var forged := [false]
	var ok := _advance(s, "chapter4", _pick_by(["Ответить: «Молчание»", "Читать", "Оставить мёртвого", "«Ты остаёшься", "Взять кинжал."]),
		func(id: String) -> Array:
			if id == "dwarf_forge" and not forged[0]:
				forged[0] = true
				return [[], [idx]]
			return [[], []], seen)
	assert_true(ok, "глава 3 пройдена до главы 4")
	for bid in CH3:
		assert_true(seen.has(bid), "бой %s" % bid)
	assert_true(seen.has("shop:dwarf_forge"), "горн Молчащих открыт")
	assert_true(seen.has("levelup:4"), "в лагере после суда — уровень 4")
	assert_eq(s.state.level, 4)
	assert_true(s.flag("ch3_riddle_solved"), "дверь открыта словом «молчание»")
	assert_eq(String(s.flag("velior_fate")), "forgiven")
	assert_true(s.state.items_of("hero").has("crown_dagger"), "Велиор отдал кинжал")
	assert_true(s.state.items_of("hero").has("silent_legacy"), "наследие дварфов от Торвина")
	assert_true(s.state.items_of("hero").has("silent_crown"), "венец за загадкой")
	var sword: Array = s.state.inventory.filter(func(x: Dictionary) -> bool: return String(x.id) == "mine_greatsword")
	assert_true(sword[0].get("forged", false), "двуручник Гаррета перекован")
	assert_eq(s.state.items_of("hero").count("dwarf_steel"), 0, "слиток ушёл в горн")
	assert_eq(int(s.darkness()), dark0, "без мёртвого и казни Тьма не растёт")
	assert_true(s.companions().has("velior"), "прощённый Велиор в отряде")


func test_chapter3_dead_spoke_and_kill() -> void:
	var s := _to_chapter3()
	var dark0 := int(s.darkness())
	var seen := []
	_advance(s, "chapter4", _pick_by(["Прислушаться к шёпоту", "Взять кинжал со стола"]),
		func(_id: String) -> Array: return [[], []], seen)
	assert_true(s.flag("ch3_dead_spoke"))
	assert_eq(String(s.flag("velior_fate")), "killed")
	assert_eq(int(s.darkness()) - dark0, 15, "мёртвый заговорил +5 и казнь +10")
	assert_false(s.companions().has("velior"), "Велиора больше нет в отряде")
	assert_true(s.state.items_of("hero").has("crown_dagger_taken"), "кинжал забран — тёмная вещь")
