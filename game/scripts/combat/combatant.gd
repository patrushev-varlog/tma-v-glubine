class_name Combatant
extends RefCounted
## Участник боя: герой, спутник или враг. Состояния — словарь statuses (данные в statuses.json),
## пассивные приёмы — список traits (traits.json); их свойства читает Battle через CombatData.

## Имя для журнала боя; интерфейс берёт имя из перевода по kind (CombatData.unit_name).
var name := ""
var id := ""
var team := 0
## Класс героя, id спутника или вид врага.
var kind := ""
var color := Color.WHITE
var letter := "?"

var level := 1
var archetype := ""
var max_hp := 1
var hp := 1
var ac := 10
var speed := 6
var init_mod := 0
var saves := {}
var weapon := {}
var ranged_weapon := {}
var abilities: Array[String] = []
var traits: Array[String] = []
var uses := {}
var slots := 0
var max_slots := 0
var spell_attack := 5
var spell_dc := 13
var attacks_per_action := 1
var str_mod := 0
var undead := false
var sneak_dice := ""
var is_hero := false
var is_companion := false
## Союзник под ИИ (узники в бунте главы 1): на стороне отряда, но ходит сам и в поражении не считается.
var ai_ally := false

## Экипировка: надетые предметы и то, что они дают в бою (см. Items).
var items: Array[String] = []
var heal_bonus := 0
var dr := 0
var undead_dice := ""
var drain_dice := ""
var fire_dice := ""
var item_dark := 0

var cell := Vector2i.ZERO
var initiative := 0
var down := false
var dead := false
var reaction_used := false
var speed_left := 0
var action_used := false
## Сколько ударов осталось в начатом действии «Атака»; 0 — действие ещё не начато.
var attacks_left := 0
var bonus_used := false
var sneak_used := false
var cleave_used := false
## Ходил ли уже в этом бою (для «Убийства»).
var acted := false
## Состояния: id → {"src": id наложившего, "value": число или кости, "fresh": только что наложено}.
var statuses := {}
## Счётчики «раз за бой» и «раз за ход» для приёмов и предметов: ключ → сколько раз сработало.
var counters := {}

## Простые поля, которые сохраняются как есть.
const STATE := ["id", "name", "team", "kind", "letter", "level", "archetype", "max_hp", "hp", "ac", "speed", "init_mod",
	"slots", "max_slots", "spell_attack", "spell_dc", "attacks_per_action", "str_mod", "undead", "sneak_dice",
	"is_hero", "is_companion", "ai_ally", "heal_bonus", "dr", "undead_dice", "drain_dice", "fire_dice", "item_dark",
	"initiative", "down", "dead", "reaction_used", "speed_left", "action_used", "attacks_left", "bonus_used",
	"sneak_used", "cleave_used", "acted"]


func conscious() -> bool:
	return not down and not dead


func has_status(sid: String) -> bool:
	return statuses.has(sid)


func status_value(sid: String) -> Variant:
	return statuses[sid].get("value", 0) if statuses.has(sid) else null


func status_src(sid: String) -> String:
	return String(statuses[sid].get("src", "")) if statuses.has(sid) else ""


func has_trait(trait_id: String) -> bool:
	return traits.has(trait_id)


func save_bonus(stat: String) -> int:
	return int(saves.get(stat, 0))


func reach() -> int:
	return int(weapon.get("reach", 1))


func is_ranged() -> bool:
	return weapon.get("kind", "melee") == "ranged"


## СЛ толчка: 8 + бонус мастерства 2 + Сила.
func shove_dc() -> int:
	return 10 + str_mod


func uses_left(ability_id: String) -> int:
	return int(uses.get(ability_id, 0))


func to_dict() -> Dictionary:
	var d := {}
	for f in STATE:
		d[f] = get(f)
	d["color"] = color.to_html()
	d["saves"] = saves
	d["weapon"] = weapon
	d["ranged_weapon"] = ranged_weapon
	d["abilities"] = Array(abilities)
	d["traits"] = Array(traits)
	d["items"] = Array(items)
	d["uses"] = uses
	d["statuses"] = statuses
	d["counters"] = counters
	d["cell"] = [cell.x, cell.y]
	return d


static func from_dict(d: Dictionary) -> Combatant:
	var c := Combatant.new()
	for f in STATE:
		if not d.has(f):
			continue
		match typeof(c.get(f)):
			TYPE_INT:
				c.set(f, int(d[f]))
			TYPE_BOOL:
				c.set(f, bool(d[f]))
			_:
				c.set(f, String(d[f]))
	c.color = Color.html(d.color)
	c.saves = ints(d.saves)
	c.weapon = ints(d.weapon)
	c.ranged_weapon = ints(d.get("ranged_weapon", {}))
	for a in d.abilities:
		c.abilities.append(String(a))
	for t in d.get("traits", []):
		c.traits.append(String(t))
	for it in d.get("items", []):
		c.items.append(String(it))
	c.uses = ints(d.uses)
	for sid in d.get("statuses", {}):
		c.statuses[String(sid)] = ints(d.statuses[sid])
	c.counters = ints(d.get("counters", {}))
	c.cell = Vector2i(int(d.cell[0]), int(d.cell[1]))
	return c


## JSON возвращает числа как float; возвращаем целые, чтобы правила считали так же.
static func ints(src: Dictionary) -> Dictionary:
	return CombatData.whole_numbers(src)
