extends SceneTree
## Снимки лагеря главы 1: повышение уровня с выбором ветки и торговец (нужен дисплей, в контейнере — Xvfb).
##   godot --path game --rendering-method gl_compatibility -s res://tools/camp_shots.gd
## SHOT_DIR — папка снимков (по умолчанию user://shots).

func _initialize() -> void:
	var dir := OS.get_environment("SHOT_DIR") if OS.get_environment("SHOT_DIR") != "" else "user://shots"
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	SaveStore.dir = "user://shot_saves/"
	var game: Node = root.get_node("Game")
	game.new_game({"difficulty": "story", "hero": {"class": "fighter", "hero_f": false, "name": "Ардан", "spouse_f": true,
		"spouse_id": "eila", "spouse_name": "Эйла"}})
	var s: StorySession = game.session
	for i in 20000:
		var item := s.next()
		if item.type == "levelup":
			break
		if item.type == "choices":
			s.choose(0)
		elif item.type == "battle":
			s.win_battle(0)
	var story: Node = load("res://scenes/story_screen.tscn").instantiate()
	root.add_child(story)
	await _frames(8)
	await _shot(dir, "c1_levelup")
	for b in story.find_children("*", "Button", true, false):
		if (b as Button).text.contains(tr("ARCH_berserker")):
			(b as Button).emit_signal("pressed")
			break
	await _frames(4)
	for i in 10:
		if story._camp != null:
			break
		story._advance()
		await _frames(2)
	await _frames(6)
	await _shot(dir, "c2_shop")
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(dir: String, name: String) -> void:
	await _frames(3)
	var path := "%s/%s.png" % [dir, name]
	root.get_texture().get_image().save_png(path)
	print("снимок: ", path)
