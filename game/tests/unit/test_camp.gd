extends GutTest
## Лагерь между главами: повышение уровня с веткой (выбор на 2 уровне, смена дальше) и торговец.

const HERO := {"class": "fighter", "hero_f": false, "name": "Ардан", "spouse_f": true, "spouse_id": "eila", "spouse_name": "Эйла"}


## Играть первыми вариантами до первого ответа нужного вида ("levelup" или "shop").
func _play_to(s: StorySession, kind: String, branch := "berserker") -> Dictionary:
	for i in 20000:
		var item := s.next()
		match String(item.type):
			"choices":
				s.choose(0)
			"battle":
				s.win_battle(0)
			"levelup":
				if kind == "levelup":
					return item
				s.choose_branch(branch)
			"shop":
				if kind == "shop":
					return item
				s.leave_shop([])
			"end":
				break
	return {}


func _new(silver_hint := 0) -> StorySession:
	var s := StorySession.new()
	s.new_game({"hero": HERO, "difficulty": "story"}, "ru")
	return s


func test_levelup_two_picks_branch() -> void:
	var s := _new()
	var item := _play_to(s, "levelup")
	assert_eq(int(item.get("level", 0)), 2, "первое повышение — 2 уровень в лагере главы 1")
	assert_eq(s.scene_name(), "camp1")
	assert_eq(s.next().type, "levelup", "история ждёт выбора ветки")
	s.choose_branch("berserker")
	assert_eq(s.state.branch, "berserker")
	assert_eq(s.state.level, 2)
	assert_ne(s.next().type, "levelup", "после выбора история идёт дальше")
	# Бой на 2 уровне — с умениями ветки.
	var h := CombatData.make_hero("fighter", 2, s.state.hero_branch())
	assert_true(h.abilities.has("rage"), "у берсерка «Ярость»")


func test_branch_switch_at_next_camp_and_replay() -> void:
	var s := _new()
	_play_to(s, "levelup")
	s.choose_branch("berserker")
	var item := _play_to(s, "levelup", "berserker")
	assert_eq(int(item.level), 3, "лагерь главы 2 — 3 уровень")
	s.choose_branch("guardian")
	assert_eq(s.state.branch, "guardian", "ветку сменили")
	var h := CombatData.make_hero("fighter", 3, s.state.hero_branch())
	assert_true(h.traits.has("protector"), "умения новой ветки пришли сразу по уровню")
	assert_false(h.abilities.has("rage"))
	# Журнал проигрывается с начала (другая версия истории) и даёт ту же ветку.
	var d := s.to_save()
	d.story_hash = "other"
	var b := StorySession.new()
	b.load_save(d)
	assert_eq(b.state.branch, "guardian")
	assert_eq(b.state.level, 3)


func test_shop_buys_into_inventory() -> void:
	var s := _new()
	var item := _play_to(s, "shop")
	assert_true(["sutler", "smith"].has(String(item.id)), "в лагере главы 1 торговец")
	var stock := Shops.stock(String(item.id))
	assert_false(stock.is_empty())
	var before := s.state.silver
	var cheap: Dictionary = stock[0]
	for st in stock:
		if int(st.price) < int(cheap.price):
			cheap = st
	s.leave_shop([[cheap.id, "garret"], ["no_such_item", "hero"]])
	if before >= int(cheap.price):
		assert_eq(s.state.silver, before - int(cheap.price), "серебро списано")
		assert_true(s.state.items_of("garret").has(String(cheap.id)), "вещь у Гаррета")
	else:
		assert_eq(s.state.silver, before, "денег не хватило — покупки нет")
	assert_ne(s.next().type, "shop", "от торговца ушли")


func test_shop_prices_and_fit() -> void:
	assert_eq(Shops.price("sutler", "sutler_quilt"), 35)
	assert_eq(Shops.price("smith", "sutler_quilt"), 25, "кузнец на 25% дешевле, до 5")
	assert_eq(Shops.price("smith", "village_mail"), 70)
	assert_eq(Shops.price("sutler", "village_mail"), -1, "кольчугу продаёт только кузнец")
	assert_false(Shops.fits("sutler", "sutler_censer", "garret"), "кадило — жрецу и Ирене")
	assert_true(Shops.fits("sutler", "sutler_censer", "irena"))


func test_owned_items_join_battle_kit() -> void:
	var sc := CombatData.scenario("chapter1_1", "fighter", "", "full", "story", "kit", {}, {"hero": ["sutler_quilt"], "garret": ["miner_charm"]})
	var hero: Combatant = sc.units[0]
	assert_true(hero.items.has("sutler_quilt"), "купленная стёганка надета")
	var garret: Combatant = null
	for u in sc.units:
		if u.kind == "garret":
			garret = u
	assert_true(garret.items.has("miner_charm"), "оберег у Гаррета")
