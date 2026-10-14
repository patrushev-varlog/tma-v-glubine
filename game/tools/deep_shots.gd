extends SceneTree
## Снимки дна главы 5: карты сцен (спуск, зал печати) там, где герой ходит и осматривает, бои и экран
## конца истории. Нужен дисплей (в контейнере — Xvfb).
##   godot --path game --rendering-method gl_compatibility -s res://tools/deep_shots.gd
## SHOT_DIR — папка снимков (по умолчанию user://shots).

var dir := ""


func _initialize() -> void:
	dir = OS.get_environment("SHOT_DIR") if OS.get_environment("SHOT_DIR") != "" else "user://shots"
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	SaveStore.dir = "user://shot_saves/"
	var game: Node = root.get_node("Game")
	await _frames(1)
	game.language = "ru"
	TranslationServer.set_locale("ru")
	game.new_game({"difficulty": "story", "hero": {"class": "cleric", "hero_f": true, "name": "Ода", "spouse_f": false,
		"spouse_id": "", "spouse_name": "Освин"}})
	var s: StorySession = game.session
	var shot := {"descent": "e1_descent", "seal_hall": "e2_seal_hall"}
	var near := {"descent": "guardroom", "seal_hall": "pedestal_13"}
	var exits := ["third_pillar", "seal_center"]
	for i in 30000:
		var item := s.next()
		if item.type == "end":
			break
		match String(item.type):
			"battle":
				s.win_battle(0)
			"levelup":
				s.choose_branch(String(s.state.hero.get("archetype", "")))
			"shop":
				s.leave_shop([])
			"choices":
				var scene := s.scene_name()
				if shot.has(scene) and s.chapter_name() == "chapter5" and exits.any(func(x: String) -> bool: return item.objects.has(x)):
					await _map_shot(game, String(shot[scene]), String(near[scene]))
					shot.erase(scene)
				var pick := 0
				for k in item.options.size():
					for p in ["Поднять бунт", "«Нет", "Ломать краны", "Взять перстень", "«Я не играю", "Уважить выбор"]:
						if String(item.options[k]).begins_with(p):
							pick = k
				s.choose(pick)
	var story: Node = load("res://scenes/story_screen.tscn").instantiate()
	game.pending_tail.assign([{"type": "line", "text": "КОНЕЦ. «Мир».", "tags": PackedStringArray()}])
	root.add_child(story)
	await _frames(10)
	story._advance()
	await _frames(10)
	await _shot("e6_end")
	story.queue_free()
	await _frames(2)
	for bid in ["chapter5_1_garrison", "chapter5_2_raised", "chapter5_final_master"]:
		var b := Battle.new()
		b.setup(CombatData.scenario(bid, "cleric", "", "full", "story", "kit", {}), 3, "story")
		if bid == "chapter5_final_master":
			# Вторая фаза: павшие стражи встают, из света выходят тени.
			for e in b.enemies():
				if not e.dead:
					b.deal_damage(e, e.hp, "shot")
		game.battle = b
		var node: Node = load("res://scenes/battle_screen.tscn").instantiate()
		root.add_child(node)
		await _frames(30)
		await _shot("e5_" + bid)
		node.queue_free()
		await _frames(2)
	quit()


## Карта сцены в режиме ходьбы: герой у объекта для осмотра, подсказка «Enter — …».
func _map_shot(game: Node, name: String, obj: String) -> void:
	game.pending_tail.assign([{"type": "line", "text": "…", "tags": PackedStringArray()}])
	var loc: Node = load("res://scenes/location_screen.tscn").instantiate()
	loc.change_screen = func(_p: String) -> void: pass
	root.add_child(loc)
	await _frames(6)
	loc._advance()
	var o: Dictionary = loc._map.object(obj)
	if not o.is_empty():
		var r: Dictionary = loc._map.path_to_object(loc._view.hero.cell, o)
		if r.ok and not r.path.is_empty():
			loc._view.hero.place(r.path[-1])
			loc._camera.reset_smoothing()
		loc._hover(o.cell)
		loc._update_prompt()
	await _frames(30)
	await _shot(name)
	loc.queue_free()
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	var path := "%s/%s.png" % [dir, name]
	root.get_texture().get_image().save_png(path)
	print("снимок: ", path)
