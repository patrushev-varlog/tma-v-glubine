extends SceneTree
## Снимки экрана среза для документа: godot --path . --rendering-method gl_compatibility -s res://tools/screenshots.gd
## (нужен дисплей; в контейнере — Xvfb). Размер окна задаёт SHOT_SIZE=1280x800, папка — SHOT_DIR.

func _initialize() -> void:
	var sz := OS.get_environment("SHOT_SIZE").split("x") if OS.get_environment("SHOT_SIZE") != "" else PackedStringArray(["1280", "720"])
	var dir := OS.get_environment("SHOT_DIR") if OS.get_environment("SHOT_DIR") != "" else "user://shots"
	DisplayServer.window_set_size(Vector2i(int(sz[0]), int(sz[1])))
	root.size = Vector2i(int(sz[0]), int(sz[1]))
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	for i in 6:
		await process_frame
	var tag := "%sx%s" % [sz[0], sz[1]]
	var plan: Array = OS.get_environment("SHOT_PLAN").split(",") if OS.get_environment("SHOT_PLAN") != "" else ["start"]
	for step in plan:
		match step:
			"choices":
				while main._continue.visible:
					main._advance()
			"en":
				main.set_language("en")
			"board":
				main.board.grab_focus()
				main.board.cursor = Vector2i(2, 2)
				main.board.step_hero_to_cursor()
				for i in 20:
					await process_frame
			"dark0":
				main.portrait.set_stage(0)
				main._refresh_static()
				var r: Rect2 = main.portrait.get_global_rect()
				print("portrait_rect ", r.position.x, " ", r.position.y, " ", r.size.x, " ", r.size.y)
			"dark1":
				main.portrait.set_stage(1)
				main._refresh_static()
			"dark2":
				main.portrait.set_stage(2)
				main._refresh_static()
			"dark3":
				main.portrait.set_stage(3)
				main._refresh_static()
			"art1":
				main.board.next_art()
				main._refresh_static()
			"art2":
				main.board.next_art()
				main._refresh_static()
		for i in 4:
			await process_frame
		var img := root.get_texture().get_image()
		var path := "%s/%s_%s.png" % [dir, tag, step]
		img.save_png(path)
		print("снимок: ", path)
	quit()
