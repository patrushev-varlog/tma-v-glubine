class_name Content
extends RefCounted
## Классы героя, спутники, враги, способности и сценарий боя.
## Цифры — урезанный SRD 5.2 для героев 2 уровня; уточняются на тестах.

const SPELL_DC := 13
const SPELL_ATTACK := 5

const ABILITIES := {
	"second_wind": {"name": "Второе дыхание", "cost": "bonus", "resource": "use", "target": "self", "range": 0,
		"desc": "Лечит себя на 1d10+2."},
	"disengage": {"name": "Отход", "cost": "bonus", "resource": "none", "target": "self", "range": 0,
		"desc": "До конца хода уход от врагов не провоцирует атаки."},
	"sacred_flame": {"name": "Священное пламя", "cost": "action", "resource": "none", "target": "enemy", "range": 12,
		"desc": "Спасбросок Ловкости, 1d8 урона светом."},
	"healing_word": {"name": "Слово исцеления", "cost": "bonus", "resource": "slot", "target": "ally", "range": 12,
		"desc": "Лечит союзника на 1d4+3, поднимает выбывшего."},
	"fire_bolt": {"name": "Огненный снаряд", "cost": "action", "resource": "none", "target": "enemy", "range": 24,
		"desc": "Атака заклинанием, 1d10 огнём."},
	"magic_missile": {"name": "Волшебная стрела", "cost": "action", "resource": "slot", "target": "enemy", "range": 24,
		"desc": "Без промаха: 3d4+3 силовым полем."},
	"thunderwave": {"name": "Громовая волна", "cost": "action", "resource": "slot", "target": "self", "range": 0, "radius": 1,
		"desc": "Все вокруг: спасбросок Телосложения, 2d8 звуком, половина при успехе. Задевает и своих."},
	"hallowed_ground": {"name": "Освящённая земля", "cost": "action", "resource": "slot", "target": "cell", "range": 12, "radius": 1,
		"desc": "Зона 3×3: союзники лечатся на 1d6, нежить получает 2d6 светом."},
	"shield_of_faith": {"name": "Щит веры", "cost": "bonus", "resource": "slot", "target": "ally", "range": 12,
		"desc": "+2 к КД союзника до конца боя."},
	"trip": {"name": "Сбить с ног", "cost": "action", "resource": "use", "target": "enemy", "range": 1,
		"desc": "Атака оружием; при попадании спасбросок Силы или враг падает."},
	"taunt": {"name": "Провокация", "cost": "bonus", "resource": "use", "target": "self", "range": 0, "radius": 3,
		"desc": "Враги в 3 клетках атакуют Гаррета в свой следующий ход."},
	"bomb": {"name": "Алхимическая бомба", "cost": "action", "resource": "use", "target": "cell", "range": 6, "radius": 1,
		"desc": "Зона 3×3: спасбросок Ловкости, 2d6 огнём, половина при успехе. Задевает и своих."},
	"trap": {"name": "Ловушка", "cost": "action", "resource": "use", "target": "empty_cell", "range": 3,
		"desc": "Скрытая ловушка: первый враг на клетке получает 2d6 и останавливается."},
	"cursed_blade": {"name": "Проклятый клинок", "cost": "action", "resource": "none", "target": "enemy", "range": 1, "dark": true,
		"desc": "Тёмный дар. Атака оружием +1d8 некротикой, лечит на половину."},
	"shadow_step": {"name": "Шаг в тень", "cost": "bonus", "resource": "none", "target": "self", "range": 0, "dark": true,
		"desc": "Тёмный дар. Преимущество на следующую атаку, уход без атак при возможности."},
	"wither": {"name": "Иссушение", "cost": "action", "resource": "none", "target": "enemy", "range": 12, "dark": true,
		"desc": "Тёмный дар. Спасбросок Телосложения, 2d8 некротикой; столько же лечит самого раненого союзника."},
	"life_drain": {"name": "Высасывание жизни", "cost": "action", "resource": "none", "target": "enemy", "range": 12, "dark": true,
		"desc": "Тёмный дар. Атака заклинанием, 3d6 некротикой, лечит себя на половину."},
}

const HERO_CLASSES := {
	"fighter": {"name": "Воин", "max_hp": 20, "ac": 16, "init": 0,
		"saves": {"str": 5, "dex": 0, "con": 4, "wis": 1},
		"weapon": {"name": "Длинный меч", "to_hit": 5, "damage": "1d8+3", "reach": 1, "kind": "melee"},
		"abilities": ["second_wind", "cursed_blade"], "uses": {"second_wind": 1}},
	"rogue": {"name": "Плут", "max_hp": 15, "ac": 14, "init": 3,
		"saves": {"str": 0, "dex": 5, "con": 1, "wis": 1},
		"weapon": {"name": "Короткий меч", "to_hit": 5, "damage": "1d6+3", "reach": 1, "kind": "melee"},
		"sneak": "1d6", "abilities": ["disengage", "shadow_step"], "uses": {}},
	"cleric": {"name": "Жрец", "max_hp": 17, "ac": 18, "init": 0,
		"saves": {"str": 1, "dex": 0, "con": 2, "wis": 5},
		"weapon": {"name": "Булава", "to_hit": 4, "damage": "1d6+2", "reach": 1, "kind": "melee"},
		"slots": 3, "abilities": ["sacred_flame", "healing_word", "wither"], "uses": {}},
	"wizard": {"name": "Волшебник", "max_hp": 12, "ac": 12, "init": 2,
		"saves": {"str": -1, "dex": 2, "con": 1, "wis": 3},
		"weapon": {"name": "Посох", "to_hit": 1, "damage": "1d6-1", "reach": 1, "kind": "melee"},
		"slots": 3, "abilities": ["fire_bolt", "magic_missile", "thunderwave", "life_drain"], "uses": {}},
}

const COMPANIONS := {
	"irena": {"name": "Ирена", "letter": "И", "color": "#e8d27a", "max_hp": 17, "ac": 16, "init": 0,
		"saves": {"str": 1, "dex": 0, "con": 2, "wis": 5},
		"weapon": {"name": "Булава", "to_hit": 4, "damage": "1d6+2", "reach": 1, "kind": "melee"},
		"slots": 3, "abilities": ["sacred_flame", "healing_word", "hallowed_ground", "shield_of_faith"], "uses": {}},
	"garret": {"name": "Гаррет", "letter": "Г", "color": "#c97b4a", "max_hp": 22, "ac": 17, "init": 0,
		"saves": {"str": 5, "dex": 0, "con": 4, "wis": 0},
		"weapon": {"name": "Длинный меч", "to_hit": 5, "damage": "1d8+3", "reach": 1, "kind": "melee"},
		"abilities": ["trip", "taunt"], "uses": {"trip": 2, "taunt": 2}},
	"velior": {"name": "Велиор", "letter": "В", "color": "#6fb07a", "max_hp": 15, "ac": 14, "init": 3,
		"saves": {"str": 0, "dex": 5, "con": 1, "wis": 1},
		"weapon": {"name": "Короткий меч", "to_hit": 5, "damage": "1d6+3", "reach": 1, "kind": "melee"},
		"sneak": "1d6", "abilities": ["bomb", "trap"], "uses": {"bomb": 2, "trap": 2}},
}

const ENEMIES := {
	"overseer": {"name": "Надсмотрщик", "letter": "н", "max_hp": 11, "ac": 12, "init": 1, "speed": 6,
		"saves": {"str": 1, "dex": 1, "con": 1, "wis": 0},
		"weapon": {"name": "Сабля", "to_hit": 3, "damage": "1d6+1", "reach": 1, "kind": "melee"}},
	"overseer_chief": {"name": "Старший надсмотрщик", "letter": "Н", "max_hp": 22, "ac": 14, "init": 2, "speed": 6,
		"saves": {"str": 4, "dex": 2, "con": 2, "wis": 2},
		"weapon": {"name": "Длинный меч", "to_hit": 4, "damage": "1d8+2", "reach": 1, "kind": "melee"}},
	"zombie": {"name": "Зомби", "letter": "з", "max_hp": 15, "ac": 8, "init": -2, "speed": 4, "undead": true,
		"saves": {"str": 1, "dex": -2, "con": 3, "wis": 0},
		"weapon": {"name": "Удар", "to_hit": 3, "damage": "1d6+1", "reach": 1, "kind": "melee"}},
	"skeleton_archer": {"name": "Скелет-лучник", "letter": "с", "max_hp": 13, "ac": 13, "init": 2, "speed": 6, "undead": true,
		"saves": {"str": 0, "dex": 2, "con": 2, "wis": -1},
		"weapon": {"name": "Короткий лук", "to_hit": 4, "damage": "1d6+2", "range": 16, "kind": "ranged"}},
}

const HERO_COLOR := "#7aa7e8"


static func make_hero(class_id: String) -> Combatant:
	var t: Dictionary = HERO_CLASSES[class_id]
	var c := _from_template(t, "hero", class_id)
	c.name = "Герой (%s)" % t.name
	c.letter = "Я"
	c.color = Color.html(HERO_COLOR)
	c.is_hero = true
	return c


static func make_companion(comp_id: String) -> Combatant:
	var t: Dictionary = COMPANIONS[comp_id]
	var c := _from_template(t, comp_id, comp_id)
	c.name = t.name
	c.letter = t.letter
	c.color = Color.html(t.color)
	c.is_companion = true
	return c


static func make_enemy(kind: String, idx: int) -> Combatant:
	var t: Dictionary = ENEMIES[kind]
	var c := _from_template(t, "%s_%d" % [kind, idx], kind)
	c.name = t.name
	c.letter = t.letter
	c.team = 1
	c.color = Color.html("#b9505a") if not t.get("undead", false) else Color.html("#a596d6")
	c.undead = t.get("undead", false)
	return c


static func _from_template(t: Dictionary, id: String, kind: String) -> Combatant:
	var c := Combatant.new()
	c.id = id
	c.kind = kind
	c.max_hp = t.max_hp
	c.hp = t.max_hp
	c.ac = t.ac
	c.speed = t.get("speed", 6)
	c.init_mod = t.get("init", 0)
	c.saves = t.saves.duplicate()
	c.weapon = t.weapon.duplicate()
	for a in t.get("abilities", []):
		c.abilities.append(String(a))
	c.uses = t.get("uses", {}).duplicate()
	c.slots = t.get("slots", 0)
	c.max_slots = c.slots
	c.sneak_dice = t.get("sneak", "")
	return c


## Бой 3 пролога: колонна пленных на привале у ворот рудника.
static func scenario_column(hero_class: String, with_velior: bool) -> Dictionary:
	var heroes: Array[Combatant] = [make_hero(hero_class), make_companion("irena"), make_companion("garret")]
	var hero_cells := [Vector2i(1, 9), Vector2i(2, 10), Vector2i(2, 8), Vector2i(3, 10)]
	if with_velior:
		heroes.append(make_companion("velior"))
	for i in heroes.size():
		heroes[i].cell = hero_cells[i]
	var enemies: Array[Combatant] = [
		make_enemy("overseer_chief", 1),
		make_enemy("overseer", 1),
		make_enemy("overseer", 2),
		make_enemy("zombie", 1),
		make_enemy("zombie", 2),
		make_enemy("skeleton_archer", 1),
	]
	var enemy_cells := [Vector2i(9, 2), Vector2i(8, 4), Vector2i(10, 4), Vector2i(7, 2), Vector2i(9, 6), Vector2i(10, 1)]
	for i in enemies.size():
		enemies[i].cell = enemy_cells[i]
	var obstacles: Array[Vector2i] = [
		Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 5),
		Vector2i(4, 2), Vector2i(4, 3),
		Vector2i(8, 8), Vector2i(9, 8),
		Vector2i(2, 4), Vector2i(7, 10), Vector2i(11, 6),
	]
	return {"width": 12, "height": 12, "units": heroes + enemies, "obstacles": obstacles,
		"title": "Пролог, бой 3: колонна у ворот рудника"}
