extends GutTest
## Звук по данным: сцена → музыка и эмбиент (data/audio.json); без файлов — тишина без ошибок.


func test_scenes_choose_music_and_ambient() -> void:
	Sound.for_scene("temple")
	assert_eq(Sound.now_playing(), {"music": "dread", "ambient": "temple"}, "храм — тревога и эхо")
	Sound.for_battle()
	assert_eq(Sound.now_playing(), {"music": "battle", "ambient": ""}, "бой — боевой трек, окружение молчит")
	Sound.for_scene("no_such_scene")
	assert_eq(Sound.now_playing().music, "battle", "сцена без записи оставляет то, что играло")
	Sound.for_menu()
	assert_eq(Sound.now_playing().music, "home", "меню — «Дом»")


func test_every_prologue_scene_has_sound() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Sound.DATA))
	for sc in JSON.parse_string(FileAccess.get_file_as_string(StorySession.SCENES_PATH)).scenes:
		if sc.chapter == "prologue":
			assert_true(data.scenes.has(sc.scene), "звук сцены пролога %s" % sc.scene)


func test_missing_sfx_is_silent() -> void:
	Sound.sfx("no_such_sound")
	assert_eq(Sound.get_children().filter(func(c: Node) -> bool: return c is AudioStreamPlayer).size(), 2,
		"без файла звук не создаёт проигрыватель")
