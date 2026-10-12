class_name GamepadSim
extends RefCounted
## Проверка экрана среза с «виртуального» геймпада: события InputEventJoypadButton идут
## тем же путём, что от настоящего (Input.parse_input_event), только без устройства.


static func press(tree: SceneTree, button: JoyButton) -> void:
	for pressed in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.device = 0
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
		await tree.process_frame


static func key(tree: SceneTree, code: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		ev.keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
		await tree.process_frame


static func run_checks(t, main) -> void:
	var tree: SceneTree = t
	var input_setup: Node = tree.root.get_node("InputSetup")
	var text_before: String = main._text.text
	t.check(text_before.begins_with("Осень"), "сцена начинается с первой строки: " + text_before.left(40))
	t.check(main._continue.has_focus(), "фокус на кнопке «дальше»")

	# A листает строки до первого выбора.
	var guard := 0
	while main._continue.visible and guard < 10:
		await press(tree, JOY_BUTTON_A)
		guard += 1
	t.check(input_setup.device == "xbox", "после кнопки геймпада подсказки под геймпад: " + input_setup.device)
	t.check(main._choices.get_child_count() == 2, "первый выбор: два варианта")
	var first: Button = main._choices.get_child(0)
	t.check(first.has_focus(), "фокус на первом варианте")

	# Крестовина вниз — второй вариант, A — выбрать.
	await press(tree, JOY_BUTTON_DPAD_DOWN)
	var second: Button = main._choices.get_child(1)
	t.check(second.has_focus(), "крестовина вниз переводит фокус на второй вариант")
	await press(tree, JOY_BUTTON_A)
	t.check(main.story.get_var("evening_together") == true, "A выбрал «сесть рядом»")

	# Y — английский посреди сцены, флаг выбора на месте.
	await press(tree, JOY_BUTTON_Y)
	t.check(main.lang == "en", "Y переключил язык на английский")
	t.check(main.story.get_var("evening_together") == true, "после смены языка выбор сохранился")
	var en_text: String = main._text.text
	t.check(en_text.length() > 0 and en_text.unicode_at(0) < 0x400, "после смены языка текст английский: " + en_text.left(50))
	t.check(main._continue.text.contains("continue"), "интерфейс тоже на английском: " + main._continue.text)

	# View — фокус на поле; крестовина двигает курсор, A — шаг Гаррета.
	await press(tree, JOY_BUTTON_BACK)
	t.check(main.board.has_focus(), "View перевёл фокус на поле")
	var start_hero: Vector2i = main.board.hero
	await press(tree, JOY_BUTTON_DPAD_RIGHT)
	t.check(main.board.cursor == Vector2i(2, 1), "крестовина вправо сдвинула курсор: %s" % main.board.cursor)
	await press(tree, JOY_BUTTON_A)
	t.check(main.board.hero == Vector2i(2, 1) and main.board.hero != start_hero, "A — Гаррет шагнул на курсор")
	t.check(main.board.facing == "south-east", "Гаррет смотрит по ходу: " + main.board.facing)
	await press(tree, JOY_BUTTON_DPAD_UP)
	await press(tree, JOY_BUTTON_A)
	t.check(main.board.hero == Vector2i(2, 1), "на крепь шагнуть нельзя")

	# RB/LB — стадия Тьмы, X — набор графики.
	await press(tree, JOY_BUTTON_RIGHT_SHOULDER)
	await press(tree, JOY_BUTTON_RIGHT_SHOULDER)
	t.check(main.portrait.stage == 2, "RB дважды — стадия «Мрак»")
	await press(tree, JOY_BUTTON_LEFT_SHOULDER)
	t.check(main.portrait.stage == 1, "LB — стадия «Сумрак»")
	await press(tree, JOY_BUTTON_X)
	t.check(main.board.art_index == 1, "X — следующий набор графики")

	# Назад в диалог и доиграть сцену одной кнопкой A.
	await press(tree, JOY_BUTTON_BACK)
	t.check(not main.board.has_focus(), "View вернул фокус в диалог")
	guard = 0
	while main.story.choices().size() > 0 or main.story.can_continue() or main._continue.visible:
		await press(tree, JOY_BUTTON_A)
		guard += 1
		if guard > 60:
			break
	t.check(guard <= 60, "сцена доигрывается геймпадом")
	t.check(main.story.get_var("asked") == 2, "по пути задано два вопроса")

	# Клавиатура возвращает подсказки клавиатуры.
	await key(tree, KEY_L)
	t.check(input_setup.device == "keyboard", "после клавиши подсказки под клавиатуру")
	t.check(main.lang == "ru", "L вернул русский")
	t.check(input_setup.joy_kind("Sony Interactive Entertainment DualSense Wireless Controller") == "playstation", "DualSense распознан")
	t.check(input_setup.joy_kind("Steam Deck") == "deck", "Steam Deck распознан")
