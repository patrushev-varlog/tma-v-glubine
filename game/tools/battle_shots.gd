extends SceneTree
## Снимки экрана боя для PR: бои пролога в разных состояниях. Нужен дисплей (в контейнере — Xvfb).
##   godot --path game --rendering-method gl_compatibility -s res://tools/battle_shots.gd
## SHOT_DIR — папка снимков (по умолчанию user://shots), SHOT_SIZE — размер окна (1280x720), SHOT_LANG — язык (ru).

var dir := ""


func _initialize() -> void:
	var sz := OS.get_environment("SHOT_SIZE").split("x") if OS.get_environment("SHOT_SIZE") != "" else PackedStringArray(["1280", "720"])
	dir = OS.get_environment("SHOT_DIR") if OS.get_environment("SHOT_DIR") != "" else "user://shots"
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_size(Vector2i(int(sz[0]), int(sz[1])))
	root.size = Vector2i(int(sz[0]), int(sz[1]))
	SaveStore.dir = "user://shot_saves/"
	var game: Node = root.get_node("Game")
	await _frames(1)
	game.language = OS.get_environment("SHOT_LANG") if OS.get_environment("SHOT_LANG") != "" else "ru"
	TranslationServer.set_locale(game.language)

	# Облава: герой один, наведение на мертвеца показывает путь, шанс и урон.
	var s := await _battle(game, "prologue_1", "fighter", "story", {}, 5)
	var target := _first_enemy(s.battle)
	s.board.hover_cell = target.cell
	s._show_plan(target.cell)
	await _shot("b1_raid_hover")
	s.queue_free()

	# Дезертир: Гаррет связан, у надсмотрщиков аркан, у арбалетчика сбивающий болт.
	s = await _battle(game, "prologue_3", "wizard", "trial", {}, 4)
	s._select_mode("fire_bolt")
	var cells: Array[Vector2i] = s.battle.ability_targets(s.battle.current(), "fire_bolt")
	if not cells.is_empty():
		s.board.hover_cell = cells[0]
		s._show_plan(cells[0])
	await _shot("b2_deserter_ability")
	s.queue_free()

	# Храм: Ирена два раунда не поднимает руку — кнопки атаки погашены.
	s = await _battle(game, "prologue_2", "cleric", "story", {}, 2)
	var guard := 0
	while s.battle.current().kind != "irena" and guard < 20:
		s._end_turn()
		await _idle(s)
		guard += 1
	await _shot("b3_temple_irena")
	s.queue_free()

	# Колонна у костров: цель «продержаться», подкрепление и его выходы на поле, курсор геймпада.
	s = await _battle(game, "prologue_4_camp", "rogue", "story", {}, 8)
	s._move_cursor(Vector2i.ZERO)
	s._move_cursor(Vector2i(1, -1))
	s._move_cursor(Vector2i(1, -1))
	await _shot("b4_camp_objective")
	guard = 0
	while s.battle.round_num < 3 and s.battle.outcome == "" and guard < 40:
		s._end_turn()
		await _idle(s)
		guard += 1
	await _shot("b5_camp_reinforcements")
	s.queue_free()

	# Колонна у ворот рудника: телега посреди поля, из ворот в 3-м раунде выйдут мертвецы.
	s = await _battle(game, "prologue_4_gate", "fighter", "trial", {}, 3)
	await _shot("b6_gate")
	s.queue_free()

	# Анимация: волшебник бросает огненный снаряд — снимок в полёте и после попадания.
	s = await _battle(game, "prologue_3", "wizard", "story", {}, 4)
	s._select_mode("fire_bolt")
	var bolt_cells: Array[Vector2i] = s.battle.ability_targets(s.battle.current(), "fire_bolt")
	if not bolt_cells.is_empty():
		s._select_cell(bolt_cells[0], false)
		await create_timer(0.36).timeout
		await _shot("b7_fire_bolt_flight")
		await create_timer(0.25).timeout
		await _shot("b8_fire_bolt_hit")
	s.queue_free()
	quit()


func _battle(game: Node, bid: String, cls: String, diff: String, flags: Dictionary, seed_value: int) -> Node:
	var b := Battle.new()
	b.setup(CombatData.scenario(bid, cls, "", "full", diff, "kit", flags), seed_value, diff)
	game.battle = b
	var node: Node = load("res://scenes/battle_screen.tscn").instantiate()
	root.add_child(node)
	await _frames(6)
	await _idle(node)
	return node


## Дождаться хода отряда (враги ходят с паузами).
func _idle(screen: Node) -> void:
	await _frames(2)
	var guard := 0
	while screen.busy and guard < 2000:
		await process_frame
		guard += 1
	await _frames(4)


func _first_enemy(b: Battle) -> Combatant:
	var best: Combatant = null
	for e in b.enemies():
		if not e.dead and (best == null or Battle.dist(e.cell, b.current().cell) < Battle.dist(best.cell, b.current().cell)):
			best = e
	return best


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	var path := "%s/%s.png" % [dir, name]
	root.get_texture().get_image().save_png(path)
	print("снимок: ", path)
