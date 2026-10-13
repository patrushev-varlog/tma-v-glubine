extends GutTest
## Пролог как демо (поток H): Тьма по канону, дары после допроса, конец демо на входе в главу 1
## и перенос сохранения демо в полную игру.

const HERO := {"class": "rogue", "hero_f": true, "name": "Кая", "spouse_f": true, "spouse_id": "eila", "spouse_name": "Эйла"}


func before_each() -> void:
	SaveStore.dir = "user://test_saves_prologue/"
	for slot in SaveStore.slots():
		SaveStore.remove(slot)
	SaveStore.remove("battle")


func after_each() -> void:
	SaveStore.dir = SaveStore.DIR
	Game.demo_forced = false
	Game.session = null


## Играть до первой сцены главы 1: pick — какой вариант выбирать (0 — первый, -1 — последний).
func _play_prologue(s: StorySession, pick: int) -> Array[String]:
	var battles: Array[String] = []
	for i in 5000:
		if s.chapter_name() != "prologue":
			break
		var item := s.next()
		match String(item.type):
			"choices":
				s.choose(pick if pick >= 0 else item.options.size() - 1)
			"battle":
				battles.append(String(item.id))
				s.win_battle(0)
			"end":
				break
	return battles


func test_prologue_darkness_and_gifts() -> void:
	for cls in ["fighter", "rogue", "cleric", "wizard"]:
		for pick in [0, -1]:
			var hero := HERO.duplicate()
			hero["class"] = cls
			var s := StorySession.new()
			s.new_game({"hero": hero, "difficulty": "story"}, "ru")
			var battles := _play_prologue(s, pick)
			var tag := "%s, выбор %d" % [cls, pick]
			assert_eq(s.scene_name(), "gate", "пролог ведёт в главу 1: " + tag)
			assert_eq(s.state.chapter, 1, "титр главы 1 показан: " + tag)
			assert_eq(battles.size(), 4, "четыре боя пролога: %s %s" % [tag, battles])
			assert_true(s.darkness() <= 20, "Тьма за пролог не выше 20 (DESIGN.md, таблица): %s — %d" % [tag, s.darkness()])
			assert_true(s.state.unlocks.has("dark_gifts"), "дары открыты после допроса: " + tag)
	# Самые тёмные выборы (последние варианты: за телегой, допрос мёртвого) дают ровно потолок пролога.
	var dark := StorySession.new()
	dark.new_game({"hero": HERO, "difficulty": "story"}, "ru")
	_play_prologue(dark, -1)
	assert_eq(dark.darkness(), 20, "телега и допрос мёртвого — по +10")


func test_demo_ends_at_chapter_1_and_save_carries_over() -> void:
	Game.demo_forced = true
	Game.new_game({"hero": HERO, "difficulty": "story"})
	var s := Game.session
	while s.scene_name() != "interrogation_scene":
		var item := s.next()
		if item.type == "choices":
			s.choose(0)
		elif item.type == "battle":
			s.win_battle(0)
	assert_ne(Game.screen_path(), Game.DEMO_END_SCENE, "допрос ещё в демо")
	_play_prologue(s, 0)
	assert_eq(Game.screen_path(), Game.DEMO_END_SCENE, "вход в главу 1 — конец демо")
	var auto := SaveStore.read("auto")
	assert_eq(String(auto.get("scene", "")), "gate", "автосохранение на входе в главу 1")
	# Полная игра грузит то же сохранение и продолжает главу 1.
	Game.demo_forced = false
	var tail := Game.load_from("auto")
	assert_eq(Game.session.scene_name(), "gate", "полная игра продолжает с главы 1")
	assert_eq(Game.screen_path(), "res://scenes/story_screen.tscn", "в полной игре дальше экран истории")
	assert_false(tail.is_empty(), "первая строка главы 1 на экране")
	assert_true(Game.session.state.unlocks.has("dark_gifts"), "дары перенеслись")


## Английский пролог устроен так же, как русский: те же выборы, теги, бои и флаги. На этом держится
## перенос сохранения при смене языка (журнал выборов проигрывается на другом тексте).
func test_english_prologue_matches_russian() -> void:
	assert_true(StoryRunner.languages().has("en"), "английская история собрана (story/ink-en/game.ink)")
	for seed_value in [1, 7, 42]:
		var runs := []
		for lang in ["ru", "en"]:
			var s := StorySession.new()
			s.new_game({"hero": HERO, "difficulty": "story"}, lang)
			var trace := PackedStringArray()
			var rng: int = seed_value
			for i in 5000:
				if s.chapter_name() != "prologue":
					break
				var item := s.next()
				match String(item.type):
					"line":
						var tags := PackedStringArray()
						for t in item.tags:
							tags.append(String(t).strip_edges())
						trace.append("L:" + ",".join(tags))
					"choices":
						rng = (rng * 1103515245 + 12345) % 2147483648
						trace.append("C:%d" % item.options.size())
						s.choose(rng % item.options.size())
					"battle":
						trace.append("B:" + String(item.id))
						s.win_battle(0)
			var flags := s.flags()
			flags.erase("spouse_name")
			runs.append({"trace": trace, "flags": flags, "scene": s.scene_name()})
		assert_eq(runs[1].scene, "gate", "английский пролог доходит до главы 1")
		assert_eq(runs[1].flags, runs[0].flags, "флаги совпадают, прогон %d" % seed_value)
		var a: PackedStringArray = runs[0].trace
		var b: PackedStringArray = runs[1].trace
		var first_diff := -1
		for i in mini(a.size(), b.size()):
			if a[i] != b[i]:
				first_diff = i
				break
		assert_eq(first_diff, -1, "теги и выборы совпадают, прогон %d: %s" % [seed_value,
			"" if first_diff < 0 else "%s / %s" % [a[first_diff], b[first_diff]]])
		assert_eq(a.size(), b.size(), "число строк совпадает, прогон %d" % seed_value)
