extends SceneTree
## Смоук-тест интерфейса: запускает сцену и проводит бой тапами через те же функции, что и игрок.
## godot --headless --path prototypes/combat -s res://tests/ui_smoke.gd

var main: Node
var frames := 0
var started := false


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 3:
		main.enemy_step = 0.0
		main.hero_class = ["fighter", "rogue", "cleric", "wizard"][randi() % 4]
		main.with_velior = true
		main._start_new()
		started = true
	if not started or main.busy:
		return false
	var b: Battle = main.battle
	if b.outcome != "":
		print("Смоук интерфейса: бой завершён (%s) за %d раундов, класс %s." % [b.outcome, b.round_num, main.hero_class])
		quit(0)
		return true
	if frames > 50000:
		print("Смоук интерфейса: бой не завершился.")
		quit(1)
		return true
	var u := b.current()
	if u.team == 0:
		_play_hero_turn(b, u)
	return false


func _play_hero_turn(b: Battle, u: Combatant) -> void:
	for aid in u.abilities:
		var a: Dictionary = b.ability(aid)
		if a.target == "self" or not b.can_use(u, aid) or Content.BASIC_ACTIONS.has(aid):
			continue
		var targets := b.ability_targets(u, aid)
		if targets.is_empty() or a.target == "cell" or a.target == "empty_cell":
			continue
		main._select_mode(aid)
		main._tap(targets[0])
		main._tap(targets[0])
		break
	if b.outcome == "" and not u.action_used:
		var foe := CombatAI._pick_target(b, u)
		if foe != null:
			main._tap(foe.cell)
			main._tap(foe.cell)
	if b.outcome == "" and u.speed_left > 0 and u.conscious():
		var foe2 := CombatAI._pick_target(b, u)
		if foe2 != null:
			var reach := b.reachable(u)
			var best := u.cell
			for c in reach:
				if c is Vector2i and Battle.dist(c, foe2.cell) < Battle.dist(best, foe2.cell):
					best = c
			if best != u.cell:
				main._tap(best)
				main._tap(best)
	if b.outcome == "":
		main._end_turn()
