class_name InkTranscript
extends RefCounted
## Прогон истории с детерминированными выборами — тот же, что transcript() в tools/ink_tool.mjs.
## Хэш прогона сравнивается с эталоном inkjs из tests/reference.json.

const SAVE_EVERY := 3


static func run(json: String, setup: Dictionary, seed: int, names: Array, spouse_name: String) -> Dictionary:
	var runner := StoryRunner.new()
	runner.load_json_text(json)
	runner.set_var("hero_class", setup["cls"])
	runner.set_var("hero_f", setup["hero_f"])
	runner.set_var("spouse_f", setup["spouse_f"])
	runner.set_var("spouse_name", spouse_name)
	var rng := seed
	var out := PackedStringArray()
	var picks := 0
	while true:
		while runner.can_continue():
			var line := runner.next_line()
			out.append("L|%s|%s" % [String(line["text"]).replace("\n", "\\n"), ",".join(line["tags"])])
		var choices := runner.choices()
		if choices.is_empty():
			break
		rng = (rng * 1103515245 + 12345) % 2147483648
		var idx := rng % choices.size()
		out.append("C|%s|>%d" % ["|".join(choices), idx])
		runner.choose(idx)
		picks += 1
		if picks % SAVE_EVERY == 0:
			var saved := runner.save_state()
			runner = StoryRunner.new()
			runner.load_json_text(json)
			runner.load_state(saved)
	var values := PackedStringArray()
	for n in names:
		values.append("%s=%s" % [n, _fmt(runner.get_var(n))])
	out.append("V|" + ";".join(values))
	var text := "\n".join(out)
	return {"text": text, "hash": text.sha256_text(), "lines": out.size(), "picks": picks}


static func _fmt(v: Variant) -> String:
	if v is bool:
		return "true" if v else "false"
	return str(v)
