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


## Несколько групп костей через «+» («1d4+1d6»): кости по нежити от разных предметов складываются.
static func _terms(expr: String) -> PackedStringArray:
	return expr.replace(" ", "").split("+")


static func _multi(expr: String) -> bool:
	return expr.count("d") > 1


## Критический удар удваивает количество костей, но не бонус.
static func roll(rng: RandomNumberGenerator, expr: String, crit := false) -> int:
	if _multi(expr):
		var sum := 0
		for t in _terms(expr):
			sum += roll(rng, t, crit)
		return sum
	var d := parse(expr)
	var count: int = d.count * (2 if crit else 1)
	var total: int = d.bonus
	for i in count:
		total += rng.randi_range(1, d.sides)
	return max(total, 0)


static func min_of(expr: String) -> int:
	if _multi(expr):
		var sum := 0
		for t in _terms(expr):
			sum += min_of(t)
		return sum
	var d := parse(expr)
	return max(d.count + d.bonus, 0)


static func max_of(expr: String) -> int:
	if _multi(expr):
		var sum := 0
		for t in _terms(expr):
			sum += max_of(t)
		return sum
	var d := parse(expr)
	return max(d.count * d.sides + d.bonus, 0)


static func avg_of(expr: String) -> float:
	if _multi(expr):
		var sum := 0.0
		for t in _terms(expr):
			sum += avg_of(t)
		return sum
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


## Запись костей: (2, 6, 3) → «2d6+3».
static func expr(count: int, sides: int, bonus: int) -> String:
	var out := "%dd%d" % [count, sides]
	if bonus > 0:
		out += "+%d" % bonus
	elif bonus < 0:
		out += "%d" % bonus
	return out


## Сложить кости: одинаковые грани объединяются («1d4» + «1d4» = «2d4»), разные идут через «+».
static func add(have: String, more: String) -> String:
	if have == "":
		return more
	if more == "":
		return have
	var a := parse(have)
	var b := parse(more)
	if not _multi(have) and not _multi(more) and a.sides == b.sides and a.bonus == 0 and b.bonus == 0:
		return "%dd%d" % [a.count + b.count, a.sides]
	return have + "+" + more


## Прибавить число к костям: («1d10», 3) → «1d10+3».
static func plus(have: String, bonus: int) -> String:
	if bonus == 0 or have == "":
		return have
	if _multi(have):
		return have + ("+%d" % bonus if bonus > 0 else "%d" % bonus)
	var d := parse(have)
	return expr(d.count, d.sides, d.bonus + bonus)
