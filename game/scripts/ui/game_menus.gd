class_name GameMenus
extends RefCounted
## Журнал и меню паузы: общие для экрана истории и экрана локации. Каждая функция кладёт рамку
## поверх root и возвращает её; закрывает рамку экран (queue_free), чтобы знать, что открыто.


static func _frame(root: Control) -> Array:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	return [overlay, UiKit.overlay(overlay)]


## Журнал: отряд, вещи, задания.
static func journal(root: Control, on_close: Callable) -> Control:
	var f := _frame(root)
	var col: VBoxContainer = f[1]
	var s := Game.session
	col.add_child(UiKit.heading(tr_("JOURNAL_TITLE"), UiKit.HEAD_BODY))
	var party := PackedStringArray([String(s.state.hero.get("name", ""))])
	for c in s.companions():
		party.append(tr_("COMPANION_" + c))
	col.add_child(UiKit.label(UiKit.fmt("JOURNAL_PARTY", {"party": ", ".join(party), "level": s.state.level,
		"silver": s.state.silver}), UiKit.FONT_SMALL))
	var items := PackedStringArray()
	for it in s.state.inventory:
		var key := "ITEM_" + String(it.id)
		items.append(tr_(key) if tr_(key) != key else String(it.id))
	col.add_child(UiKit.label(UiKit.fmt("JOURNAL_ITEMS", {"items": ", ".join(items)}) if not items.is_empty()
		else tr_("JOURNAL_NO_ITEMS"), UiKit.FONT_SMALL))
	col.add_child(UiKit.label(tr_("JOURNAL_QUESTS"), UiKit.FONT_SMALL, UiKit.MUTED))
	for q in QuestJournal.entries(s):
		var line := tr_(q.title_key)
		if q.state == "done":
			line += " — " + tr_("QUEST_DONE")
		elif q.has("clues"):
			line += " — " + UiKit.fmt("QUEST_CLUES", {"n": q.clues, "max": q.clues_max})
		col.add_child(UiKit.label("• " + line, UiKit.FONT_BODY, UiKit.ACCENT if q.state == "active" else UiKit.MUTED))
		for note in q.notes:
			col.add_child(UiKit.label("    " + note, UiKit.FONT_SMALL))
	col.add_child(UiKit.button(tr_("STORY_CLOSE"), on_close))
	UiKit.focus_first(col)
	return f[0]


## Меню паузы. actions: quicksave, save (открыть слоты), to_menu, close — Callable.
static func pause_menu(root: Control, actions: Dictionary) -> Control:
	var f := _frame(root)
	var col: VBoxContainer = f[1]
	col.add_child(UiKit.heading(tr_("STORY_MENU"), UiKit.HEAD_BODY))
	col.add_child(UiKit.button(tr_("STORY_QUICKSAVE"), actions.quicksave))
	col.add_child(UiKit.button(tr_("STORY_SAVE"), actions.save))
	col.add_child(UiKit.button(tr_("STORY_TO_MENU"), actions.to_menu))
	col.add_child(UiKit.button(tr_("STORY_CLOSE"), actions.close))
	UiKit.focus_first(col)
	return f[0]


static func tr_(key: String) -> String:
	return TranslationServer.translate(key)
