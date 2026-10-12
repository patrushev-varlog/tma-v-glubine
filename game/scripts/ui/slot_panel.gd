class_name SlotPanel
extends RefCounted
## Окно слотов сохранения: mode "load" — непустые слоты, "save" — быстрый и ручные слоты.
## on_pick(slot) вызывается при выборе; окно закрывается само.


static func open(root: Control, mode: String, on_pick: Callable) -> Control:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(holder)
	var col := UiKit.overlay(holder)
	col.add_child(UiKit.label(tr_key("LOAD_TITLE" if mode == "load" else "SAVE_TITLE"), UiKit.FONT_BODY, UiKit.ACCENT))
	for slot in SaveStore.slots():
		if mode == "save" and slot == "auto":
			continue
		var d := SaveStore.read(slot)
		if mode == "load" and d.is_empty():
			continue
		var text := "%s — %s" % [slot_name(slot), describe(d)]
		col.add_child(UiKit.button(text, func() -> void:
			holder.queue_free()
			on_pick.call(slot), UiKit.FONT_SMALL))
	col.add_child(UiKit.button(tr_key("MENU_BACK"), func() -> void: holder.queue_free()))
	UiKit.focus_first(col)
	return holder


static func tr_key(key: String) -> String:
	return TranslationServer.translate(key)


static func slot_name(slot: String) -> String:
	if slot.begins_with("slot_"):
		return UiKit.fmt("SLOT_manual", {"n": slot.substr(5)})
	return tr_key("SLOT_" + slot)


## Подпись слота: глава, уровень, дата — без загрузки истории.
static func describe(d: Dictionary) -> String:
	if d.is_empty():
		return tr_key("SLOT_EMPTY")
	var date := Time.get_datetime_string_from_unix_time(int(float(d.get("time", 0))), true).left(16)
	return UiKit.fmt("SLOT_INFO", {"chapter": tr_key("CHAPTER_%d" % int(d.get("chapter", 0))),
		"level": int(d.get("level", 1)), "date": date})
