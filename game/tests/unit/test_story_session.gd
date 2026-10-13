extends GutTest
## Модуль сюжета: прохождение всей истории, теги, флаги, отряд, журнал заданий и сохранения.

const HEROES := [
	{"class": "fighter", "hero_f": false, "name": "Ардан", "spouse_f": true, "spouse_id": "eila", "spouse_name": "Эйла"},
	{"class": "wizard", "hero_f": true, "name": "Мира", "spouse_f": false, "spouse_id": "taren", "spouse_name": "Тарен"},
	{"class": "rogue", "hero_f": false, "name": "Кай", "spouse_f": true, "spouse_id": "", "spouse_name": "Мирослава"},
	{"class": "cleric", "hero_f": true, "name": "Ода", "spouse_f": false, "spouse_id": "doran", "spouse_name": "Доран"},
]


func _new(hero: Dictionary, diff := "story") -> StorySession:
	var s := StorySession.new()
	s.new_game({"hero": hero, "difficulty": diff}, "ru")
	return s


## Играть до конца или до max_events событий; выборы — из одинакового генератора.
## Возвращает показанные строки (текст и теги одной строкой) — для сравнения прогонов.
func _play(s: StorySession, seed_value: int, max_events := -1) -> PackedStringArray:
	var out := PackedStringArray()
	var rng := seed_value
	var guard := 0
	while guard < 20000:
		guard += 1
		if max_events >= 0 and s.events.size() >= max_events:
			break
		var item := s.next()
		match String(item.type):
			"line":
				out.append("%s|%s" % [item.text, ",".join(item.tags)])
			"choices":
				rng = (rng * 1103515245 + 12345) % 2147483648
				var idx: int = rng % item.options.size()
				out.append("C>%d" % idx)
				s.choose(idx)
			"battle":
				out.append("B:" + String(item.id))
				s.win_battle(2 if s.state.combat_darkness < 20 else 0)
			"levelup":
				var arches := CombatData.archetypes_of(String(s.state.hero["class"]))
				var pick := String(arches[(rng + int(item.level)) % arches.size()])
				out.append("U:%d>%s" % [item.level, pick])
				s.choose_branch(pick)
			"shop":
				var stock := Shops.stock(String(item.id))
				var buy: Array = [[stock[0].id, "hero"]] if not stock.is_empty() and rng % 2 == 0 else []
				out.append("S:%s>%d" % [item.id, buy.size()])
				s.leave_shop(buy)
			"explore_end":
				out.append("E")
			"end":
				break
	return out


## Строки, которые загрузка вернула для экрана, в том же виде, что у _play.
func _lines(tail: Array[Dictionary]) -> PackedStringArray:
	var out := PackedStringArray()
	for item in tail:
		out.append("%s|%s" % [item.text, ",".join(item.tags)])
	return out


## После загрузки игра идёт так же. Строки до первой остановки загрузка показывает с начала сцены,
## поэтому они должны быть концом того, что увидел бы игрок без сохранения.
func _same_after_load(loaded: PackedStringArray, cont: PackedStringArray, what: String) -> void:
	var stop_l := _first_stop(loaded)
	var stop_c := _first_stop(cont)
	assert_gt(stop_l, 0, what + ": на экране есть строки")
	assert_eq(cont.slice(stop_c - stop_l, stop_c), loaded.slice(0, stop_l), what + ": на экране те же строки")
	assert_eq(loaded.slice(stop_l), cont.slice(stop_c), what + ": дальше всё так же")


func _first_stop(lines: PackedStringArray) -> int:
	for i in lines.size():
		if lines[i].begins_with("C>") or lines[i].begins_with("B:"):
			return i
	return lines.size()


func test_full_playthrough() -> void:
	for i in HEROES.size():
		var s := _new(HEROES[i])
		var entered: Array[String] = []
		s.scene_entered.connect(func(scene: String) -> void: entered.append(scene))
		_play(s, 100 + i)
		assert_eq(s.next().type, "end", "%s: история дошла до конца" % HEROES[i].class)
		assert_eq(entered.size(), s.scenes.size(), "%s: вошли во все %d сцен по порядку" % [HEROES[i].class, s.scenes.size()])
		assert_eq(s.state.level, 5, "уровень отряда 5 к финалу (# levelup)")
		assert_eq(s.state.chapter, 5, "глава 5 (# chapter)")
		assert_true(["love", "peace", "guardian", "tyrant"].has(s.state.ending), "есть концовка: " + s.state.ending)
		assert_eq(String(s.flag("ending")), s.state.ending, "концовка в Ink и в состоянии совпадает")
		assert_true(s.state.unlocks.has("dark_gifts"), "тёмные дары открыты после пролога")
		assert_true(s.state.battles.size() >= 15, "пройдено боёв: %d" % s.state.battles.size())
		assert_eq(s.state.combat_darkness, 20, "боевая Тьма упёрлась в потолок 20")
		assert_between(s.darkness(), 0, 100, "шкала Тьмы в пределах")


func test_setup_vars() -> void:
	var s := _new(HEROES[1])
	assert_eq(String(s.flag("hero_class")), "wizard")
	assert_true(bool(s.flag("hero_f")) and not bool(s.flag("spouse_f")))
	assert_eq(String(s.flag("spouse_name")), "Тарен", "имя супруга из списка")
	var c := _new(HEROES[2])
	assert_eq(String(c.flag("spouse_name")), "Мирослава", "своё имя — как введено")
	assert_eq(StorySession.spouse_forms("eila", true, "ru").acc, "Эйлу", "винительный падеж")
	assert_eq(StorySession.spouse_forms("keiran", false, "en").nom, "Keiran", "английское имя")
	assert_true(StorySession.spouse_forms("", true, "ru").is_empty(), "у своего имени форм нет")


func test_tags_apply() -> void:
	var g := GameState.new()
	g.apply_tags(PackedStringArray(["item:gate_sword", "to:garret"]), "")
	g.apply_tags(PackedStringArray(["item:crown_dagger"]), "")
	g.apply_tags(PackedStringArray(["silver:30"]), "")
	g.apply_tags(PackedStringArray(["silver:-50"]), "")
	g.apply_tags(PackedStringArray(["journal:ch1_hunt_map"]), "Отметка в журнале: «Красный крест у ствола на карте Хольта».")
	g.apply_tags(PackedStringArray(["journal:ch1_hunt_map"]), "повтор")
	g.apply_tags(PackedStringArray(["rest:long", "levelup:3"]), "")
	g.apply_tags(PackedStringArray(["item_remove:crown_dagger"]), "")
	assert_eq(g.items_of("garret"), ["gate_sword"] as Array[String], "# to: отдаёт предмет спутнику")
	assert_eq(g.items_of("hero"), [] as Array[String], "# item_remove: забирает")
	assert_eq(g.silver, 0, "серебро не уходит в минус")
	assert_eq(g.journal.size(), 1, "запись журнала одна")
	assert_eq(g.journal[0].text, "Красный крест у ствола на карте Хольта", "текст записи — то, что в кавычках")
	assert_eq(g.level, 3)
	var back := GameState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	assert_eq(JSON.stringify(back.to_dict()), JSON.stringify(g.to_dict()), "состояние партии сохраняется")


func test_party_from_flags() -> void:
	var s := _new(HEROES[0])
	assert_eq(s.companions(), ["irena", "garret"] as Array[String], "в прологе без Велиора")
	s.runner.set_var("velior_terms", "free")
	s.state.level = 3
	assert_eq(s.party_key(), "full")
	s.runner.set_var("velior_fate", "exiled")
	assert_eq(s.party_key(), "no_velior", "изгнанный Велиор уходит")
	s.runner.set_var("irena_confronted", "left")
	assert_eq(s.party_key(), "duo", "Ирена ушла — остался Гаррет")


func test_combat_darkness_cap() -> void:
	var s := _new(HEROES[0])
	_play_until_battle(s)
	var before := s.darkness()
	s.state.combat_darkness = 19
	s.win_battle(5)
	assert_eq(s.state.combat_darkness, 20, "боевая Тьма не выше 20 за игру")
	assert_eq(s.darkness(), before + 1, "в шкалу Ink ушло столько же")


func _play_until_battle(s: StorySession) -> void:
	var rng := 7
	for i in 5000:
		var item := s.next()
		if item.type == "battle":
			return
		if item.type == "choices":
			rng = (rng * 1103515245 + 12345) % 2147483648
			s.choose(rng % item.options.size())


## Сохранить посреди игры, загрузить быстрым путём (состояние сцены + журнал внутри неё) и с начала
## (другая версия истории): дальше игра идёт так же, как без сохранения.
func test_save_load_matches_continuous_play() -> void:
	for cut in [0, 7, 23, 41, 60]:
		var a := _new(HEROES[cut % 4])
		_play(a, 900 + cut, cut)
		var save: Dictionary = JSON.parse_string(JSON.stringify(a.to_save()))
		var rest_a := _play(a, 5)
		var b := StorySession.new()
		var rest_b := _lines(b.load_save(save))
		assert_eq(b.events.size(), cut, "быстрая загрузка: журнал той же длины (%d)" % cut)
		rest_b.append_array(_play(b, 5))
		_same_after_load(rest_b, rest_a, "быстрая загрузка после %d событий" % cut)
		assert_eq(JSON.stringify(b.state.to_dict()), JSON.stringify(a.state.to_dict()), "состояние партии совпадает")
		assert_eq(b.flags(), a.flags(), "флаги Ink совпадают")
		var c := StorySession.new()
		save.story_hash = "другая версия"
		var rest_c := _lines(c.load_save(save))
		rest_c.append_array(_play(c, 5))
		_same_after_load(rest_c, rest_a, "загрузка с начала после %d событий" % cut)


func test_load_returns_screen_tail() -> void:
	var a := _new(HEROES[0])
	_play(a, 3, 12)
	var shown: Array[Dictionary] = []
	var item := a.next()
	while item.type == "line":
		shown.append(item)
		item = a.next()
	var b := StorySession.new()
	var tail := b.load_save(JSON.parse_string(JSON.stringify(a.to_save())))
	assert_eq(tail.size(), shown.size(), "после загрузки на экране те же строки")
	if tail.size() == shown.size() and tail.size() > 0:
		assert_eq(tail[-1].text, shown[-1].text)
	assert_eq(b.next().type, item.type, "и та же остановка")


func test_scene_entry_snapshot() -> void:
	var s := _new(HEROES[0])
	var entries := []
	s.scene_entered.connect(func(scene: String) -> void: entries.append(s.entry.duplicate()))
	_play(s, 11, 30)
	assert_gt(entries.size(), 1, "вошли в несколько сцен")
	for e in entries:
		assert_true(e.has("ink") and e.has("game") and e.has("log_index"), "снимок сцены %s полный" % e.scene)
	assert_eq(entries[0].scene, "evening", "первая сцена — вечер")
	assert_eq(int(entries[0].log_index), 0, "в первую сцену входим до первого выбора")


func test_explore_flow_and_replay() -> void:
	var a := _new(HEROES[2])
	# Доиграть до главы 1 и осмотреть закоулок в отдельном потоке.
	var rng := 21
	for i in 20000:
		var item := a.next()
		if item.type == "choices":
			if a.state.chapter >= 1:
				break
			rng = (rng * 1103515245 + 12345) % 2147483648
			a.choose(rng % item.options.size())
		elif item.type == "battle":
			a.win_battle(0)
	assert_eq(a.state.chapter, 1, "дошли до главы 1")
	var flags_before: Dictionary = a.flags()
	var choices_before: PackedStringArray = a.runner.choices()
	a.explore("ch1_nook_timber")
	var lines := 0
	var item := a.next()
	while item.type != "explore_end":
		if item.type == "line":
			lines += 1
		elif item.type == "choices":
			a.choose(0)
		item = a.next()
		if lines > 500:
			break
	assert_gt(lines, 0, "осмотр показал строки")
	assert_true(bool(a.flag("ch1_nook_timber_done")), "флаг осмотра поставлен")
	assert_ne(flags_before.ch1_nook_timber_done, a.flag("ch1_nook_timber_done"))
	assert_eq(a.runner.choices(), choices_before, "основной сюжет ждёт там же")
	var b := StorySession.new()
	var save: Dictionary = JSON.parse_string(JSON.stringify(a.to_save()))
	save.story_hash = "x"
	b.load_save(save)
	assert_eq(b.flags(), a.flags(), "осмотр проигрывается из журнала")
	assert_eq(JSON.stringify(b.state.to_dict()), JSON.stringify(a.state.to_dict()))


func test_quest_journal() -> void:
	var s := _new(HEROES[0])
	var q := QuestJournal.entries(s)
	assert_eq(q[0].id, "main_prologue", "главная цель пролога")
	s.state.journal.append({"id": "ch1_hunt_marks", "text": "Фонарь первого штейгера"})
	s.runner.set_var("ch1_hunt_clues", 1)
	q = QuestJournal.entries(s)
	var hunt: Dictionary = q.filter(func(e: Dictionary) -> bool: return e.id == "ch1_hunt")[0]
	assert_true(hunt.state == "active" and hunt.clues == 1 and hunt.clues_max == 3, "охота главы 1: 1 из 3")
	assert_eq(hunt.notes, ["Фонарь первого штейгера"] as Array[String], "записи журнала в задании")
	s.runner.set_var("ch1_hunt_done", true)
	hunt = QuestJournal.entries(s).filter(func(e: Dictionary) -> bool: return e.id == "ch1_hunt")[0]
	assert_eq(hunt.state, "done", "охота закрыта")
	for e in QuestJournal.entries(s):
		assert_ne(tr(e.title_key), e.title_key, "есть название задания %s" % e.id)


func test_save_store() -> void:
	SaveStore.dir = "user://test_saves/"
	for slot in SaveStore.slots() + ["battle"]:
		SaveStore.remove(slot)
	assert_eq(SaveStore.latest(), "", "сохранений нет")
	var s := _new(HEROES[0])
	_play(s, 1, 5)
	assert_eq(SaveStore.write("slot_2", s.to_save()), OK)
	assert_eq(SaveStore.write("quick", s.to_save()), OK)
	assert_eq(SaveStore.latest(), "quick", "самое свежее — быстрое")
	var d := SaveStore.read("slot_2")
	assert_eq(int(d.events.size()), 5)
	assert_false(FileAccess.file_exists(SaveStore.path_of("slot_2") + ".tmp"), "временный файл убран")
	SaveStore.remove("slot_2")
	SaveStore.remove("quick")
	SaveStore.dir = SaveStore.DIR
