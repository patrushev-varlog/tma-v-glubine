extends SceneTree
## Замер inkgd: загрузка JSON всей истории, полный прогон без перезагрузок, сохранение и загрузка состояния.

func _initialize() -> void:
	await process_frame
	var json := FileAccess.get_file_as_string("res://story/game.ru.json")
	var t0 := Time.get_ticks_msec()
	var r := StoryRunner.new()
	r.load_json_text(json)
	var t_load := Time.get_ticks_msec() - t0
	r.set_var("hero_class", "wizard")
	t0 = Time.get_ticks_msec()
	var lines := 0
	var picks := 0
	var worst := 0
	while true:
		var t_step := Time.get_ticks_msec()
		while r.can_continue():
			r.next_line()
			lines += 1
		var ch := r.choices()
		worst = max(worst, Time.get_ticks_msec() - t_step)
		if ch.is_empty():
			break
		r.choose(picks % ch.size())
		picks += 1
	var t_play := Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	var s := r.save_state()
	var t_save := Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	r.load_state(s)
	var t_restore := Time.get_ticks_msec() - t0
	print("%s: загрузка JSON %d мс; прогон %d строк, %d выборов за %d мс (худший шаг %d мс); сохранение %d мс (%d КБ), загрузка %d мс" % [
		StoryRunner.backend_name(), t_load, lines, picks, t_play, worst, t_save, s.length() / 1024, t_restore])
	quit()
