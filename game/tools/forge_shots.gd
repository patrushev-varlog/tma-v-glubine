extends SceneTree
## Снимки кузниц плоти главы 4: карты сцен (цеха, контора, анатомический зал, литейная) там, где
## герой ходит и осматривает, лавка лагеря и бои. Нужен дисплей (в контейнере — Xvfb).
##   godot --path game --rendering-method gl_compatibility -s res://tools/forge_shots.gd
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
	var shot := {"workshops": "f1_works", "reports": "f2_office", "flesh_master": "f3_anatomy", "foundry": "f4_foundry"}
	var near := {"workshops": "survivor", "reports": "armory", "flesh_master": "cupola", "foundry": "last_furnace"}
	var exits := ["office_stairs", "hall_door", "stairs_up", "last_furnace"]
	for i in 30000:
		var item := s.next()
		if item.type == "end" or s.chapter_name() == "chapter5":
			break
		match String(item.type):
			"battle":
				s.win_battle(0)
			"levelup":
				s.choose_branch(String(s.state.hero.get("archetype", "")))
			"shop":
				if String(item.id).ends_with("_ch4"):
					s.state.silver = maxi(s.state.silver, 120)
					var story: Node = load("res://scenes/story_screen.tscn").instantiate()
					root.add_child(story)
					await _frames(10)
					await _shot("f6_camp_shop")
					story.queue_free()
					await _frames(2)
				s.leave_shop([])
			"choices":
				var scene := s.scene_name()
				if shot.has(scene) and s.chapter_name() == "chapter4" and exits.any(func(x: String) -> bool: return item.objects.has(x)):
					await _map_shot(game, String(shot[scene]), String(near[scene]))
					shot.erase(scene)
				var pick := 0
				for k in item.options.size():
					for p in ["Поднять бунт", "«Нет", "Ломать краны", "Взять перстень", "«Я не играю"]:
						if String(item.options[k]).begins_with(p):
							pick = k
				s.choose(pick)
	for bid in ["chapter4_1", "chapter4_2", "chapter4_3"]:
		var b := Battle.new()
		b.setup(CombatData.scenario(bid, "cleric", "", "full", "story", "kit", {}), 3, "story")
		game.battle = b
		var node: Node = load("res://scenes/battle_screen.tscn").instantiate()
		root.add_child(node)
		await _frames(30)
		await _shot("f5_" + bid)
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
