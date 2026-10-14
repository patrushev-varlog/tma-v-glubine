extends GutTest
## Локация (поток G): карта двора Эшмура, пути, объекты из тегов #obj: в Ink, экран локации
## с переходом в бой и обратно, сохранение позиции на карте.

const HERO := {"class": "wizard", "hero_f": false, "name": "Ардан", "spouse_f": true, "spouse_id": "eila",
	"spouse_name": "Эйла", "archetype": "evoker"}

var _shots_dir := ""


func before_each() -> void:
	SaveStore.dir = "user://test_saves_location/"


func after_all() -> void:
	SaveStore.dir = SaveStore.DIR


# --- Карта -----------------------------------------------------------------------------

func test_index_names_real_scenes_and_maps() -> void:
	var s := StorySession.new()
	var names := s.scenes.map(func(x: Dictionary) -> String: return String(x.scene))
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LocationMap.DIR + "index.json"))
	assert_gt(index.scenes.size(), 0)
	for scene in index.scenes:
		assert_has(names, scene, "сцена %s есть в истории" % scene)
		var m := LocationMap.load_location(String(index.scenes[scene]))
		m.setup_scene(scene)
		assert_true(m.walkable(m.spawn_of(scene)), "точка входа сцены %s проходима" % scene)
	assert_eq(LocationMap.for_scene("evening"), "", "вечер дома идёт без карты")


func test_ground_and_objects_fit_map() -> void:
	var m := LocationMap.load_location("ashmoor")
	assert_eq(m.ground.size(), m.size.x * m.size.y, "пол на каждой клетке")
	for scene in ["raid", "ashes"]:
		m.setup_scene(scene)
		var seen := {}
		for o in m.objects:
			for c in m.cells_of(o):
				assert_true(m.ground.has(c), "%s внутри карты" % o.id)
				if o.solid:
					assert_false(seen.has(c), "%s не налезает на %s" % [o.id, seen.get(c, "")])
					seen[c] = o.id


func test_path_goes_around_solid_objects() -> void:
	var m := LocationMap.load_location("ashmoor")
	m.setup_scene("ashes")
	var house := m.object("hero_house")
	var p := m.path(Vector2i(3, 10), Vector2i(7, 10))
	assert_false(p.is_empty(), "путь вокруг дома есть")
	for c in p:
		assert_false(m.cells_of(house).has(c), "путь не проходит сквозь дом")
		assert_true(m.walkable(c))
	assert_true(m.path(Vector2i(3, 10), house.cell).is_empty(), "в дом не войти")


func test_reach_cells_are_next_to_object() -> void:
	var m := LocationMap.load_location("ashmoor")
	m.setup_scene("ashes")
	var cart := m.object("cart")
	var reach := m.reach_cells(cart)
	assert_gt(reach.size(), 0)
	for c in reach:
		var near := false
		for oc in m.cells_of(cart):
			near = near or (absi(c.x - oc.x) <= 1 and absi(c.y - oc.y) <= 1)
		assert_true(near and m.walkable(c))
	var r := m.path_to_object(m.spawn_of("ashes"), cart)
	assert_true(r.ok)
	assert_true(reach.has(r.path[-1]), "путь кончается рядом с телегой")


func test_conditions_pick_objects() -> void:
	var m := LocationMap.load_location("ashmoor")
	m.setup_scene("ashes", func(c: String) -> bool: return c == "buried_neighbors")
	assert_false(m.object("graves").is_empty(), "после похорон — могилы")
	assert_true(m.object("bodies").is_empty())
	m.setup_scene("ashes", func(c: String) -> bool: return c == "!buried_neighbors")
	assert_true(m.object("graves").is_empty())
	assert_false(m.object("bodies").is_empty(), "до похорон — тела")
	m.setup_scene("raid", func(c: String) -> bool: return c == "!won:prologue_1")
	assert_false(m.object("dead_1").is_empty(), "мертвецы до боя")
	assert_true(m.object("oldrik").is_empty(), "Олдрик только утром")


## Каждый вариант с тегом #obj: в сценах на картах — объект этой карты, до которого можно дойти.
func test_every_obj_tag_has_reachable_object() -> void:
	var found := {}
	for seed_value: int in [1, 2, 3, 4, 5, 6]:
		var s := StorySession.new()
		s.new_game({"hero": HERO, "difficulty": "story"}, "ru")
		var rng: int = seed_value
		for i in 6000:
			var item := s.next()
			if item.type == "end" or not ["prologue", "chapter1"].has(s.chapter_name()):
				break
			if item.type == "battle":
				s.win_battle(0)
			elif item.type == "levelup":
				s.choose_branch(String(s.state.hero.archetype))
			elif item.type == "shop":
				s.leave_shop([])
			elif item.type == "choices":
				var loc := LocationMap.for_scene(s.scene_name())
				for obj in item.objects:
					if obj == "":
						continue
					assert_ne(loc, "", "#obj:%s в сцене с картой" % obj)
					var m := LocationMap.load_location(loc)
					m.setup_scene(s.scene_name(), func(c: String) -> bool: return _check(s, c))
					var o := m.object(obj)
					assert_false(o.is_empty(), "объект %s есть на карте" % obj)
					assert_true(m.path_to_object(m.spawn_of(s.scene_name()), o).ok, "до %s можно дойти" % obj)
					found[obj] = true
				rng = (rng * 1103515245 + 12345) % 2147483648
				s.choose(rng % item.options.size())
	for obj in ["oldrik", "cart", "list", "road", "drift_on", "hearth", "guardroom", "gallery_end", "lever"]:
		assert_true(found.has(obj), "объект %s встретился" % obj)


## Объекты для свободного осмотра (поле explore): до них можно дойти, а узел Ink есть в истории.
func test_explore_objects_reachable_and_known() -> void:
	var story := FileAccess.get_file_as_string("res://story/game.ru.json")
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LocationMap.DIR + "index.json"))
	var seen := 0
	for scene in index.scenes:
		var m := LocationMap.load_location(String(index.scenes[scene]))
		m.setup_scene(scene)
		assert_eq(m.ground.size() > 0, true)
		for o in m.objects:
			for c in m.cells_of(o):
				assert_true(m.ground.has(c), "%s (%s) внутри пола карты" % [o.id, scene])
			if not o.has("explore"):
				continue
			seen += 1
			assert_true(story.contains('"%s"' % o.explore), "узел %s есть в истории" % o.explore)
			assert_ne(tr(String(o.label)), String(o.label), "подпись %s переведена" % o.label)
			assert_true(m.path_to_object(m.spawn_of(scene), o).ok, "до %s можно дойти в сцене %s" % [o.id, scene])
	assert_eq(seen, 14, "шесть мест осмотра главы 1 и восемь главы 2 (у вожака беглых два вида)")


func _check(s: StorySession, cond: String) -> bool:
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


# --- Экран локации ------------------------------------------------------------------------

## До первой строки сцены scene; возвращает эту строку.
func _story_to(scene: String) -> Dictionary:
	Game.new_game({"hero": HERO, "difficulty": "story"})
	for i in 2000:
		var item := Game.session.next()
		if item.type == "line" and String(item.get("scene", "")) == scene:
			return item
		if item.type == "choices":
			Game.session.choose(0)
		elif item.type == "battle":
			Game.session.win_battle(0)
	fail_test("не дошли до сцены " + scene)
	return {}


func _screen(first: Dictionary) -> Node:
	Game.pending_tail = [first]
	var sc: Node = load("res://scenes/location_screen.tscn").instantiate()
	sc.change_screen = func(path: String) -> void: sc.set_meta("went", path)
	add_child_autofree(sc)
	await wait_physics_frames(3)
	return sc


## Экран локации после возврата с экрана боя: хвоста истории нет, он продолжает сам.
func _screen_resume() -> Node:
	Game.pending_tail = []
	var sc: Node = load("res://scenes/location_screen.tscn").instantiate()
	sc.change_screen = func(path: String) -> void: sc.set_meta("went", path)
	add_child_autofree(sc)
	await wait_physics_frames(3)
	return sc


## Нажимать «Далее» и первый вариант, пока экран не придёт в нужный режим.
func _until(sc: Node, mode: String, limit := 200) -> void:
	for i in limit:
		if sc._mode == mode or sc.has_meta("went"):
			return
		match String(sc._mode):
			"line":
				sc._advance()
			"choices":
				sc._choose(0)
			_:
				return


func test_raid_battle_and_back() -> void:
	assert_eq(Game.screen_path(), "res://scenes/story_screen.tscn", "до игры — экран истории")
	var first := _story_to("raid")
	assert_eq(Game.screen_path(), "res://scenes/location_screen.tscn", "облава идёт на карте")
	var sc: Node = await _screen(first)
	assert_eq(sc._mode, "line")
	assert_eq(sc._text.text, String(first.text), "первая строка сцены в панели")
	assert_eq(sc._map.variant, "night")
	assert_false(sc._map.object("dead_1").is_empty(), "мертвецы у изгороди")
	_until(sc, "battle")
	assert_eq(sc._mode, "battle", "дошли до боя")
	sc._start_battle()
	await wait_seconds(0.5)
	assert_eq(sc.get_meta("went", ""), Game.BATTLE_SCENE, "переход на экран боя")
	assert_not_null(Game.battle, "бой начат")
	assert_eq(Game.battle_return_scene, "res://scenes/location_screen.tscn", "после боя — обратно на карту")
	Game.finish_battle(1)
	assert_eq(Game.session.state.battles.get("prologue_1", 0), 1, "бой засчитан")
	sc.queue_free()
	sc = await _screen_resume()
	assert_eq(sc._mode, "line", "после боя история идёт дальше на карте")
	assert_true(sc._map.object("dead_1").is_empty(), "мертвецов на карте больше нет")
	assert_false(sc._map.object("brandt").is_empty(), "у телеги Брандт")
	_until(sc, "leaving")
	await wait_seconds(0.5)
	assert_eq(sc.get_meta("went", ""), "res://scenes/location_screen.tscn", "пепелище — тот же двор утром")
	assert_eq(Game.pending_tail[0].get("scene", ""), "ashes")


func test_ashes_walk_talk_inspect_save() -> void:
	var first := _story_to("ashes")
	var sc: Node = await _screen(first)
	assert_eq(sc._map.variant, "morning")
	_until(sc, "roam")
	assert_eq(sc._mode, "roam", "история ждёт, пока герой подойдёт к погребу")
	assert_true(sc._choice_obj.has("oldrik"))
	assert_false(sc._panel.visible, "панель убрана, можно ходить")
	assert_eq(sc._goals.get_child_count(), 2, "на экране список того, что можно сделать")

	# Клик по Олдрику: герой идёт к погребу и заговаривает с ним.
	var start: Vector2i = sc._view.hero.cell
	sc._click(sc._map.object("oldrik").cell)
	assert_true(sc._view.hero.is_moving())
	await wait_seconds(1.6)
	assert_ne(sc._view.hero.cell, start)
	assert_eq(sc._mode, "line", "разговор начался")
	assert_eq(Game.session.map_pos.location, "ashmoor", "позиция на карте в сессии")

	# Похоронить (первый вариант) и дойти до улик.
	_until(sc, "roam")
	assert_true(sc._choice_obj.has("cart") and sc._choice_obj.has("list") and sc._choice_obj.has("road"))
	assert_false(sc._map.object("graves").is_empty(), "после похорон на дворе Хаскеров могилы")

	# Клавиатура и геймпад: шаг стиком по экрану.
	var before: Vector2i = sc._view.hero.cell
	Input.action_press("ui_left")
	await wait_seconds(0.5)
	Input.action_release("ui_left")
	await wait_seconds(0.3)
	assert_ne(sc._view.hero.cell, before, "шаг с клавиатуры")
	assert_lt(sc._view.cell_center(sc._view.hero.cell).x, sc._view.cell_center(before).x, "влево по экрану")

	# Сохранение посреди карты и загрузка — герой там же.
	var pos: Vector2i = sc._view.hero.cell
	assert_eq(Game.save_to("quick"), OK)
	Game.load_from("quick")
	assert_eq(Game.screen_path(), "res://scenes/location_screen.tscn")
	assert_eq(Vector2i(int(Game.session.map_pos.x), int(Game.session.map_pos.y)), pos, "позиция загрузилась")

	# Телега: подойти и осмотреть (Enter рядом), потом уйти по колее.
	var sc2: Node = await _screen({"type": "line", "text": "…", "tags": PackedStringArray()})
	assert_eq(sc2._view.hero.cell, pos, "после загрузки герой на том же месте")
	sc2._advance()
	assert_eq(sc2._mode, "roam")
	var r: Dictionary = sc2._map.path_to_object(sc2._view.hero.cell, sc2._map.object("cart"))
	sc2._view.hero.walk(r.path)
	await wait_seconds(0.25 * r.path.size() + 0.3)
	assert_eq(sc2._reachable_active(), "cart")
	sc2._interact("cart")
	_until(sc2, "roam")
	assert_false(sc2._choice_obj.has("cart"), "телегу второй раз не осматривают")
	sc2._interact("road")
	_until(sc2, "leaving")
	await wait_seconds(0.5)
	assert_eq(sc2.get_meta("went", ""), "res://scenes/story_screen.tscn", "храм — снова экран истории")
	assert_eq(Game.session.state.chapter, 0)


## Глава 1 на картах: бунт, закоулки и подсказки осмотром объектов, у рычага Гаррет останавливает,
## штрек за досками ведёт к бою со штейгером. Сюжет между картами проходится без экрана.
func test_chapter1_hunt_on_maps() -> void:
	var first := _story_to("gate")
	var sc: Node = await _screen(first)
	assert_eq(sc._map.id, "mine_gate")
	_until(sc, "battle")
	Game.start_battle(1)
	Game.finish_battle(0)
	sc.queue_free()
	sc = await _screen_resume()
	_until(sc, "roam")
	assert_eq(sc._mode, "roam", "после боя у поста можно ходить")
	assert_true(sc._choice_obj.has("drift_on"))
	assert_true(sc._explore_obj.has("holt_hut") and sc._explore_obj.has("face"), "караулка и забой для осмотра")
	assert_eq(sc._goals.get_child_count(), 2, "в списке целей только выход")
	sc._interact("face")
	assert_eq(Game.session.flow, "explore", "осмотр идёт в отдельном потоке")
	_until(sc, "roam")
	assert_true(Game.session.flag("ch1_nook_face_done"), "забой осмотрен")
	assert_true(sc._choice_obj.has("drift_on"), "после осмотра снова ходим")
	sc._interact("holt_hut")
	_until(sc, "roam")
	assert_eq(int(Game.session.flag("ch1_hunt_clues")), 2, "две подсказки: зарубки и карта Хольта")
	sc._interact("drift_on")
	_until(sc, "leaving")
	await wait_seconds(0.5)
	sc.queue_free()

	# Клетка: кладовая крепи; бараки: бунт и старый узник — без экрана, через сессию.
	var s := Game.session
	var explored := false
	for i in 3000:
		var item := s.next()
		if s.scene_name() == "lift" and item.type == "choices" and item.objects.has("lever"):
			break
		match String(item.type):
			"battle":
				s.win_battle(0)
			"levelup":
				s.choose_branch(String(s.state.hero.archetype))
			"shop":
				s.leave_shop([])
			"choices":
				if s.scene_name() == "cage" and item.objects.has("hearth") and not explored:
					s.explore("ch1_nook_timber")
					explored = true
					continue
				var pick := 0
				for k in item.options.size():
					if String(item.options[k]).begins_with("Поднять бунт"):
						pick = k
				s.choose(pick)
	assert_true(s.flag("ch1_nook_timber_done"), "крепь из кладовой у Гаррета")
	assert_eq(String(s.flag("ch1_choice")), "riot")

	# Подъёмник: у рычага Гаррет останавливает, герой возвращается и идёт в штрек.
	sc = await _screen({"type": "line", "text": "…", "tags": PackedStringArray()})
	assert_eq(sc._map.id, "mine_lift")
	sc._advance()
	assert_eq(sc._mode, "roam")
	assert_false(sc._map.object("prisoner_1").is_empty(), "после бунта узники на площадке")
	sc._interact("lever")
	assert_eq(sc._mode, "line", "Гаррет придержал за плечо")
	_until(sc, "choices")
	sc._choose(0)
	_until(sc, "roam")
	assert_eq(sc._mode, "roam", "решили вернуться: остаёмся на площадке")
	assert_eq(s.scene_name(), "lift")
	sc._interact("drift_boards")
	_until(sc, "battle")
	assert_eq(sc._mode, "battle", "за досками штейгер")
	assert_eq(s.pending_battle, "ch1_hunt_foreman")
	Game.start_battle(1)
	Game.finish_battle(0)
	sc.queue_free()
	sc = await _screen_resume()
	_until(sc, "roam")
	assert_true(s.flag("ch1_hunt_done"), "фонарь у отряда")
	assert_true(s.state.items_of("hero").has("foreman_lantern"))
	# Теперь рычаг уводит сразу: охота закрыта.
	sc._interact("lever")
	assert_ne(sc._mode, "roam")
	assert_true(LocationMap.truthy(s.flag("hunt_leave_ok")), "проверка охоты пропускает")
