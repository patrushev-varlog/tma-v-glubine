class_name CampPanels
extends RefCounted
## Лагерь между главами: повышение уровня с выбором ветки и торговец. Общие для экрана истории и
## экрана локации, как GameMenus: функция кладёт рамку поверх root и возвращает её, а по выбору
## зовёт on_done — экран закрывает рамку и продолжает историю.
##
## Ветки (решение Валерия 13.10.2026, DESIGN.md, «Умения в бою»): на 2 уровне герой выбирает одну
## из двух веток класса, умения приходят по таблице; в каждом следующем лагере ветку можно сменить —
## умения новой ветки приходят сразу все по текущему уровню.


static func _frame(root: Control) -> Array:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	return [overlay, UiKit.overlay(overlay)]


## Повышение уровня. on_done(branch: String) — выбранная ветка (та же, если герой её оставил).
static func levelup(root: Control, level: int, on_done: Callable) -> Control:
	Sound.sfx("journal")
	var f := _frame(root)
	var col: VBoxContainer = f[1]
	var st := Game.session.state
	var cls := String(st.hero.get("class", "fighter"))
	var current := st.branch
	col.add_child(UiKit.heading(UiKit.fmt("LEVELUP_TITLE", {"level": level}), UiKit.HEAD_BODY))
	col.add_child(UiKit.label(tr_("LEVELUP_GROWTH"), UiKit.FONT_SMALL, UiKit.MUTED))
	col.add_child(UiKit.label(tr_("LEVELUP_PICK") if current == "" else
		UiKit.fmt("LEVELUP_KEEP_OR_SWITCH", {"branch": tr_("ARCH_" + current)}), UiKit.FONT_SMALL))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	for arch in CombatData.archetypes_of(cls):
		row.add_child(_branch_card(cls, String(arch), level, current, on_done))
	UiKit.focus_first(row)
	return f[0]


static func _branch_card(cls: String, arch: String, level: int, current: String, on_done: Callable) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	box.add_child(UiKit.heading(tr_("ARCH_" + arch).to_upper(), UiKit.HEAD_SMALL, UiKit.HERO if arch == current else UiKit.ACCENT))
	var desc := UiKit.label(tr_("ARCH_%s_DESC" % arch), UiKit.FONT_SMALL, UiKit.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(360, 0)
	box.add_child(desc)
	var levels: Dictionary = CombatData.table("classes")[cls].archetypes[arch].levels
	for lv in range(2, 6):
		var gain := String(levels[str(lv)])
		var key := ("TRAIT_" if CombatData.table("traits").has(gain) else "ABILITY_") + gain
		var got := lv <= level
		var line := UiKit.label("%d · %s" % [lv, tr_(key)], UiKit.FONT_SMALL,
			UiKit.ACCENT if lv == level else (UiKit.TEXT if got else UiKit.MUTED))
		line.tooltip_text = tr_(key + "_DESC")
		line.mouse_filter = Control.MOUSE_FILTER_PASS
		box.add_child(line)
		if lv == level:
			var d := UiKit.label(tr_(key + "_DESC"), UiKit.FONT_SMALL, UiKit.TEXT)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size = Vector2(360, 0)
			box.add_child(d)
	var text := UiKit.fmt("LEVELUP_KEEP" if arch == current else ("LEVELUP_CHOOSE" if current == "" else "LEVELUP_SWITCH"),
		{"branch": tr_("ARCH_" + arch)})
	box.add_child(UiKit.button(text, func() -> void: on_done.call(arch)))
	return box


## Торговец. on_done(buy: Array) — покупки [[предмет, владелец], …] в порядке нажатий.
static func shop(root: Control, shop_id: String, on_done: Callable) -> Control:
	Sound.sfx("coin")
	var f := _frame(root)
	var col: VBoxContainer = f[1]
	var silver := [Game.session.state.silver]
	var buy: Array = []
	col.add_child(UiKit.heading(tr_("SHOP_" + shop_id), UiKit.HEAD_BODY))
	var purse := UiKit.label("", UiKit.FONT_SMALL, UiKit.ACCENT)
	col.add_child(purse)
	var owners: Array[String] = ["hero"]
	owners.append_array(Game.session.companions())
	var buttons: Array[Button] = []
	var refresh := func() -> void:
		purse.text = UiKit.fmt("SHOP_SILVER", {"silver": silver[0]})
		for b in buttons:
			b.disabled = int(b.get_meta("price")) > silver[0] or bool(b.get_meta("sold"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	for s in Shops.stock(shop_id):
		var name := UiKit.label("%s — %d" % [tr_("ITEM_" + String(s.id)), int(s.price)], UiKit.FONT_SMALL)
		name.autowrap_mode = TextServer.AUTOWRAP_OFF
		grid.add_child(name)
		var fx := UiKit.label(_item_effect(String(s.id)), UiKit.FONT_SMALL, UiKit.MUTED)
		fx.autowrap_mode = TextServer.AUTOWRAP_OFF
		grid.add_child(fx)
		var who := HBoxContainer.new()
		who.add_theme_constant_override("separation", 6)
		var row_buttons: Array[Button] = []
		for o in owners:
			if not Shops.fits(shop_id, String(s.id), o):
				continue
			var label := tr_("SHOP_FOR_HERO") if o == "hero" else UiKit.fmt("SHOP_FOR", {"name": tr_("COMPANION_" + o)})
			var b := UiKit.button(label, Callable(), UiKit.FONT_SMALL, "coin")
			b.set_meta("price", int(s.price))
			b.set_meta("sold", false)
			b.pressed.connect(func() -> void:
				if int(s.price) > silver[0]:
					return
				silver[0] -= int(s.price)
				buy.append([String(s.id), o])
				for rb in row_buttons:
					rb.set_meta("sold", true)
				refresh.call())
			row_buttons.append(b)
			buttons.append(b)
			who.add_child(b)
		grid.add_child(who)
	col.add_child(UiKit.button(tr_("SHOP_LEAVE"), func() -> void: on_done.call(buy)))
	refresh.call()
	UiKit.focus_first(col)
	return f[0]


## Свойства вещи одной строкой: «+1 КД, спасброски +1» (по fx из items.json).
static func _item_effect(item_id: String) -> String:
	if not Items.has_item(item_id):
		return ""
	var fx: Dictionary = Items.catalog()[item_id].fx
	var parts := PackedStringArray()
	for k in ["hit", "dmg", "ac", "save", "hp", "spell", "slot", "heal", "dr"]:
		if int(fx.get(k, 0)) != 0:
			parts.append(UiKit.fmt("FX_" + k, {"n": int(fx[k])}))
	return ", ".join(parts)


static func tr_(key: String) -> String:
	return TranslationServer.translate(key)
