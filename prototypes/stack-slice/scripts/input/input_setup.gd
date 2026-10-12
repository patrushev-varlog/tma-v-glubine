extends Node
## Автозагрузка: раскладка ввода для клавиатуры, мыши и геймпада + какое устройство сейчас в руках.
## Godot 4.7 по умолчанию не вешает кнопки геймпада на ui_accept и ui_cancel (только D-pad и левый
## стик на стрелки), поэтому добавляем их сами. Steam Deck через Steam Input виден как геймпад Xbox.

signal device_changed(kind: String)

## "keyboard" (клавиатура и мышь) или "xbox" / "playstation" / "nintendo" / "deck".
var device := "keyboard"

const ACTIONS := {
	# действие: клавиши и кнопки геймпада
	"ui_accept": {"joy": [JOY_BUTTON_A]},
	"ui_cancel": {"joy": [JOY_BUTTON_B]},
	"ui_up": {"keys": [KEY_W]},
	"ui_down": {"keys": [KEY_S]},
	"ui_left": {"keys": [KEY_A]},
	"ui_right": {"keys": [KEY_D]},
	"slice_language": {"keys": [KEY_L], "joy": [JOY_BUTTON_Y]},
	"slice_art": {"keys": [KEY_T], "joy": [JOY_BUTTON_X]},
	"slice_dark_down": {"keys": [KEY_Q], "joy": [JOY_BUTTON_LEFT_SHOULDER]},
	"slice_dark_up": {"keys": [KEY_R], "joy": [JOY_BUTTON_RIGHT_SHOULDER]},
	"slice_focus": {"keys": [KEY_TAB], "joy": [JOY_BUTTON_BACK]},
	"slice_restart": {"keys": [KEY_F5], "joy": [JOY_BUTTON_START]},
}


func _ready() -> void:
	# Tab забираем себе: переключение «поле / диалог», а не обход фокуса.
	for ev in InputMap.action_get_events("ui_focus_next"):
		if ev is InputEventKey and ev.keycode == KEY_TAB:
			InputMap.action_erase_event("ui_focus_next", ev)
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)
		for code in ACTIONS[action].get("keys", []):
			var key := InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(action, key)
		for code in ACTIONS[action].get("joy", []):
			var button := InputEventJoypadButton.new()
			button.button_index = code
			button.device = -1  # любой геймпад
			InputMap.action_add_event(action, button)


func _input(event: InputEvent) -> void:
	var kind := device
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.4):
		kind = joy_kind(Input.get_joy_name(event.device))
	elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 2.0):
		kind = "keyboard"
	if kind != device:
		device = kind
		device_changed.emit(kind)


static func joy_kind(name: String) -> String:
	var n := name.to_lower()
	if n.contains("steam deck") or n.contains("steam virtual") or n.contains("valve"):
		return "deck"
	if n.contains("ps3") or n.contains("ps4") or n.contains("ps5") or n.contains("dualsense") or n.contains("dualshock") or n.contains("playstation") or n.contains("sony"):
		return "playstation"
	if n.contains("nintendo") or n.contains("switch") or n.contains("joy-con"):
		return "nintendo"
	return "xbox"


## Подпись кнопки для подсказок на экране под текущее устройство.
func glyph(action: String) -> String:
	if device == "keyboard":
		return {
			"ui_accept": "Enter", "ui_cancel": "Esc", "slice_language": "L", "slice_art": "T",
			"slice_dark_down": "Q", "slice_dark_up": "R", "slice_focus": "Tab", "slice_restart": "F5",
			"move": tr("GLYPH_MOVE_KEYS"),
		}.get(action, action)
	var face: Dictionary = {
		"xbox": {"a": "A", "b": "B", "x": "X", "y": "Y", "lb": "LB", "rb": "RB", "back": "View", "start": "Menu"},
		"deck": {"a": "A", "b": "B", "x": "X", "y": "Y", "lb": "L1", "rb": "R1", "back": "View", "start": "Menu"},
		"playstation": {"a": "✕", "b": "○", "x": "□", "y": "△", "lb": "L1", "rb": "R1", "back": "Share", "start": "Options"},
		# У Nintendo нижняя кнопка подписана B: SDL отдаёт её как JOY_BUTTON_A (позиция, не буква).
		"nintendo": {"a": "B", "b": "A", "x": "Y", "y": "X", "lb": "L", "rb": "R", "back": "−", "start": "+"},
	}[device]
	return {
		"ui_accept": face["a"], "ui_cancel": face["b"], "slice_language": face["y"], "slice_art": face["x"],
		"slice_dark_down": face["lb"], "slice_dark_up": face["rb"], "slice_focus": face["back"],
		"slice_restart": face["start"], "move": tr("GLYPH_MOVE_PAD"),
	}.get(action, action)
