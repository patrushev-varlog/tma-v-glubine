class_name TestArena
extends RefCounted
## Помощники тестов боя: пустое поле и беспомощные враги.


## Пустое поле 12×12 с заданными участниками; ход у первого из них.
static func make(list: Array, seed_value := 7) -> Battle:
	var b := Battle.new()
	var units: Array[Combatant] = []
	for u in list:
		units.append(u)
	b.setup({"width": 12, "height": 12, "units": units, "obstacles": []}, seed_value, "trial")
	b.order.clear()
	for u in units:
		b.order.append(u.id)
	b.turn_index = 0
	b._start_turn()
	return b


## Участник на клетке.
static func at(c: Combatant, cell: Vector2i) -> Combatant:
	c.cell = cell
	return c


## Враг, который никогда не проходит спасброски и по которому не промахнуться (кроме 1 на кубике).
static func helpless(kind: String, idx: int, cell: Vector2i, hp := 0) -> Combatant:
	var e := CombatData.make_enemy(kind, idx)
	e.cell = cell
	e.ac = -50
	for k in ["str", "dex", "con", "wis"]:
		e.saves[k] = -30
	if hp > 0:
		e.max_hp = hp
		e.hp = hp
	return e


## Участник, которого не задеть: огромный КД и спасброски.
static func sturdy(c: Combatant) -> Combatant:
	c.ac = 99
	for k in ["str", "dex", "con", "wis"]:
		c.saves[k] = 99
	return c


## Есть ли в журнале боя строка с подстрокой.
static func logged(b: Battle, part: String) -> bool:
	for line in b.log_lines:
		if line.find(part) >= 0:
			return true
	return false
