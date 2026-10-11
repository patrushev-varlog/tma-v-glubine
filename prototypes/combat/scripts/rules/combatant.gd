class_name Combatant
extends RefCounted
## Участник боя: герой, спутник или враг.

var id := ""
var name := ""
var team := 0
var kind := ""
var color := Color.WHITE
var letter := "?"

var max_hp := 1
var hp := 1
var ac := 10
var speed := 6
var init_mod := 0
var saves := {}
var weapon := {}
var abilities: Array[String] = []
var uses := {}
var slots := 0
var max_slots := 0
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
var bonus_used := false
var sneak_used := false
var disengaged := false
var hidden := false
var ac_bonus := 0
var taunted_by := ""
var taunt_turns := 0


func conscious() -> bool:
	return not down and not dead


func total_ac() -> int:
	return ac + ac_bonus


func save_bonus(stat: String) -> int:
	return int(saves.get(stat, 0))


func reach() -> int:
	return int(weapon.get("reach", 1))


func is_ranged() -> bool:
	return weapon.get("kind", "melee") == "ranged"


func uses_left(ability_id: String) -> int:
	return int(uses.get(ability_id, 0))


func to_dict() -> Dictionary:
	return {
		"id": id, "name": name, "team": team, "kind": kind,
		"color": color.to_html(), "letter": letter,
		"max_hp": max_hp, "hp": hp, "ac": ac, "speed": speed, "init_mod": init_mod,
		"saves": saves, "weapon": weapon, "abilities": Array(abilities), "uses": uses,
		"slots": slots, "max_slots": max_slots, "undead": undead, "sneak_dice": sneak_dice,
		"is_hero": is_hero, "is_companion": is_companion,
		"cell": [cell.x, cell.y], "initiative": initiative, "down": down, "dead": dead,
		"prone": prone, "reaction_used": reaction_used, "speed_left": speed_left,
		"action_used": action_used, "bonus_used": bonus_used, "sneak_used": sneak_used,
		"disengaged": disengaged, "hidden": hidden, "ac_bonus": ac_bonus,
		"taunted_by": taunted_by, "taunt_turns": taunt_turns,
	}


static func from_dict(d: Dictionary) -> Combatant:
	var c := Combatant.new()
	c.id = d.id
	c.name = d.name
	c.team = int(d.team)
	c.kind = d.kind
	c.color = Color.html(d.color)
	c.letter = d.letter
	c.max_hp = int(d.max_hp)
	c.hp = int(d.hp)
	c.ac = int(d.ac)
	c.speed = int(d.speed)
	c.init_mod = int(d.init_mod)
	c.saves = _ints(d.saves)
	c.weapon = _ints(d.weapon)
	for a in d.abilities:
		c.abilities.append(String(a))
	c.uses = _ints(d.uses)
	c.slots = int(d.slots)
	c.max_slots = int(d.max_slots)
	c.undead = bool(d.undead)
	c.sneak_dice = d.sneak_dice
	c.is_hero = bool(d.is_hero)
	c.is_companion = bool(d.is_companion)
	c.cell = Vector2i(int(d.cell[0]), int(d.cell[1]))
	c.initiative = int(d.initiative)
	c.down = bool(d.down)
	c.dead = bool(d.dead)
	c.prone = bool(d.prone)
	c.reaction_used = bool(d.reaction_used)
	c.speed_left = int(d.speed_left)
	c.action_used = bool(d.action_used)
	c.bonus_used = bool(d.bonus_used)
	c.sneak_used = bool(d.sneak_used)
	c.disengaged = bool(d.disengaged)
	c.hidden = bool(d.hidden)
	c.ac_bonus = int(d.ac_bonus)
	c.taunted_by = d.taunted_by
	c.taunt_turns = int(d.taunt_turns)
	return c


## JSON возвращает числа как float; возвращаем целые, чтобы правила считали так же.
static func _ints(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		var v = src[k]
		out[k] = int(v) if typeof(v) == TYPE_FLOAT and v == floorf(v) else v
	return out
