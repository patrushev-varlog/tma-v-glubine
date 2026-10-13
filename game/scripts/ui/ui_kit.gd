class_name UiKit
extends RefCounted
## Общие кирпичики интерфейса: палитра, надписи, кнопки, рамки. Экраны собираются кодом,
## чтобы вёрстка была в одном месте и одинаково работала с мышью, клавиатурой и геймпадом.
## Палитра та же, что в срезе стека (prototypes/stack-slice).

const BG := Color("#2e222f")
const PANEL := Color("#3e3546")
const TEXT := Color("#c7dcd0")
const MUTED := Color("#9babb2")
const ACCENT := Color("#f9c22b")
const HERO := Color("#7aa7e8")
const SPEAKER := Color("#e6d6b8")
const DANGER := Color("#e83b3b")

const FONT_TITLE := 40
const FONT_BODY := 22
const FONT_SMALL := 17
## Кегли пиксельного шрифта заголовков: пиксель шрифта — 1/8 кегля, чёткий только на кратных 8.
const HEAD_TITLE := 40
const HEAD_BODY := 24
const HEAD_SMALL := 16

## Шрифты (DESIGN.md, раздел 4; выбраны на прототипе локации, поток G): длинный текст — Literata,
## заголовки и подписи — пиксельный Tiny5. Оба под OFL, тексты лицензий в fonts/.
const FONTS := {"body": "res://fonts/Literata.ttf", "heading": "res://fonts/Tiny5.ttf"}

static var _fonts := {}


static func label(text := "", size := FONT_BODY, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Надпись пиксельным шрифтом: заголовки, имена говорящих, подписи на карте.
static func heading(text := "", size := HEAD_BODY, color := ACCENT) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", heading_font())
	return l


static func body_font() -> Font:
	return _font("body")


static func heading_font() -> Font:
	return _font("heading")


static func _font(kind: String) -> Font:
	if not _fonts.has(kind):
		var f: FontFile = (load(String(FONTS[kind])) as FontFile).duplicate()
		if kind == "heading":
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_fonts[kind] = f
	return _fonts[kind]


## Тема всего окна: шрифт текста по умолчанию (ставит автозагрузка Game).
static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = FONT_BODY
	return t


static func button(text: String, on_press: Callable = Callable(), size := FONT_BODY) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(0, 44)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


## Фон на весь экран и отступы; возвращает колонку для содержимого.
static func screen(root: Control, separation := 12) -> VBoxContainer:
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var margin := margins(24)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", separation)
	margin.add_child(col)
	return col


static func margins(px: int) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, px)
	return m


## Рамка поверх экрана (журнал, сохранения): затемнение и панель по центру.
static func overlay(root: Control) -> VBoxContainer:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	return col


## Подставить значения в строку перевода: fmt("BATTLE_WON", {"rounds": 3}).
static func fmt(key: String, values := {}) -> String:
	return TranslationServer.translate(key).format(values)


## Фокус на первую кнопку внутри узла (для геймпада и клавиатуры).
static func focus_first(node: Node) -> void:
	for c in node.find_children("*", "Button", true, false):
		if c.is_visible_in_tree() and not c.disabled:
			# По id, а не захватом кнопки: если до конца кадра кнопку уберут, захват был бы освобождён.
			var id := c.get_instance_id()
			(func() -> void:
				var b := instance_from_id(id) as Button
				if b != null and b.is_inside_tree():
					b.grab_focus()).call_deferred()
			return
