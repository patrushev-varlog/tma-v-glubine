class_name Combatant
extends RefCounted
## Участник боя: герой, спутник или враг.

var id := ""
var name := ""
var team := 0
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

var cell := Vector2i.ZERO
var initiative := 0
var down := false
var dead := false
var prone := false
var reaction_used := false
var speed_left := 0
var action_used := false
## Сколько ударов осталось в начатом действии «Атака»; 0 — действие ещё не начато.
var attacks_left := 0
var bonus_used := false
var sneak_used := false
var cleave_used := false
var disengaged := false
var hidden := false
## Спрятался не в этот ход: скрытность спадёт в конце хода, если не спрятаться снова.
var hide_expiring := false
var dodging := false
var ac_bonus := 0
var taunted_by := ""
var taunt_turns := 0
## Ходил ли уже в этом бою (для «Убийства»).
var acted := false
## Кто наложил «Направляющий снаряд» или «Луч холода»; эффект снимается в начале его хода.
var guided_by := ""
var slowed_by := ""
## Изгнанная нежить бежит и не атакует, пока не получит урон.
var turned := false
var raging := false
var reckless := false
var relentless_used := false
var poison_ready := false
## «Шаг в тень»: следующее попадание добавляет некротический урон и лечит.
var shadow_ready := false
## Отравлен ядом плута: бьёт с помехой до конца своего хода.
var poisoned := false
var uncanny_used := false
var spirit_weapon := false
var guardians := false
## Опутан паутиной: не ходит, бьёт с помехой, по нему с преимуществом.
var restrained := false
## Под «Замедлением»: −2 КД, половина движения, одна атака, без атак при возможности.
var slow_spell := false
## Парализован гулем: пропускает ход.
var stunned := false

## Экипировка (см. Items): надетые предметы и то, что они дают в бою.
var items: Array[String] = []
var heal_bonus := 0
var dr := 0
var undead_dice := ""
var drain_dice := ""
## Кости огнём при попадании оружием по любому врагу (молот литейщика).
var fire_dice := ""
## Разовые за бой именные правила легендарок: «Шёпот», «Молчание»; «Уворот» с плащом литейщика — до двух раз.
var whisper_used := false
var silence_used := false
var uncanny_count := 0
var rally := false
var rally_used := false
var rescue := false
var rescue_used := false
var ring := false
var item_dark := 0

## Простые поля состояния, которые сохраняются как есть.
const STATE := ["id", "name", "team", "kind", "letter", "level", "archetype", "max_hp", "hp", "ac", "speed", "init_mod",
	"slots", "max_slots", "spell_attack", "spell_dc", "attacks_per_action", "str_mod", "undead", "sneak_dice",
	"is_hero", "is_companion", "initiative", "down", "dead", "prone", "reaction_used", "speed_left", "action_used",
	"attacks_left", "bonus_used", "sneak_used", "cleave_used", "disengaged", "hidden", "hide_expiring", "dodging", "ac_bonus",
	"taunted_by", "taunt_turns", "acted", "guided_by", "slowed_by", "turned", "raging", "reckless",
	"relentless_used", "poison_ready", "shadow_ready", "poisoned", "uncanny_used", "spirit_weapon", "guardians", "restrained",
	"slow_spell", "stunned", "heal_bonus", "dr", "undead_dice", "drain_dice", "fire_dice", "whisper_used", "silence_used", "uncanny_count", "rally", "rally_used", "rescue",
	"rescue_used", "ring", "item_dark"]


func conscious() -> bool:
	return not down and not dead


func total_ac() -> int:
	return ac + ac_bonus - (2 if slow_spell else 0)


func save_bonus(stat: String) -> int:
	return int(saves.get(stat, 0))


func reach() -> int:
	return int(weapon.get("reach", 1))


func has_trait(trait_id: String) -> bool:
	return traits.has(trait_id)


## СЛ толчка: 8 + бонус мастерства 2 + Сила.
func shove_dc() -> int:
	return 10 + str_mod


## Может ли сейчас атаковать при возможности.
func can_react() -> bool:
	return conscious() and not reaction_used and not turned and not slow_spell and not stunned and not is_ranged()


func is_ranged() -> bool:
	return weapon.get("kind", "melee") == "ranged"


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
	c.saves = _ints(d.saves)
	c.weapon = _ints(d.weapon)
	c.ranged_weapon = _ints(d.get("ranged_weapon", {}))
	for a in d.abilities:
		c.abilities.append(String(a))
	for t in d.get("traits", []):
		c.traits.append(String(t))
	for it in d.get("items", []):
		c.items.append(String(it))
	c.uses = _ints(d.uses)
	c.cell = Vector2i(int(d.cell[0]), int(d.cell[1]))
	return c


## JSON возвращает числа как float; возвращаем целые, чтобы правила считали так же.
static func _ints(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		var v = src[k]
		out[k] = int(v) if typeof(v) == TYPE_FLOAT and v == floorf(v) else v
	return out
