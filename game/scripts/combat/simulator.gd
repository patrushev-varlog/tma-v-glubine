class_name Simulator
extends RefCounted
## Прогон боя, где обе стороны ведёт ИИ. Нужен для смоук-теста, самопроверки сборки и грубой оценки баланса.

const MAX_ROUNDS := 40


static func run_battle(battle_id: String, hero_class: String, archetype: String, party: String, diff: String,
		seed_value: int, use_dark := false, gear := "kit") -> Dictionary:
	var b := Battle.new()
	b.setup(CombatData.scenario(battle_id, hero_class, archetype, party, diff, gear), seed_value, diff)
	var guard := 0
	while b.outcome == "" and b.round_num <= MAX_ROUNDS:
		CombatAI.take_turn(b, b.current(), use_dark)
		b.end_turn()
		guard += 1
		if guard > 3000:
			break
	var down := 0
	var hero_down := false
	for h in b.heroes():
		if not h.conscious():
			down += 1
			if h.is_hero:
				hero_down = true
	return {"outcome": b.outcome if b.outcome != "" else "timeout", "rounds": b.round_num,
		"heroes_down": down, "hero_down": hero_down, "darkness": b.darkness}


static func summarize(battle_id: String, hero_class: String, archetype: String, party: String, diff: String, runs: int,
		use_dark := false, gear := "kit", seed_base := 1000) -> Dictionary:
	var wins := 0
	var rounds := 0
	var timeouts := 0
	var downs := 0
	var hero_downs := 0
	for i in runs:
		var r := run_battle(battle_id, hero_class, archetype, party, diff, seed_base + i, use_dark, gear)
		if r.outcome == "victory":
			wins += 1
		elif r.outcome == "timeout":
			timeouts += 1
		rounds += int(r.rounds)
		downs += int(r.heroes_down)
		if r.hero_down:
			hero_downs += 1
	return {"win_rate": float(wins) / runs, "avg_rounds": float(rounds) / runs,
		"avg_down": float(downs) / runs, "timeouts": timeouts, "hero_down_rate": float(hero_downs) / runs}
