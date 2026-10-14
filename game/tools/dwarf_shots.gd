extends SceneTree
## Снимки дварфийских залов главы 3: карты сцен (арки, кузница, архив, галерея печати) там, где
## герой ходит и осматривает, кузница Молчащих и бои залов. Нужен дисплей (в контейнере — Xvfb).
##   godot --path game --rendering-method gl_compatibility -s res://tools/dwarf_shots.gd
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
	var shot := {"arches": "d1_arches", "refuge": "d2_forge", "archive": "d3_archive", "keeper": "d4_gallery"}
	var near := {"arches": "riddle_door", "refuge": "brewery", "archive": "tablets", "keeper": "torvin"}
	var exits := ["hall_on", "fresco_door", "archive_out", "torvin"]
	for i in 30000:
		var item := s.next()
		if item.type == "end" or s.chapter_name() == "chapter4":
			break
		match String(item.type):
			"battle":
				s.win_battle(0)
			"levelup":
				s.choose_branch(String(s.state.hero.get("archetype", "")))
			"shop":
				if String(item.id) == "dwarf_forge" and shot.has("forge_shop"):
					await _shop_shot(s)
					shot.erase("forge_shop")
				s.leave_shop([])
			"choices":
				var scene := s.scene_name()
				if shot.has(scene) and s.chapter_name() == "chapter3" and exits.any(func(x: String) -> bool: return item.objects.has(x)):
					await _map_shot(game, String(shot[scene]), String(near[scene]))
					shot.erase(scene)
					if scene == "arches":
						shot["forge_shop"] = true
				var pick := 0
				for k in item.options.size():
					if String(item.options[k]).begins_with("Поднять бунт") or String(item.options[k]).begins_with("«Нет"):
						pick = k
				s.choose(pick)
	for bid in ["chapter3_1", "chapter3_2", "chapter3_3"]:
		var b := Battle.new()
		b.setup(CombatData.scenario(bid, "cleric", "", "full", "story", "kit", {}), 3, "story")
		game.battle = b
		var node: Node = load("res://scenes/battle_screen.tscn").instantiate()
		root.add_child(node)
		await _frames(30)
		await _shot("d5_" + bid)
		node.queue_free()
		await _frames(2)
	quit()


## Кузница Молчащих: лавка с переносом свойства, как её открывает экран истории (слиток и добротная вещь кладутся для снимка).
func _shop_shot(s: StorySession) -> void:
	if not s.state.inventory.any(func(it: Dictionary) -> bool: return String(it.id) == "dwarf_steel"):
		s.state.inventory.append({"id": "dwarf_steel", "owner": "hero"})
	if not s.state.inventory.any(func(it: Dictionary) -> bool: return Items.forgeable(String(it.id))):
		s.state.inventory.append({"id": "gate_sword", "owner": "irena"})
	var story: Node = load("res://scenes/story_screen.tscn").instantiate()
	root.add_child(story)
	await _frames(10)
	await _shot("d6_forge_shop")
	story.queue_free()
	await _frames(2)


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
