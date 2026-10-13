class_name SelfTest
extends RefCounted
## Самопроверка собранной игры: «Тьма в глубине -- --selftest» (так её запускает CI на сборке Linux).
## Проходит всю историю с одинаковыми выборами, проводит бой силами ИИ, сохраняет и загружает.
## Печатает итог и возвращает код выхода: 0 — всё в порядке.


static func run() -> int:
	var fails := PackedStringArray()
	var t0 := Time.get_ticks_msec()
	if TranslationServer.translate("GAME_TITLE") == "GAME_TITLE" or TranslationServer.translate("ABILITY_fire_bolt") == "ABILITY_fire_bolt":
		fails.append("нет таблиц перевода")
	for t in ["abilities", "statuses", "traits", "classes", "companions", "enemies", "battles", "items", "rules"]:
		if CombatData.table(t).is_empty():
			fails.append("пустые данные " + t)
	# Бой: обе стороны ведёт ИИ.
	var r := Simulator.run_battle("level_1", "wizard", "", "full", "trial", 1)
	if not ["victory", "defeat"].has(r.outcome):
		fails.append("бой не закончился")
	# История целиком.
	var s := StorySession.new()
	s.new_game({"difficulty": "story", "hero": {"class": "cleric", "hero_f": true, "name": "Ода", "spouse_f": false,
		"spouse_id": "eivin", "spouse_name": "Эйвин", "archetype": "life"}}, "ru")
	var entered: Array[String] = []
	s.scene_entered.connect(func(n: String) -> void: entered.append(n))
	var mid := {}
	var rng := 42
	for i in 20000:
		var item := s.next()
		if item.type == "end":
			break
		if item.type == "choices":
			rng = (rng * 1103515245 + 12345) % 2147483648
			s.choose(rng % item.options.size())
			if s.events.size() >= 20 and mid.is_empty():
				mid = JSON.parse_string(JSON.stringify(s.to_save()))
		elif item.type == "battle":
			s.win_battle(2)
		elif item.type == "levelup":
			# Ветка: на 2 уровне вторая, дальше снова первая — проверка смены ветки в лагере.
			var arches := CombatData.archetypes_of(String(s.state.hero["class"]))
			s.choose_branch(String(arches[1 if int(item.level) == 2 else 0]))
		elif item.type == "shop":
			var stock := Shops.stock(String(item.id))
			s.leave_shop([[stock[0].id, "hero"]] if not stock.is_empty() else [])
	var scenes := entered.size()
	if scenes != s.scenes.size():
		fails.append("сцен пройдено %d из %d" % [scenes, s.scenes.size()])
	if s.state.ending == "":
		fails.append("нет концовки")
	# Сохранение посреди игры: загрузка даёт то же место.
	var b := StorySession.new()
	if not mid.is_empty():
		b.load_save(mid)
	if mid.is_empty() or b.events.size() != mid.events.size() or b.next().type == "end":
		fails.append("загрузка сохранения")
	var ms := Time.get_ticks_msec() - t0
	if fails.is_empty():
		print("SELFTEST OK: %s, сцен %d, боёв %d, концовка %s, Тьма %d, %d мс" % [StoryRunner.backend_name(), scenes,
			s.state.battles.size(), s.state.ending, s.darkness(), ms])
		return 0
	print("SELFTEST FAIL: " + "; ".join(fails))
	return 1
