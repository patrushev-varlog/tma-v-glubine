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
	quit()


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
