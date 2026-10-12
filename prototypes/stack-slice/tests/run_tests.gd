extends SceneTree
## Headless-тесты среза: godot --headless --path . -s res://tests/run_tests.gd
## 1) GodotInk проигрывает всю историю (пролог — эпилог) и сцену на двух языках так же, как inkjs;
## 2) журнал выборов переносится между языками; 3) геймпад управляет диалогом и полем.

var failures := 0
var checks := 0


func _initialize() -> void:
	var only := OS.get_environment("SLICE_TESTS")
	if only == "" or only.contains("ink"):
		_test_reference_transcripts()
		_test_language_switch()
	if only == "" or only.contains("ui"):
		await _test_gamepad_ui()
	print("\n%d проверок, провалено %d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)


func _test_reference_transcripts() -> void:
	var ref: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/reference.json"))
	var limit := int(OS.get_environment("SLICE_RUNS")) if OS.get_environment("SLICE_RUNS") != "" else 1000
	for story_id in ref["stories"]:
		var entry: Dictionary = ref["stories"][story_id]
		var json := FileAccess.get_file_as_string("res://story/%s.json" % story_id)
		var t0 := Time.get_ticks_msec()
		var ok := 0
		var runs: Array = entry["runs"].slice(0, limit)
		for r in runs:
			var t := InkTranscript.run(json, r, int(r["seed"]), entry["vars"], ref["spouse_name"])
			var same: bool = t["hash"] == r["hash"]
			check(same, "%s %s %s/%s seed %d: прогон не совпал с inkjs (строк %d против %d)" % [
				story_id, r["cls"], r["hero_f"], r["spouse_f"], r["seed"], t["lines"], r["lines"]])
			if same:
				ok += 1
			elif OS.get_environment("SLICE_DUMP") != "":
				var f := FileAccess.open("user://%s_%s_%d.txt" % [story_id, r["cls"], r["seed"]], FileAccess.WRITE)
				f.store_string(t["text"])
		var ms := Time.get_ticks_msec() - t0
		print("%s: %d/%d прогонов совпали с inkjs, %d мс (%.0f мс на прогон)" % [story_id, ok, runs.size(), ms, float(ms) / max(1, runs.size())])


func _test_language_switch() -> void:
	var setup := {"hero_class": "wizard", "hero_f": true, "spouse_f": false, "spouse_name": "Mara"}
	var r := StoryRunner.new()
	r.start_language("ru", setup)
	# Два выбора на русском, потом смена языка.
	for pick in [1, 0]:
		while r.can_continue():
			r.next_line()
		r.choose(pick)
	var tail := r.switch_language("en")
	check(r.language == "en", "язык переключился")
	check(r.choices().size() > 0 or tail.size() > 0, "после смены языка история продолжается")
	check(r.get_var("evening_together") == true, "флаг выбора сохранился при смене языка")
	var en_text := ""
	for line in tail:
		en_text += line["text"]
	for c in r.choices():
		en_text += c
	check(en_text.length() > 0 and not en_text.contains("Спросить"), "после смены языка текст английский: " + en_text.left(80))
	# Доиграть до конца на английском.
	var guard := 0
	while guard < 100:
		guard += 1
		while r.can_continue():
			r.next_line()
		if r.choices().is_empty():
			break
		r.choose(0)
	check(r.choices().is_empty() and not r.can_continue(), "английская сцена доигрывается до конца")
	check(r.get_var("asked") == 2, "в сцене задано два вопроса")


func _test_gamepad_ui() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	check(main.get("board") != null, "экран среза собрался без ошибок")
	if main.get("board") == null:
		return
	await GamepadSim.run_checks(self, main)
