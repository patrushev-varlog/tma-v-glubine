class_name AbilityIcon
extends Button
## Кнопка умения на панели боя: иконка, клавиша, сколько осталось. Пока иконок из потока K нет,
## рисуется заглушка: плашка по типу действия и две буквы названия. Готовая иконка подхватится
## из res://art/icons/abilities/<id>.png.

const ART := "res://art/icons/abilities/%s.png"
const SIZE := Vector2(60, 60)
## Цвет плашки: действие, бонусное, без действия, тёмный дар, конец хода.
const KIND_COLORS := {
	"action": Color("#8a4b3c"), "bonus": Color("#8a6d32"), "free": Color("#3f6a5a"),
	"dark": Color("#5b3a7a"), "spell": Color("#3c5a8a"), "end": Color("#4a4f58"),
}

var ability_id := ""
var kind := "action"
var abbr := ""
var hotkey := ""
var badge := ""
var selected := false
var _tex: Texture2D = null


static func make(aid: String, kind_: String, abbr_: String, hotkey_: String, badge_: String) -> AbilityIcon:
	var b := AbilityIcon.new()
	b.ability_id = aid
	b.kind = kind_
	b.abbr = abbr_
	b.hotkey = hotkey_
	b.badge = badge_
	b.custom_minimum_size = SIZE
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	var p := ART % aid
	if aid != "" and ResourceLoader.exists(p):
		b._tex = load(p)
	return b


## Две буквы для заглушки: «Огненный снаряд» → «ОС», «Аркан» → «Ар».
static func abbreviate(name: String) -> String:
	var words := name.replace("«", "").replace("»", "").replace("!", "").split(" ", false)
	if words.size() >= 2:
		return (words[0].left(1) + words[1].left(1)).to_upper()
	return name.left(2)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var col: Color = KIND_COLORS.get(kind, KIND_COLORS.action)
	if disabled:
		col = col.darkened(0.55)
	elif is_hovered():
		col = col.lightened(0.15)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(6)
	sb.border_color = Color("#f9c22b") if selected else col.lightened(0.3)
	sb.set_border_width_all(3 if selected else 1)
	draw_style_box(sb, r)
	var font := get_theme_default_font()
	var fg := Color(1, 1, 1, 0.45 if disabled else 1.0)
	if _tex != null:
		draw_texture_rect(_tex, r.grow(-6), false, fg)
	else:
		draw_string(font, Vector2(0, size.y * 0.5 + 9), abbr, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, fg)
	if hotkey != "":
		draw_string(font, Vector2(5, 15), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.7))
	if badge != "":
		var bw := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 8
		var br := Rect2(Vector2(size.x - bw - 2, size.y - 18), Vector2(bw, 16))
		draw_rect(br, Color(0, 0, 0, 0.6))
		draw_string(font, br.position + Vector2(4, 12), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, fg)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
		queue_redraw()
