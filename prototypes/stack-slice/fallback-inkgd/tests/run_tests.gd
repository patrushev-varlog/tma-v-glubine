extends SceneTree
## godot --headless --path fallback-inkgd -s res://tests/run_tests.gd
## Тот же эталон, что у основного проекта: прогоны inkgd должны совпасть с inkjs.
## SLICE_RUNS=N — сколько прогонов брать на историю (по умолчанию 4: inkgd медленный).

func _initialize() -> void:
	# Ждём кадр, чтобы узел рантайма inkgd встал в дерево.
	await process_frame
	var ref: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/reference.json"))
	var limit := int(OS.get_environment("SLICE_RUNS")) if OS.get_environment("SLICE_RUNS") != "" else 4
	var failures := 0
	for story_id in ref["stories"]:
		var entry: Dictionary = ref["stories"][story_id]
		var json := FileAccess.get_file_as_string("res://story/%s.json" % story_id)
		var t0 := Time.get_ticks_msec()
		var ok := 0
		var runs: Array = entry["runs"].slice(0, limit)
		for r in runs:
			var t := InkTranscript.run(json, r, int(r["seed"]), entry["vars"], ref["spouse_name"])
			if t["hash"] == r["hash"]:
				ok += 1
			else:
				failures += 1
				printerr("FAIL: %s %s seed %d: строк %d против %d" % [story_id, r["cls"], r["seed"], t["lines"], r["lines"]])
				var f := FileAccess.open("user://fail_%s_%s_%d.txt" % [story_id, r["cls"], r["seed"]], FileAccess.WRITE)
				f.store_string(t["text"])
		var ms := Time.get_ticks_msec() - t0
		print("%s: %d/%d прогонов совпали с inkjs, %d мс (%.0f мс на прогон)" % [story_id, ok, runs.size(), ms, float(ms) / max(1, runs.size())])
	quit(1 if failures > 0 else 0)
