extends SceneTree
## Грубая оценка баланса боя 3 пролога: обе стороны ведёт ИИ.
## godot --headless --path prototypes/combat -s res://tools/simulate.gd

const RUNS := 300


func _init() -> void:
	print("Класс героя | Велиор | Режим | Тёмные дары | Победы | Раундов | Выбыло героев")
	for cls in Content.HERO_CLASSES:
		for velior in [false, true]:
			for diff in ["story", "trial"]:
				for dark in [false, true]:
					var s := Simulator.summarize(cls, velior, diff, RUNS, dark)
					print("%s | %s | %s | %s | %d%% | %.1f | %.1f" % [
						Content.HERO_CLASSES[cls].name, "да" if velior else "нет",
						"История" if diff == "story" else "Испытание", "да" if dark else "нет",
						roundi(s.win_rate * 100), s.avg_rounds, s.avg_down])
	quit()
