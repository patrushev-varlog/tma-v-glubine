class_name Content
extends RefCounted
## Классы героя, спутники, враги, способности и сценарий боя.
## Цифры — урезанный SRD 5.2 для героев 2 уровня; уточняются на тестах.
## Дальности сжаты под поле боя: лук и большинство заклинаний 8 клеток, снаряд и стрела 10.

const SPELL_DC := 13
const SPELL_ATTACK := 5

const ABILITIES := {
	"second_wind": {"name": "Второе дыхание", "cost": "bonus", "resource": "use", "target": "self", "range": 0,
		"desc": "Лечит себя на 1d10+2."},
	"disengage": {"name": "Отход", "cost": "bonus", "resource": "none", "target": "self", "range": 0,
		"desc": "До конца хода уход от врагов не провоцирует атаки."},
	"sacred_flame": {"name": "Священное пламя", "cost": "action", "resource": "none", "target": "enemy", "range": 8,
		"desc": "Спасбросок Ловкости, 1d8 урона светом."},
	"healing_word": {"name": "Слово исцеления", "cost": "bonus", "resource": "slot", "target": "ally", "range": 8,
		"desc": "Лечит союзника на 1d4+3, поднимает выбывшего."},
	"fire_bolt": {"name": "Огненный снаряд", "cost": "action", "resource": "none", "target": "enemy", "range": 10,
		"desc": "Атака заклинанием, 1d10 огнём."},
	"magic_missile": {"name": "Волшебная стрела", "cost": "action", "resource": "slot", "target": "enemy", "range": 10,
		"desc": "Без промаха: 3d4+3 силовым полем."},
	"thunderwave": {"name": "Громовая волна", "cost": "action", "resource": "slot", "target": "self", "range": 0, "radius": 1,
		"desc": "Все вокруг: спасбросок Телосложения, 2d8 звуком, половина при успехе. Задевает и своих."},
	"hallowed_ground": {"name": "Освящённая земля", "cost": "action", "resource": "slot", "target": "cell", "range": 8, "radius": 1,
		"desc": "Зона 3×3: союзники лечатся на 1d6, нежить получает 2d6 светом."},
	"shield_of_faith": {"name": "Щит веры", "cost": "bonus", "resource": "slot", "target": "ally", "range": 8,
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
	"wither": {"name": "Иссушение", "cost": "action", "resource": "none", "target": "enemy", "range": 8, "dark": true,
		"desc": "Тёмный дар. Спасбросок Телосложения, 2d8 некротикой; столько же лечит самого раненого союзника."},
	"life_drain": {"name": "Высасывание жизни", "cost": "action", "resource": "none", "target": "enemy", "range": 8, "dark": true,
		"desc": "Тёмный дар. Атака заклинанием, 3d6 некротикой, лечит себя на половину."},
	# Базовые действия: есть у всех героев и спутников.
	"dodge": {"name": "Уклонение", "cost": "action", "resource": "none", "target": "self", "range": 0,
		"desc": "До начала следующего хода атаки по тебе с помехой."},
	"shove": {"name": "Толчок", "cost": "action", "resource": "none", "target": "enemy", "range": 1,
		"desc": "Спасбросок Силы или Ловкости врага: отлетает на клетку назад, а если некуда — падает. Можно столкнуть в ловушку или жир."},
	# Воин.
	"action_surge": {"name": "Всплеск действий", "cost": "free", "resource": "use", "target": "self", "range": 0,
		"desc": "Ещё одно действие в этот ход. Раз за бой."},
	# Плут: хитрое действие.
	"dash": {"name": "Рывок", "cost": "bonus", "resource": "none", "target": "self", "range": 0,
		"desc": "Хитрое действие: ещё столько же движения в этот ход."},
	"hide": {"name": "Спрятаться", "cost": "bonus", "resource": "none", "target": "self", "range": 0,
		"desc": "Хитрое действие, если рядом нет врагов. Вне их обзора — сразу, иначе проверка Ловкости против 15. Спрятавшийся бьёт с преимуществом и скрытой атакой."},
	"shoot": {"name": "Выстрел из лука", "cost": "action", "resource": "none", "target": "enemy", "range": 8,
		"desc": "Атака коротким луком, 1d6+3. Скрытая атака работает и издали."},
	# Жрец.
	"turn_undead": {"name": "Изгнание нежити", "cost": "action", "resource": "use", "target": "self", "range": 0, "radius": 3,
		"desc": "Нежить в 3 клетках: спасбросок Мудрости или бежит и не атакует, пока не получит урон."},
	"guiding_bolt": {"name": "Направляющий снаряд", "cost": "action", "resource": "slot", "target": "enemy", "range": 10,
		"desc": "Атака заклинанием, 4d6 светом; следующая атака по цели до твоего хода — с преимуществом."},
	# Волшебник.
	"ray_of_frost": {"name": "Луч холода", "cost": "action", "resource": "none", "target": "enemy", "range": 8,
		"desc": "Атака заклинанием, 1d8 холодом; цель теряет 2 клетки движения до твоего следующего хода."},
	"grease": {"name": "Жир", "cost": "action", "resource": "slot", "target": "cell", "range": 8, "radius": 1,
		"desc": "Зона 3×3 до конца боя: кто в ней или входит в неё — спасбросок Ловкости или падает и теряет движение. Задевает и своих."},
}

## Базовые действия, которые добавляются каждому герою и спутнику.
const BASIC_ACTIONS: Array[String] = ["dodge", "shove"]

## Пассивные приёмы: срабатывают сами, кнопок нет.
const TRAITS := {
	"cleave": {"name": "Рассечение", "desc": "Раз за ход при попадании в ближнем бою — удар по второму врагу рядом с целью, 1d8 без модификатора."},
	"hold_the_line": {"name": "Удержать проход", "desc": "Враг, по которому Гаррет попал атакой при возможности, останавливается."},
}

const HERO_CLASSES := {
	"fighter": {"name": "Воин", "max_hp": 20, "ac": 16, "init": 0,
		"saves": {"str": 5, "dex": 0, "con": 4, "wis": 1},
		"weapon": {"name": "Длинный меч", "to_hit": 5, "damage": "1d8+3", "reach": 1, "kind": "melee"},
		"abilities": ["second_wind", "action_surge", "cursed_blade"], "uses": {"second_wind": 1, "action_surge": 1},
		"traits": ["cleave"], "str_mod": 3},
	"rogue": {"name": "Плут", "max_hp": 15, "ac": 14, "init": 3,
		"saves": {"str": 0, "dex": 5, "con": 1, "wis": 1},
		"weapon": {"name": "Короткий меч", "to_hit": 5, "damage": "1d6+3", "reach": 1, "kind": "melee"},
		"ranged_weapon": {"name": "Короткий лук", "to_hit": 5, "damage": "1d6+3", "range": 8, "kind": "ranged"},
		"sneak": "1d6", "abilities": ["shoot", "disengage", "dash", "hide", "shadow_step"], "uses": {}, "str_mod": 0},
	"cleric": {"name": "Жрец", "max_hp": 17, "ac": 18, "init": 0,
		"saves": {"str": 1, "dex": 0, "con": 2, "wis": 5},
		"weapon": {"name": "Булава", "to_hit": 4, "damage": "1d6+2", "reach": 1, "kind": "melee"},
		"slots": 3, "abilities": ["sacred_flame", "guiding_bolt", "healing_word", "turn_undead", "wither"],
		"uses": {"turn_undead": 2}, "str_mod": 1},
	"wizard": {"name": "Волшебник", "max_hp": 12, "ac": 12, "init": 2,
		"saves": {"str": -1, "dex": 2, "con": 1, "wis": 3},
		"weapon": {"name": "Посох", "to_hit": 1, "damage": "1d6-1", "reach": 1, "kind": "melee"},
		"slots": 3, "abilities": ["fire_bolt", "ray_of_frost", "magic_missile", "thunderwave", "grease", "life_drain"],
		"uses": {}, "str_mod": -1},
}

const COMPANIONS := {
	"irena": {"name": "Ирена", "letter": "И", "color": "#e8d27a", "max_hp": 17, "ac": 16, "init": 0,
		"saves": {"str": 1, "dex": 0, "con": 2, "wis": 5},
		"weapon": {"name": "Булава", "to_hit": 4, "damage": "1d6+2", "reach": 1, "kind": "melee"},
		"slots": 3, "abilities": ["sacred_flame", "healing_word", "hallowed_ground", "shield_of_faith"], "uses": {},
		"str_mod": 1},
	"garret": {"name": "Гаррет", "letter": "Г", "color": "#c97b4a", "max_hp": 22, "ac": 17, "init": 0,
		"saves": {"str": 5, "dex": 0, "con": 4, "wis": 0},
		"weapon": {"name": "Длинный меч", "to_hit": 5, "damage": "1d8+3", "reach": 1, "kind": "melee"},
		"abilities": ["trip", "taunt"], "uses": {"trip": 2, "taunt": 2}, "traits": ["hold_the_line"], "str_mod": 3},
	"velior": {"name": "Велиор", "letter": "В", "color": "#6fb07a", "max_hp": 15, "ac": 14, "init": 3,
		"saves": {"str": 0, "dex": 5, "con": 1, "wis": 1},
		"weapon": {"name": "Короткий меч", "to_hit": 5, "damage": "1d6+3", "reach": 1, "kind": "melee"},
		"sneak": "1d6", "abilities": ["bomb", "trap"], "uses": {"bomb": 2, "trap": 2}, "str_mod": 0},
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
		"weapon": {"name": "Короткий лук", "to_hit": 4, "damage": "1d6+2", "range": 8, "kind": "ranged"}},
}

const HERO_COLOR := "#7aa7e8"


static func make_hero(class_id: String) -> Combatant:
	var t: Dictionary = HERO_CLASSES[class_id]
	var c := _from_template(t, "hero", class_id)
	_add_basic_actions(c)
	c.name = "Герой (%s)" % t.name
	c.letter = "Я"
	c.color = Color.html(HERO_COLOR)
	c.is_hero = true
	return c


static func make_companion(comp_id: String) -> Combatant:
	var t: Dictionary = COMPANIONS[comp_id]
	var c := _from_template(t, comp_id, comp_id)
	_add_basic_actions(c)
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
	c.ranged_weapon = t.get("ranged_weapon", {}).duplicate()
	for tr in t.get("traits", []):
		c.traits.append(String(tr))
	c.str_mod = t.get("str_mod", 0)
	return c


static func _add_basic_actions(c: Combatant) -> void:
	for a in BASIC_ACTIONS:
		c.abilities.append(a)


## Бой 3 пролога: колонна пленных на привале у ворот рудника.
## Карта: # — стена или телега, h — места отряда, C — старший надсмотрщик, o — надсмотрщик,
## z — зомби, a — скелет-лучник. Заглавные O и A есть только на «Испытании».
## Рудник справа за стеной, ворота в два прохода; низкие стены делят поле на коридоры.
const COLUMN_MAP: Array[String] = [
	"..........z.#.....",
	"......##....#..#..",
	"............#..a..",
	"...#.#...o..#.....",
	".....#......#.....",
	".....#.......#....",
	"hh...........C....",
	"hh..........#..#..",
	".....#......#..A..",
	".....#...O..#.....",
	"...#.#......#.....",
	"............#.....",
	"......##....#..#..",
	"..........z.#.....",
]

const MAP_ENEMIES := {"C": "overseer_chief", "o": "overseer", "O": "overseer", "z": "zombie",
	"a": "skeleton_archer", "A": "skeleton_archer"}


static func scenario_column(hero_class: String, with_velior: bool, diff := "trial") -> Dictionary:
	var heroes: Array[Combatant] = [make_hero(hero_class), make_companion("irena"), make_companion("garret")]
	if with_velior:
		heroes.append(make_companion("velior"))
	var hero_cells: Array[Vector2i] = []
	var enemies: Array[Combatant] = []
	var obstacles: Array[Vector2i] = []
	var counts := {}
	for y in COLUMN_MAP.size():
		var row: String = COLUMN_MAP[y]
		for x in row.length():
			var ch := row[x]
			var c := Vector2i(x, y)
			if ch == "#":
				obstacles.append(c)
			elif ch == "h":
				hero_cells.append(c)
			elif MAP_ENEMIES.has(ch):
				if diff == "story" and ch == ch.to_upper() and ch != "C":
					continue
				var kind: String = MAP_ENEMIES[ch]
				counts[kind] = int(counts.get(kind, 0)) + 1
				var e := make_enemy(kind, counts[kind])
				e.cell = c
				enemies.append(e)
	for i in heroes.size():
		heroes[i].cell = hero_cells[i]
	return {"width": COLUMN_MAP[0].length(), "height": COLUMN_MAP.size(), "units": heroes + enemies,
		"obstacles": obstacles, "title": "Пролог, бой 3: колонна у ворот рудника"}
