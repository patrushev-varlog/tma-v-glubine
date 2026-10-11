extends SceneTree
## Таблица баланса боёв уровней 1–5: обе стороны ведёт ИИ.
## godot --headless --path prototypes/combat -s res://tools/simulate.gd -- [ключи]
## Ключи: level=1,2 class=wizard arch=evoker diff=trial velior=0 dark=both runs=200 drop=O,A gear=kit boost=hp:30,hit:1
## (gear — экипировка: none — без неё, kit — гарантированный набор уровня, full — набор и всё сверх бюджета;
## drop — буквы врагов на карте, которых убрать: для подбора состава боя).
## Без ключей — все уровни, классы и ветки на «Испытании» без Велиора, с дарами и без, по 200 боёв.

func _init() -> void:
	var opt := {"level": "1,2,3,4,5", "class": ",".join(Content.HERO_CLASSES.keys()), "arch": "", "diff": "trial",
		"velior": "0", "dark": "both", "runs": "200", "gear": "kit"}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=", true, 1)
		if kv.size() == 2:
			opt[kv[0]] = kv[1]
	if opt.has("drop"):
		Content.exclude = Array(String(opt.drop).split(","))
	Items.mode = String(opt.gear)
	if opt.has("boost"):
		# boost=hp:30,hit:1 — усиление врагов вместо записанного в бою.
		for part in String(opt.boost).split(","):
			var kv2 := part.split(":")
			Content.boost_override[kv2[0]] = int(kv2[1])
	var runs := int(opt.runs)
	var darks := [false, true] if opt.dark == "both" else [opt.dark == "1"]
	print("Уровень | Класс | Ветка | Велиор | Режим | Тёмные дары | Победы | Раундов | Выбыло | Герой выбыл")
	for lv_s in String(opt.level).split(","):
		var lv := int(lv_s)
		for cls in String(opt["class"]).split(","):
			var archs: Array = [""] if lv == 1 else Content.archetypes_of(cls)
			if opt.arch != "" and lv > 1:
				archs = Array(String(opt.arch).split(",")).filter(func(x): return Content.archetypes_of(cls).has(x))
			for arch in archs:
				for vel in String(opt.velior).split(","):
					for dark in darks:
						var s := Simulator.summarize(lv, cls, arch, vel == "1", opt.diff, runs, dark)
						var arch_name: String = "—" if arch == "" else Content.HERO_CLASSES[cls].archetypes[arch].name
						print("%d | %s | %s | %s | %s | %s | %d%% | %.1f | %.1f | %d%%%s" % [lv,
							Content.HERO_CLASSES[cls].name, arch_name, "да" if vel == "1" else "нет",
							"История" if opt.diff == "story" else "Испытание", "да" if dark else "нет",
							roundi(s.win_rate * 100), s.avg_rounds, s.avg_down, roundi(s.hero_down_rate * 100),
							"" if s.timeouts == 0 else " (не кончились: %d)" % s.timeouts])
	quit()
