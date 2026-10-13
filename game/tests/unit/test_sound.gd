extends GutTest
## Звук по данным: сцена → музыка и эмбиент (data/audio.json); без файлов — тишина без ошибок.


func test_scenes_choose_music_and_ambient() -> void:
	Sound.for_scene("temple")
	assert_eq(Sound.now_playing(), {"music": "dread", "ambient": "temple"}, "храм — тревога и эхо")
	Sound.for_battle()
	assert_eq(Sound.now_playing(), {"music": "battle", "ambient": ""}, "бой без поля — боевой трек, окружение молчит")
	Sound.for_battle("ford")
	assert_eq(Sound.now_playing(), {"music": "battle", "ambient": "stream"}, "бой у брода — ручей под музыкой")
	Sound.for_scene("no_such_scene")
	assert_eq(Sound.now_playing().music, "battle", "сцена без записи оставляет то, что играло")
	Sound.for_menu()
	assert_eq(Sound.now_playing().music, "home", "меню — «Дом»")


func test_every_prologue_scene_has_sound() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Sound.DATA))
	for sc in JSON.parse_string(FileAccess.get_file_as_string(StorySession.SCENES_PATH)).scenes:
		if sc.chapter == "prologue":
			assert_true(data.scenes.has(sc.scene), "звук сцены пролога %s" % sc.scene)


func _players() -> int:
	return Sound.get_children().filter(func(c: Node) -> bool: return c is AudioStreamPlayer).size()


func test_missing_sfx_is_silent() -> void:
	var before := _players()
	Sound.sfx("no_such_sound")
	assert_eq(_players(), before, "без файла звук не создаёт проигрыватель")
	assert_eq(Sound.last_sfx, "no_such_sound", "вызов всё равно отмечен")


func test_sfx_with_variants_plays() -> void:
	var before := _players()
	Sound.sfx("hit_blade")
	assert_eq(_players(), before + 1, "у звука с вариантами (hit_blade_1…) есть файл")


## Всё, что игра может позвать, лежит в audio/: треки и шумы сцен, звуки из таблиц sfx и теги # sfx: в Ink.
func test_every_referenced_file_exists() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Sound.DATA))
	var want := {}
	for entry in [data.menu, data.battle, data.demo_end] + data.scenes.values() + data.battle_grounds.values():
		if entry is Dictionary:
			for kind in ["music", "ambient"]:
				if String(entry.get(kind, "")) != "":
					want["%s/%s" % [kind, entry[kind]]] = true
	for table in ["weapons", "abilities", "steps"]:
		for v in data.sfx[table].values():
			for id in (v if v is Array else [v]):
				if String(id) != "":
					want["sfx/" + String(id)] = true
	for id in ["ui_click", "ui_hover", "page_turn", "book", "journal", "save", "coin", "pickup", "miss", "hit_bone",
			"body_fall", "bones_collapse", "undead_groan", "undead_death", "spawn", "victory", "defeat", "heal",
			"bell_far", "bell_chapel", "handbell"]:
		want["sfx/" + id] = true
	for key in want:
		var ok := ResourceLoader.exists("res://audio/%s.ogg" % key) or ResourceLoader.exists("res://audio/%s_1.ogg" % key)
		assert_true(ok, "есть файл для %s" % key)


func test_every_ability_has_sound() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Sound.DATA))
	for aid in CombatData.table("abilities"):
		if aid != "_doc":
			assert_true(data.sfx.abilities.has(aid), "звук умения %s" % aid)
