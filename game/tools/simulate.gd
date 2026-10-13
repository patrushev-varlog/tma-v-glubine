extends SceneTree
## Таблица баланса тестовых боёв уровней 1–5: обе стороны ведёт ИИ.
## godot --headless --path game -s res://tools/simulate.gd -- [ключи]
## Ключи: level=1,2 class=wizard arch=evoker diff=trial party=full dark=both runs=200 drop=O,A gear=kit boost=hp:30,hit:1 hunt=1
## (gear — экипировка: none, kit — гарантированный набор уровня, full — набор и всё сверх бюджета;
## drop — буквы врагов на карте, которых убрать; party — full, no_velior, no_irena, duo;
## hunt=1 — бой после завершённой охоты главы, +10% хитов врагов;
## battle=prologue_1,prologue_3 — свои бои из battles.json вместо тестовых боёв уровней,
## flags=garret_ambush,garret_hunters_scared,ch1_choice=riot — сюжетные флаги для этих боёв).
## Без ключей — все уровни, классы и ветки на «Испытании» полным отрядом, с дарами и без, по 200 боёв.

func _init() -> void:
	var opt := {"level": "1,2,3,4,5", "class": ",".join(CombatData.class_ids()), "arch": "", "diff": "trial",
		"party": "full", "dark": "both", "runs": "200", "gear": "kit"}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=", true, 1)
		if kv.size() == 2:
			opt[kv[0]] = kv[1]
	if opt.has("drop"):
		CombatData.exclude = Array(String(opt.drop).split(","))
	CombatData.hunt_done = opt.get("hunt", "0") == "1"
	if opt.has("boost"):
		for part in String(opt.boost).split(","):
			var kv2 := part.split(":")
			CombatData.boost_override[kv2[0]] = int(kv2[1])
	var runs := int(opt.runs)
	var darks := [false, true] if opt.dark == "both" else [opt.dark == "1"]
	var flags := {}
	for f in String(opt.get("flags", "")).split(",", false):
		var fv := f.split("=", true, 1)
		flags[fv[0]] = fv[1] if fv.size() == 2 else true
	if opt.has("battle"):
		_story_battles(opt, flags, runs, darks)
		quit()
		return
	print("Уровень | Класс | Ветка | Отряд | Режим | Тёмные дары | Победы | Раундов | Выбыло | Герой выбыл")
	for lv_s in String(opt.level).split(","):
		var lv := int(lv_s)
		for cls in String(opt["class"]).split(","):
			var archs: Array = [""] if lv == 1 else CombatData.archetypes_of(cls)
			if opt.arch != "" and lv > 1:
				archs = Array(String(opt.arch).split(",")).filter(func(x): return CombatData.archetypes_of(cls).has(x))
			for arch in archs:
				for party in String(opt.party).split(","):
					for dark in darks:
						var s := Simulator.summarize("level_%d" % lv, cls, arch, party, opt.diff, runs, dark, opt.gear)
						print("%d | %s | %s | %s | %s | %s | %d%% | %.1f | %.1f | %d%%%s" % [lv,
							tr("CLASS_" + cls), "—" if arch == "" else tr("ARCH_" + arch), party,
							tr("DIFF_" + opt.diff), "да" if dark else "нет",
							roundi(s.win_rate * 100), s.avg_rounds, s.avg_down, roundi(s.hero_down_rate * 100),
							"" if s.timeouts == 0 else " (не кончились: %d)" % s.timeouts])
	quit()


## Сюжетные бои (battle=…): отряд задан в бою, уровень тоже; перебираются классы героя.
func _story_battles(opt: Dictionary, flags: Dictionary, runs: int, darks: Array) -> void:
	print("Бой | Класс | Режим | Тёмные дары | Победы | Раундов | Выбыло | Герой выбыл")
	for bid in String(opt.battle).split(","):
		for cls in String(opt["class"]).split(","):
			for dark in darks:
				var s := Simulator.summarize(bid, cls, "", "full", opt.diff, runs, dark, opt.gear, 1000, flags)
				print("%s | %s | %s | %s | %d%% | %.1f | %.1f | %d%%%s" % [bid, tr("CLASS_" + cls), tr("DIFF_" + opt.diff),
					"да" if dark else "нет", roundi(s.win_rate * 100), s.avg_rounds, s.avg_down,
					roundi(s.hero_down_rate * 100), "" if s.timeouts == 0 else " (не кончились: %d)" % s.timeouts])
