extends SceneTree
## Снимки экранов для PR и документации: нужен дисплей (в контейнере — Xvfb).
##   godot --path game --rendering-method gl_compatibility -s res://tools/screenshots.gd
## SHOT_DIR — папка снимков (по умолчанию user://shots), SHOT_SIZE — размер окна (1280x720).

var dir := ""


func _initialize() -> void:
	var sz := OS.get_environment("SHOT_SIZE").split("x") if OS.get_environment("SHOT_SIZE") != "" else PackedStringArray(["1280", "720"])
	dir = OS.get_environment("SHOT_DIR") if OS.get_environment("SHOT_DIR") != "" else "user://shots"
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_size(Vector2i(int(sz[0]), int(sz[1])))
	root.size = Vector2i(int(sz[0]), int(sz[1]))
	SaveStore.dir = "user://shot_saves/"
	var game: Node = root.get_node("Game")

	var menu := await _show("res://scenes/main_menu.tscn")
	await _shot("1_menu")
	menu.queue_free()

	var create := await _show("res://scenes/hero_creation.tscn")
	create._name.text = "Ода"
	(create.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == tr("CLASS_cleric"))[0] as Button).emit_signal("pressed")
	(create.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == tr("SEX_f"))[0] as Button).emit_signal("pressed")
	create._refresh()
	await _shot("2_create")
	var setup: Dictionary = create.setup()
	create.queue_free()

	game.new_game(setup)
	var story := await _show("res://scenes/story_screen.tscn")
	for i in 40:
		var b: Array = story._bottom.get_children().filter(func(c: Node) -> bool: return c is Button)
		if b.size() > 1:
			break
		story._advance()
	await _frames(4)
	await _shot("3_story_choices")
	story._choose(0)
	while game.session.pending_battle == "":
		var item: Dictionary = game.session.next()
		if item.type == "choices":
			game.session.choose(0)
		elif item.type == "line":
			story._add_line(item)
	story._clear_bottom()
	story._battle_panel(game.session.pending_battle)
	await _frames(4)
	await _shot("4_battle_stub")
	story._open_journal()
	await _frames(4)
	await _shot("5_journal")
	story.queue_free()
	await _location(game, setup)
	quit()


## Экран локации: облава ночью, бой и возврат, пепелище утром (разговор, улики).
func _location(game: Node, setup: Dictionary) -> void:
	setup.hero["class"] = "wizard"
	setup.hero["hero_f"] = false
	setup.hero["name"] = "Ардан"
	setup.hero["spouse_f"] = true
	setup.hero["spouse_id"] = "eila"
	setup.hero["spouse_name"] = "Эйла"
	game.new_game(setup)
	var first := {}
	while first.is_empty():
		var item: Dictionary = game.session.next()
		if item.type == "line" and String(item.get("scene", "")) == "raid":
			first = item
		elif item.type == "choices":
			game.session.choose(0)
	game.pending_tail.assign([first])
	var loc := await _show("res://scenes/location_screen.tscn")
	loc.change_screen = func(_p: String) -> void: pass
	loc._advance()
	loc._advance()
	await _frames(20)
	await _shot("6_raid_night")
	while loc._mode != "battle":
		if loc._mode == "choices":
			loc._choose(0)
		else:
			loc._advance()
	await _frames(4)
	loc._start_battle(game.session.pending_battle)
	await _wait(0.6)
	await _shot("7_battle_stub")
	loc._end_battle(0)
	await _wait(1.0)
	for i in 4:
		loc._advance()
	await _frames(20)
	await _shot("8_raid_after_battle")
	while loc._mode != "leaving":
		if loc._mode == "choices":
			loc._choose(0)
		else:
			loc._advance()
	var tail: Array = game.pending_tail.duplicate()
	loc.queue_free()
	await _frames(2)

	game.pending_tail.assign(tail)
	loc = await _show("res://scenes/location_screen.tscn")
	loc.change_screen = func(_p: String) -> void: pass
	while loc._mode != "roam":
		loc._advance()
	var oldrik: Dictionary = loc._map.object("oldrik")
	loc._hover(oldrik.cell)
	await _frames(30)
	await _shot("9_ashes_roam")
	loc._interact("oldrik")
	loc._advance()
	await _frames(10)
	await _shot("10_ashes_oldrik")
	while loc._mode != "roam":
		if loc._mode == "choices":
			loc._choose(0)
		else:
			loc._advance()
	var r: Dictionary = loc._map.path_to_object(loc._view.hero.cell, loc._map.object("cart"))
	loc._view.hero.walk(r.path)
	await _wait(0.25 * r.path.size() + 0.8)
	loc._hover(loc._map.object("list").cell)
	await _frames(10)
	await _shot("11_ashes_clues")


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _show(path: String) -> Node:
	var node: Node = load(path).instantiate()
	root.add_child(node)
	await _frames(6)
	return node


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	var path := "%s/%s.png" % [dir, name]
	root.get_texture().get_image().save_png(path)
	print("снимок: ", path)
