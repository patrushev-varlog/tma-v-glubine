class_name Dice
extends RefCounted
## Броски костей в нотации «2d6+3».

static var _re: RegEx


static func parse(expr: String) -> Dictionary:
	if _re == null:
		_re = RegEx.new()
		_re.compile("^(\\d*)d(\\d+)([+-]\\d+)?$")
	var s := expr.replace(" ", "")
	var m := _re.search(s)
	if m == null:
		return {"count": 0, "sides": 0, "bonus": s.to_int()}
	var c := m.get_string(1)
	return {
		"count": 1 if c == "" else c.to_int(),
		"sides": m.get_string(2).to_int(),
		"bonus": m.get_string(3).to_int(),
	}


## Критический удар удваивает количество костей, но не бонус.
static func roll(rng: RandomNumberGenerator, expr: String, crit := false) -> int:
	var d := parse(expr)
	var count: int = d.count * (2 if crit else 1)
	var total: int = d.bonus
	for i in count:
		total += rng.randi_range(1, d.sides)
	return max(total, 0)


static func min_of(expr: String) -> int:
	var d := parse(expr)
	return max(d.count + d.bonus, 0)


static func max_of(expr: String) -> int:
	var d := parse(expr)
	return max(d.count * d.sides + d.bonus, 0)


static func avg_of(expr: String) -> float:
	var d := parse(expr)
	return d.count * (d.sides + 1) / 2.0 + d.bonus


static func d20(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 20)


## Вероятность, что d20 + bonus >= target, с правилом 1 и 20 для атак.
static func hit_chance(bonus: int, target: int, advantage := 0, natural_rules := true) -> float:
	var need := target - bonus
	if natural_rules:
		need = clampi(need, 2, 20)
	else:
		need = clampi(need, 1, 21)
	var p := (21 - need) / 20.0
	if advantage > 0:
		return 1.0 - (1.0 - p) * (1.0 - p)
	if advantage < 0:
		return p * p
	return p
