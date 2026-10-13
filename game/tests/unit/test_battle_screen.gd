extends GutTest
## Экран боя (B9): бой из истории, прогноз по наведению, клик и двойной клик, курсор, победа,
## продолжение прерванного боя.

const SCREEN := "res://scenes/battle_screen.tscn"
const HERO := {"class": "fighter", "hero_f": false, "name": "Ардан", "spouse_f": true, "spouse_id": "eila",
	"spouse_name": "Эйла"}

var _screen: Node = null


func before_each() -> void:
	SaveStore.dir = "user://test_battle_saves/"
	Game.set_battle_double_click(false)
	Game.new_game({"hero": HERO, "difficulty": "story"})
	var guard := 0
	while Game.session.pending_battle == "" and guard < 2000:
		var item := Game.session.next()
		if item.type == "choices":
			Game.session.choose(0)
		guard += 1


func after_each() -> void:
	if _screen != null:
		_screen.free()
		_screen = null
	Game.abandon_battle()
	Game.battle = null


## Экран боя на первом ходу отряда (враги ходят без пауз).
func _open() -> Node:
	Game.start_battle(5)
	_screen = load(SCREEN).instantiate()
	_screen.enemy_step = 0.0
	add_child(_screen)
	await wait_frames(3)
	var guard := 0
	while _screen.busy and guard < 200:
		await wait_frames(1)
		guard += 1
	return _screen


func _nearest_foe(b: Battle) -> Combatant:
	var best: Combatant = null
	for e in b.enemies():
		if not e.dead and (best == null or Battle.dist(e.cell, b.current().cell) < Battle.dist(best.cell, b.current().cell)):
			best = e
	return best


func test_story_battle_is_prologue_1() -> void:
	assert_eq(Game.session.pending_battle, "prologue_1", "первый бой истории — облава")
	var s: Node = await _open()
	assert_eq(s.battle.id, "prologue_1", "экран открыл бой из истории")
	assert_eq(s.battle.heroes()[0].name, "Ардан", "герой с именем игрока")
	assert_eq(s.battle.current().team, 0, "ход отряда")
	assert_true(SaveStore.exists("battle"), "в начале хода бой сохранён")


func test_hover_preview_and_click() -> void:
	var s: Node = await _open()
	var b: Battle = s.battle
	var u := b.current()
	var foe := _nearest_foe(b)
	var plan: Dictionary = s._plan(foe.cell)
	assert_true(String(plan.text).contains("%"), "прогноз атаки с шансом: %s" % plan.text)
	assert_true(plan.has("act"), "атаку можно выполнить")
	var free := Vector2i(-1, -1)
	for c in b.reachable(u):
		if c is Vector2i and c != u.cell and b.occupant(c) == null:
			free = c
			break
	s._show_plan(free)
	assert_false(s.board.path.is_empty(), "наведение рисует путь")
	assert_eq(u.cell, b.current().cell, "наведение ничего не делает")
	s._select_cell(free, true)
	assert_eq(u.cell, free, "клик мышью сразу ходит")


func test_double_click_option() -> void:
	Game.set_battle_double_click(true)
	var s: Node = await _open()
	var b: Battle = s.battle
	var u := b.current()
	var start := u.cell
	var free := Vector2i(-1, -1)
	for c in b.reachable(u):
		if c is Vector2i and c != u.cell and b.occupant(c) == null:
			free = c
			break
	s._select_cell(free, true)
	assert_eq(u.cell, start, "первый клик — только прогноз")
	assert_eq(s.board.pending_cell, free, "клетка ждёт подтверждения")
	s._select_cell(free, true)
	assert_eq(u.cell, free, "второй клик по той же клетке — ход")


func test_cursor_and_abilities() -> void:
	var s: Node = await _open()
	var b: Battle = s.battle
	s._move_cursor(Vector2i.ZERO)
	assert_eq(s.board.cursor_cell, b.current().cell, "курсор появляется на герое")
	s._move_cursor(Vector2i(1, 1))
	assert_eq(s.board.cursor_cell, b.current().cell + Vector2i(1, 1), "крестовина двигает курсор")
	var shown: Array = s._shown_abilities(b.current())
	assert_false(shown.has("cursed_blade"), "тёмный дар скрыт, пока сюжет его не открыл")
	assert_true(s._abilities.get_child_count() >= shown.size() + 2, "на панели иконки умений и конец хода")
	s._select_mode("second_wind")
	assert_eq(s.mode, "second_wind", "умение на себя выбрано")
	s._select_mode("second_wind")
	assert_eq(s.mode, "", "второе нажатие применило его")
	assert_true(b.current().bonus_used, "потрачено бонусное действие")


func test_initiative_bar() -> void:
	var s: Node = await _open()
	var tokens := 0
	for ch in s._init_bar.get_children():
		if ch is PanelContainer:
			tokens += 1
	assert_eq(tokens, s.battle.units.filter(func(u: Combatant) -> bool: return not u.dead).size(), "фишка на каждого участника")


func test_victory_continues_story() -> void:
	var s: Node = await _open()
	var b: Battle = s.battle
	for e in b.enemies():
		b.deal_damage(e, 999, "test")
	assert_eq(b.outcome, "victory", "победа")
	s.finish()
	assert_eq(Game.session.pending_battle, "", "история больше не ждёт боя")
	assert_false(SaveStore.exists("battle"), "боевое сохранение удалено")
	assert_eq(Game.session.next().type, "line", "история идёт дальше")


func test_resume_after_quit() -> void:
	var s: Node = await _open()
	var b: Battle = s.battle
	var u := b.current()
	var cell := u.cell
	Game.save_battle()
	assert_true(Game.can_resume_battle(), "есть прерванный бой")
	_screen.free()
	_screen = null
	Game.battle = null
	assert_true(Game.resume_battle(), "бой загружается")
	assert_eq(Game.battle.id, "prologue_1", "тот же бой")
	assert_eq(Game.battle.current().cell, cell, "с начала того же хода")
	assert_eq(Game.session.pending_battle, "prologue_1", "история стоит на этом бою")
