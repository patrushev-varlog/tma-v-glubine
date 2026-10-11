class_name Content
extends RefCounted
## Классы героя и их ветки, спутники, враги, способности и бои по уровням 1–5.
## Цифры — урезанный SRD 5.2; уточняются на тестах и симуляции.
## Дальности сжаты под поле боя: лук и большинство заклинаний 8 клеток, снаряд и стрела 10.

const MAX_LEVEL := 5

## dice — урон или лечение на 1 уровне. scale: "cantrip" — вдвое больше костей с 5 уровня,
## "dark" и "bomb" — +1 кость с 3 уровня и ещё +1 с 5-го.
## attack: true — способность заменяет одну атаку действия «Атака» (с дополнительной атакой можно ударить ещё раз).
## slot_cost — сколько ячеек тратит заклинание 3 круга.
const ABILITIES := {
	# --- Воин, 1 уровень.
	"second_wind": {"name": "Второе дыхание", "cost": "bonus", "resource": "use", "target": "self", "range": 0,
		"desc": "Лечит себя на 1d10 + уровень."},
	# --- Плут, 1 уровень.
	"disengage": {"name": "Отход", "cost": "bonus", "resource": "none", "target": "self", "range": 0,
		"desc": "До конца хода уход от врагов не провоцирует атаки."},
	# --- Жрец, 1 уровень.
	"sacred_flame": {"name": "Священное пламя", "cost": "action", "resource": "none", "target": "enemy", "range": 8,
		"dice": "1d8", "scale": "cantrip", "desc": "Спасбросок Ловкости, 1d8 светом (2d8 с 5 уровня)."},
	"healing_word": {"name": "Слово исцеления", "cost": "bonus", "resource": "slot", "target": "ally", "range": 8,
		"dice": "1d4+3", "desc": "Лечит союзника на 1d4+3, поднимает выбывшего."},
	# --- Волшебник, 1 уровень.
	"fire_bolt": {"name": "Огненный снаряд", "cost": "action", "resource": "none", "target": "enemy", "range": 10,
		"dice": "1d10", "scale": "cantrip", "desc": "Атака заклинанием, 1d10 огнём (2d10 с 5 уровня)."},
	"magic_missile": {"name": "Волшебная стрела", "cost": "action", "resource": "slot", "target": "enemy", "range": 10,
		"dice": "3d4+3", "desc": "Без промаха: 3d4+3 силовым полем."},
	"thunderwave": {"name": "Громовая волна", "cost": "action", "resource": "slot", "target": "self", "range": 0, "radius": 1,
		"dice": "2d8", "desc": "Все вокруг: спасбросок Телосложения, 2d8 звуком, половина при успехе. Задевает и своих."},
	# --- Спутники.
	"hallowed_ground": {"name": "Освящённая земля", "cost": "action", "resource": "slot", "target": "cell", "range": 8, "radius": 1,
		"desc": "Зона 3×3: союзники лечатся на 1d6, нежить получает 2d6 светом."},
	"shield_of_faith": {"name": "Щит веры", "cost": "bonus", "resource": "slot", "target": "ally", "range": 8,
		"desc": "+2 к КД союзника до конца боя."},
	"trip": {"name": "Сбить с ног", "cost": "action", "resource": "use", "target": "enemy", "range": 1, "attack": true,
		"desc": "Атака оружием; при попадании спасбросок Силы или враг падает."},
	"taunt": {"name": "Провокация", "cost": "bonus", "resource": "use", "target": "self", "range": 0, "radius": 3,
		"desc": "Враги в 3 клетках атакуют Гаррета в свой следующий ход."},
	"bomb": {"name": "Алхимическая бомба", "cost": "action", "resource": "use", "target": "cell", "range": 6, "radius": 1,
		"dice": "2d6", "scale": "bomb", "desc": "Зона 3×3: спасбросок Ловкости, 2d6 огнём (больше с 3 и 5 уровня), половина при успехе. Задевает и своих."},
	"trap": {"name": "Ловушка", "cost": "action", "resource": "use", "target": "empty_cell", "range": 3,
		"desc": "Скрытая ловушка: первый враг на клетке получает 2d6 и останавливается."},
	# --- Тёмные дары.
	"cursed_blade": {"name": "Проклятый клинок", "cost": "action", "resource": "none", "target": "enemy", "range": 1, "dark": true,
		"attack": true, "dice": "2d8", "scale": "dark5", "desc": "Тёмный дар. Атака оружием +2d8 некротикой (3d8 с 5 уровня), лечит на половину."},
	"shadow_step": {"name": "Шаг в тень", "cost": "bonus", "resource": "none", "target": "self", "range": 0, "dark": true,
		"dice": "2d4", "scale": "dark5", "desc": "Тёмный дар. Преимущество на следующую атаку, +2d4 некротикой при попадании (3d4 с 5 уровня) и лечение на половину, уход без атак при возможности."},
	"wither": {"name": "Иссушение", "cost": "action", "resource": "none", "target": "enemy", "range": 8, "dark": true,
		"dice": "2d8", "scale": "dark5", "desc": "Тёмный дар. Спасбросок Телосложения, 2d8 некротикой (3d8 с 5 уровня), половина при успехе; половину нанесённого получает самый раненый союзник."},
	"life_drain": {"name": "Высасывание жизни", "cost": "action", "resource": "none", "target": "enemy", "range": 8, "dark": true,
		"dice": "5d8", "scale": "dark", "desc": "Тёмный дар. Атака заклинанием, 5d8 некротикой (больше с 3 и 5 уровня), лечит себя на половину."},
	# --- Базовые действия: есть у всех героев и спутников.
	"dodge": {"name": "Уклонение", "cost": "action", "resource": "none", "target": "self", "range": 0,
		"desc": "До начала следующего хода атаки по тебе с помехой."},
	"shove": {"name": "Толчок", "cost": "action", "resource": "none", "target": "enemy", "range": 1,
		"desc": "Спасбросок Силы или Ловкости врага: отлетает на клетку назад, а если некуда — падает. Можно столкнуть в ловушку или жир."},
	# --- Воин: Страж.
	"action_surge": {"name": "Всплеск действий", "cost": "free", "resource": "use", "target": "self", "range": 0,
		"desc": "Ещё одно действие в этот ход. Раз за бой."},
	# --- Воин: Берсерк.
	"rage": {"name": "Ярость", "cost": "bonus", "resource": "use", "target": "self", "range": 0,
		"desc": "До конца боя +1 к урону в ближнем бою, а урон от оружия по берсерку меньше на 2."},
	"reckless": {"name": "Безрассудная атака", "cost": "free", "resource": "none", "target": "self", "range": 0,
		"desc": "В этот ход атаки в ближнем бою с преимуществом, но и по тебе до твоего хода — с преимуществом."},
	# --- Плут: Убийца.
	"hide": {"name": "Спрятаться", "cost": "bonus", "resource": "none", "target": "self", "range": 0,
		"desc": "Если рядом нет врагов. Вне их обзора — сразу, иначе проверка Ловкости против 15. Спрятавшийся бьёт с преимуществом и скрытой атакой."},
	"poison_blade": {"name": "Яд на клинке", "cost": "bonus", "resource": "use", "target": "self", "range": 0,
		"desc": "Следующее попадание: +2d6 ядом, цель бьёт с помехой до конца своего хода."},
	# --- Плут: Ловкач.
	"shoot": {"name": "Выстрел из лука", "cost": "action", "resource": "none", "target": "enemy", "range": 8, "attack": true,
		"desc": "Атака коротким луком, 1d6+3. Скрытая атака работает и издали."},
	"dash": {"name": "Рывок", "cost": "bonus", "resource": "none", "target": "self", "range": 0,
		"desc": "Ещё столько же движения в этот ход."},
	"knife_fan": {"name": "Веер кинжалов", "cost": "action", "resource": "none", "target": "self", "range": 0, "radius": 4,
		"desc": "Метает кинжалы в трёх ближайших видимых врагов в 4 клетках: атака, 1d4+3 каждому, скрытая атака по первому."},
	# --- Жрец: Жизнь.
	"preserve_life": {"name": "Сохранение жизни", "cost": "action", "resource": "use", "target": "self", "range": 0, "radius": 6,
		"desc": "Распределяет 8 × уровень хитов между ранеными союзниками в 6 клетках, каждому не выше половины его хитов."},
	"mass_healing_word": {"name": "Массовое слово исцеления", "cost": "bonus", "resource": "slot", "slot_cost": 2, "target": "self",
		"range": 0, "radius": 6, "dice": "1d4+3", "desc": "Заклинание 3 круга (2 ячейки): все союзники в 6 клетках лечатся на 1d4+3, выбывшие встают."},
	# --- Жрец: Свет.
	"guiding_bolt": {"name": "Направляющий снаряд", "cost": "action", "resource": "slot", "target": "enemy", "range": 10,
		"dice": "3d6", "desc": "Атака заклинанием, 3d6 светом; следующая атака по цели до твоего хода — с преимуществом."},
	"turn_undead": {"name": "Изгнание нежити", "cost": "action", "resource": "use", "target": "self", "range": 0, "radius": 2,
		"desc": "Раз за бой. Нежить в 2 клетках: спасбросок Мудрости или бежит и не атакует, пока не получит урон."},
	"spiritual_weapon": {"name": "Духовное оружие", "cost": "bonus", "resource": "none", "target": "enemy", "range": 6,
		"dice": "1d6", "desc": "Первый раз — ячейка: призывает парящее оружие до конца боя. Каждый ход бонусом бьёт врага в 6 клетках: атака заклинанием, 1d6."},
	"spirit_guardians": {"name": "Духовные стражи", "cost": "action", "resource": "slot", "slot_cost": 2, "target": "self",
		"range": 0, "radius": 2, "dice": "2d8", "desc": "Заклинание 3 круга (2 ячейки): до конца боя враг, начинающий ход в 2 клетках от жреца, — спасбросок Мудрости, 2d8 светом, половина при успехе."},
	# --- Волшебник: Воплотитель.
	"scorching_ray": {"name": "Палящий луч", "cost": "action", "resource": "slot", "target": "enemy", "range": 8,
		"dice": "2d6", "desc": "Три луча, каждый — атака заклинанием на 2d6 огнём. Если цель падает, оставшиеся лучи летят в ближайшего врага."},
	"fireball": {"name": "Огненный шар", "cost": "action", "resource": "use", "target": "cell", "range": 10, "radius": 1,
		"dice": "7d6", "desc": "Заклинание 3 круга, раз за бой: зона 3×3, спасбросок Ловкости, 7d6 огнём, половина при успехе. Задевает и своих, если нет «Аккуратного воплощения»."},
	# --- Волшебник: Сковыватель.
	"grease": {"name": "Жир", "cost": "action", "resource": "slot", "target": "cell", "range": 8, "radius": 1,
		"desc": "Зона 3×3 до конца боя: кто в ней или входит в неё — спасбросок Ловкости или падает и теряет движение. Задевает и своих."},
	"web": {"name": "Паутина", "cost": "action", "resource": "slot", "target": "cell", "range": 8, "radius": 1,
		"desc": "Зона 3×3 до конца боя: кто в ней — спасбросок Ловкости или опутан: не ходит, бьёт с помехой, по нему с преимуществом. В начале хода — Сила, чтобы вырваться."},
	"spike_growth": {"name": "Каменные шипы", "cost": "action", "resource": "slot", "target": "cell", "range": 8, "radius": 2,
		"dice": "2d4", "desc": "Зона 5×5 до конца боя: каждый шаг по ней — 2d4 колющего урона. Задевает и своих, если пойдут через неё."},
	"slow": {"name": "Замедление", "cost": "action", "resource": "slot", "target": "cell", "range": 12, "radius": 3,
		"desc": "Заклинание 3 круга: враги в зоне 7×7 — спасбросок Мудрости или −2 КД, половина движения, одна атака за ход и без атак при возможности. Спасбросок в конце каждого их хода."},
}

## Базовые действия, которые добавляются каждому герою и спутнику.
const BASIC_ACTIONS: Array[String] = ["dodge", "shove"]

## Пассивные приёмы: срабатывают сами, кнопок нет.
const TRAITS := {
	"protector": {"name": "Защитник", "desc": "Союзники рядом со Стражем получают +2 к КД."},
	"hold_the_line": {"name": "Удержать проход", "desc": "Враг, по которому попала атака при возможности, останавливается."},
	"stalwart": {"name": "Стойкость", "desc": "Урон от оружия по Стражу меньше на 3."},
	"cleave": {"name": "Рассечение", "desc": "Раз за ход при попадании в ближнем бою — такой же удар по второму врагу рядом с целью."},
	"relentless": {"name": "Неудержимый", "desc": "Раз за бой в ярости при 0 хитов остаётся с 1 хитом."},
	"assassinate": {"name": "Убийство", "desc": "В первом раунде атаки по врагам, ещё не ходившим, с преимуществом и + уровень к урону."},
	"finisher": {"name": "Добивание", "desc": "Скрытая атака по врагу с половиной хитов или меньше — двойные кости."},
	"uncanny_dodge": {"name": "Уворот", "desc": "Первое попадание оружием по тебе между твоими ходами — вдвое меньше урона."},
	"life_disciple": {"name": "Ученик жизни", "desc": "Лечащие заклинания восстанавливают на 3 хита больше."},
	"sculpt": {"name": "Аккуратное воплощение", "desc": "Громовая волна и огненный шар не задевают своих."},
	"empowered": {"name": "Усиленный заговор", "desc": "+3 к урону огненного снаряда."},
	"extra_attack": {"name": "Дополнительная атака", "desc": "Действие «Атака» — два удара."},
}

## Классы героя. Хиты: hp на 1 уровне + hp_per_level за каждый следующий.
## Ветка выбирается на 2 уровне; levels — что она даёт на 2–5 уровнях (умение или пассивный приём).
## Оружие: бонус атаки = мастерство + mod (по умолчанию 3), урон + mod.
const HERO_CLASSES := {
	"fighter": {"name": "Воин", "hp": 13, "hp_per_level": 3, "ac": 15, "init": 0,
		"saves": {"str": 5, "dex": 0, "con": 4, "wis": 1}, "str_mod": 2,
		"weapon": {"name": "Длинный меч", "damage": "1d8", "reach": 1, "kind": "melee"},
		"abilities": ["second_wind", "cursed_blade"], "uses": {"second_wind": 1},
		"archetypes": {
			"guardian": {"name": "Страж", "desc": "Щит и строй: держит врагов на себе и прикрывает соседей.",
				"ac": 16, "levels": {2: "action_surge", 3: "protector", 4: "hold_the_line", 5: "stalwart"}},
			"berserker": {"name": "Берсерк", "desc": "Двуручник и ярость: много урона, мало защиты.",
				"ac": 13, "weapon": {"name": "Двуручный меч", "damage": "2d6", "reach": 1, "kind": "melee"},
				"levels": {2: "rage", 3: "cleave", 4: "reckless", 5: "relentless"}},
		}},
	"rogue": {"name": "Плут", "hp": 14, "hp_per_level": 4, "ac": 15, "init": 3,
		"saves": {"str": 0, "dex": 5, "con": 1, "wis": 1}, "str_mod": 0,
		"weapon": {"name": "Короткий меч", "damage": "1d6", "reach": 1, "kind": "melee"},
		"abilities": ["disengage", "shadow_step"], "uses": {},
		"archetypes": {
			"assassin": {"name": "Убийца", "desc": "Прятки, яд и смертельный первый удар.",
				"levels": {2: "hide", 3: "poison_blade", 4: "finisher", 5: "assassinate"}},
			"trickster": {"name": "Ловкач", "desc": "Лук, скорость и кинжалы по нескольким целям.", "ac": 13,
				"ranged_weapon": {"name": "Короткий лук", "damage": "1d6", "range": 8, "kind": "ranged"},
				"levels": {2: "shoot", 3: "uncanny_dodge", 4: "dash", 5: "knife_fan"}},
		}},
	"cleric": {"name": "Жрец", "hp": 9, "hp_per_level": 5, "ac": 15, "init": 0,
		"saves": {"str": 1, "dex": 0, "con": 2, "wis": 5}, "str_mod": 1, "caster": true,
		"weapon": {"name": "Булава", "damage": "1d6", "reach": 1, "kind": "melee", "mod": 2},
		"abilities": ["sacred_flame", "healing_word", "wither"], "uses": {},
		"archetypes": {
			"life": {"name": "Жизнь", "desc": "Лечит весь отряд и держит его на ногах.",
				"levels": {2: "life_disciple", 3: "shield_of_faith", 4: "mass_healing_word", 5: "preserve_life"}},
			"light": {"name": "Свет", "desc": "Жжёт нежить и бьёт духовным оружием.",
				"levels": {2: "guiding_bolt", 3: "turn_undead", 4: "spiritual_weapon", 5: "spirit_guardians"}},
		}},
	"wizard": {"name": "Волшебник", "hp": 8, "hp_per_level": 4, "ac": 12, "init": 2,
		"saves": {"str": -1, "dex": 2, "con": 1, "wis": 3}, "str_mod": -1, "caster": true,
		"weapon": {"name": "Посох", "damage": "1d6", "reach": 1, "kind": "melee", "mod": -1, "no_prof": true},
		"abilities": ["fire_bolt", "magic_missile", "thunderwave", "life_drain"], "uses": {},
		"archetypes": {
			"evoker": {"name": "Воплотитель", "desc": "Чистый урон: лучи, огненный шар, свои не страдают.",
				"levels": {2: "sculpt", 3: "scorching_ray", 4: "empowered", 5: "fireball"}},
			"binder": {"name": "Сковыватель", "desc": "Контроль поля: жир, шипы, паутина, замедление.",
				"levels": {2: "grease", 3: "spike_growth", 4: "web", 5: "slow"}},
		}},
}

## Ячейки заклинаний на бой по уровням (у жреца, волшебника и Ирены).
const SLOTS_BY_LEVEL := [0, 2, 3, 4, 5, 6]

const COMPANIONS := {
	"irena": {"name": "Ирена", "letter": "И", "color": "#e8d27a", "hp": 10, "hp_per_level": 7, "ac": 16, "init": 0,
		"saves": {"str": 1, "dex": 0, "con": 2, "wis": 5}, "str_mod": 1, "caster": true,
		"weapon": {"name": "Булава", "damage": "1d6", "reach": 1, "kind": "melee", "mod": 2},
		"abilities": ["sacred_flame", "healing_word", "hallowed_ground", "shield_of_faith"], "uses": {}},
	"garret": {"name": "Гаррет", "letter": "Г", "color": "#c97b4a", "hp": 14, "hp_per_level": 8, "ac": 17, "init": 0,
		"saves": {"str": 5, "dex": 0, "con": 4, "wis": 0}, "str_mod": 3, "extra_attack_at": 5,
		"weapon": {"name": "Длинный меч", "damage": "1d8", "reach": 1, "kind": "melee"},
		"abilities": ["trip", "taunt"], "uses": {"trip": 2, "taunt": 2}, "uses_growth": true, "traits": ["hold_the_line"]},
	"velior": {"name": "Велиор", "letter": "В", "color": "#6fb07a", "hp": 10, "hp_per_level": 5, "ac": 14, "init": 3,
		"saves": {"str": 0, "dex": 5, "con": 1, "wis": 1}, "str_mod": 0,
		"weapon": {"name": "Короткий меч", "damage": "1d6", "reach": 1, "kind": "melee"},
		"sneak": true, "abilities": ["bomb", "trap"], "uses": {"bomb": 2, "trap": 2}, "uses_growth": true},
}

## Враги. attacks — сколько ударов за действие. on_hit: "paralyze" — спасбросок Телосложения СЛ 10
## или пропускает следующий ход (на нежить не действует).
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
	"skeleton": {"name": "Скелет", "letter": "к", "max_hp": 13, "ac": 14, "init": 2, "speed": 6, "undead": true,
		"saves": {"str": 0, "dex": 2, "con": 2, "wis": -1},
		"weapon": {"name": "Короткий меч", "to_hit": 4, "damage": "1d6+2", "reach": 1, "kind": "melee"}},
	"drowned": {"name": "Утопленник", "letter": "у", "max_hp": 22, "ac": 10, "init": -1, "speed": 5, "undead": true,
		"saves": {"str": 2, "dex": -1, "con": 3, "wis": 0},
		"weapon": {"name": "Хватка", "to_hit": 4, "damage": "1d8+2", "reach": 1, "kind": "melee"}},
	"ghoul": {"name": "Гуль", "letter": "г", "max_hp": 22, "ac": 12, "init": 2, "speed": 6, "undead": true,
		"saves": {"str": 1, "dex": 2, "con": 0, "wis": 0},
		"weapon": {"name": "Когти", "to_hit": 4, "damage": "2d4+2", "reach": 1, "kind": "melee", "on_hit": "paralyze"}},
	"acolyte": {"name": "Послушник некроманта", "letter": "п", "max_hp": 18, "ac": 12, "init": 1, "speed": 6,
		"saves": {"str": 0, "dex": 1, "con": 1, "wis": 3},
		"weapon": {"name": "Луч болезни", "to_hit": 5, "damage": "2d8", "range": 8, "kind": "ranged"}},
	"dwarf_dead": {"name": "Мёртвый дварф", "letter": "д", "max_hp": 30, "ac": 16, "init": 0, "speed": 5, "undead": true,
		"saves": {"str": 3, "dex": 0, "con": 3, "wis": 1},
		"weapon": {"name": "Боевой молот", "to_hit": 5, "damage": "1d8+3", "reach": 1, "kind": "melee"}},
	"wight": {"name": "Умертвие", "letter": "У", "max_hp": 45, "ac": 14, "init": 2, "speed": 6, "undead": true, "attacks": 2,
		"saves": {"str": 2, "dex": 2, "con": 3, "wis": 1},
		"weapon": {"name": "Длинный меч", "to_hit": 5, "damage": "1d8+2", "reach": 1, "kind": "melee"}},
	"bone_archer": {"name": "Костяной стрелок", "letter": "л", "max_hp": 22, "ac": 14, "init": 3, "speed": 6, "undead": true,
		"saves": {"str": 0, "dex": 3, "con": 2, "wis": 0},
		"weapon": {"name": "Длинный лук", "to_hit": 5, "damage": "1d8+3", "range": 10, "kind": "ranged"}},
	"ogre_zombie": {"name": "Зомби-огр", "letter": "О", "max_hp": 60, "ac": 8, "init": -2, "speed": 5, "undead": true,
		"saves": {"str": 4, "dex": -2, "con": 4, "wis": -2},
		"weapon": {"name": "Дубина", "to_hit": 6, "damage": "2d8+4", "reach": 1, "kind": "melee"}},
	"flesh_golem": {"name": "Мясной голем", "letter": "М", "max_hp": 95, "ac": 10, "init": -1, "speed": 5, "attacks": 2,
		"saves": {"str": 4, "dex": -1, "con": 4, "wis": 0},
		"weapon": {"name": "Кулак", "to_hit": 7, "damage": "2d8+4", "reach": 1, "kind": "melee"}},
}

const HERO_COLOR := "#7aa7e8"

## Для настройки баланса из tools/simulate.gd: буквы врагов, которых убрать из боя.
static var exclude: Array = []
## Для настройки баланса: усиление врагов вместо записанного в бою ("boost").
static var boost_override := {}


static func prof(level: int) -> int:
	return 3 if level >= 5 else 2


## Урон способности с учётом уровня того, кто её применяет.
static func ability_dice(aid: String, level: int) -> String:
	var a: Dictionary = ABILITIES[aid]
	var expr: String = a.get("dice", "")
	if expr == "":
		return expr
	var d := Dice.parse(expr)
	var count: int = d.count
	match String(a.get("scale", "")):
		"cantrip":
			if level >= 5:
				count *= 2
		"dark5":
			if level >= 5:
				count += 1
		"dark", "bomb":
			if level >= 3:
				count += 1
			if level >= 5:
				count += 1
	return _expr(count, d.sides, d.bonus)


static func _expr(count: int, sides: int, bonus: int) -> String:
	var out := "%dd%d" % [count, sides]
	if bonus > 0:
		out += "+%d" % bonus
	elif bonus < 0:
		out += "%d" % bonus
	return out


static func sneak_for(level: int) -> String:
	return "%dd6" % ((level + 1) / 2)


## Ветки класса: [id, …] в порядке объявления.
static func archetypes_of(class_id: String) -> Array:
	return HERO_CLASSES[class_id].archetypes.keys()


static func make_hero(class_id: String, level := 2, archetype := "") -> Combatant:
	var t: Dictionary = HERO_CLASSES[class_id]
	if archetype == "":
		archetype = archetypes_of(class_id)[0]
	var arch: Dictionary = t.archetypes[archetype] if level >= 2 else {}
	var c := _from_template(t, "hero", class_id, level)
	c.archetype = archetype if level >= 2 else ""
	if arch.has("ac"):
		c.ac = arch.ac
	if arch.has("weapon"):
		c.weapon = _weapon(arch.weapon, level)
	if arch.has("ranged_weapon"):
		c.ranged_weapon = _weapon(arch.ranged_weapon, level)
	for lv in range(2, level + 1):
		var gain: String = arch.levels[lv]
		if TRAITS.has(gain):
			c.traits.append(gain)
		else:
			# Новые умения встают перед тёмным даром, чтобы он оставался последней кнопкой класса.
			c.abilities.insert(c.abilities.size() - 1, gain)
	if class_id == "rogue":
		c.sneak_dice = sneak_for(level)
	for aid in ["action_surge", "rage", "preserve_life", "fireball"]:
		if c.abilities.has(aid):
			c.uses[aid] = 1
	if c.abilities.has("poison_blade"):
		c.uses["poison_blade"] = 3
	if class_id == "cleric" and level >= 4:
		# Жрец-герой лечит лучше всех в отряде, поэтому на старших уровнях у него меньше ячеек.
		c.slots -= 1 if level == 4 else 2
		c.max_slots = c.slots
	if c.abilities.has("turn_undead"):
		c.uses["turn_undead"] = 1
	_finish(c)
	c.name = "Герой (%s%s)" % [t.name, "" if c.archetype == "" else ", " + String(arch.name)]
	c.letter = "Я"
	c.color = Color.html(HERO_COLOR)
	c.is_hero = true
	return c


static func make_companion(comp_id: String, level := 2) -> Combatant:
	var t: Dictionary = COMPANIONS[comp_id]
	var c := _from_template(t, comp_id, comp_id, level)
	if t.get("uses_growth", false):
		var bonus := (1 if level >= 3 else 0) + (1 if level >= 5 else 0)
		for k in c.uses:
			c.uses[k] = int(c.uses[k]) + bonus
	if t.get("sneak", false):
		c.sneak_dice = sneak_for(level)
	if level >= int(t.get("extra_attack_at", 99)):
		c.traits.append("extra_attack")
	_finish(c)
	c.name = t.name
	c.letter = t.letter
	c.color = Color.html(t.color)
	c.is_companion = true
	return c


static func make_enemy(kind: String, idx: int) -> Combatant:
	var t: Dictionary = ENEMIES[kind]
	var c := Combatant.new()
	c.id = "%s_%d" % [kind, idx]
	c.kind = kind
	c.max_hp = t.max_hp
	c.hp = t.max_hp
	c.ac = t.ac
	c.speed = t.get("speed", 6)
	c.init_mod = t.get("init", 0)
	c.saves = t.saves.duplicate()
	c.weapon = t.weapon.duplicate()
	c.attacks_per_action = t.get("attacks", 1)
	c.name = t.name
	c.letter = t.letter
	c.team = 1
	c.undead = t.get("undead", false)
	c.color = Color.html("#b9505a") if not c.undead else Color.html("#a596d6")
	return c


## Оружие героя или спутника: бонус атаки = мастерство + mod, урон + mod.
static func _weapon(w: Dictionary, level: int) -> Dictionary:
	var out := w.duplicate()
	var mod: int = w.get("mod", 3)
	var p := 0 if w.get("no_prof", false) else prof(level)
	out["to_hit"] = mod + p
	var d := Dice.parse(String(w.damage))
	out["damage"] = _expr(d.count, d.sides, mod)
	out["dice"] = _expr(d.count, d.sides, 0)
	return out


static func _from_template(t: Dictionary, id: String, kind: String, level: int) -> Combatant:
	var c := Combatant.new()
	c.id = id
	c.kind = kind
	c.level = level
	c.max_hp = int(t.hp) + int(t.hp_per_level) * (level - 1)
	c.hp = c.max_hp
	c.ac = t.ac
	c.speed = t.get("speed", 6)
	c.init_mod = t.get("init", 0)
	c.saves = t.saves.duplicate()
	# На 5 уровне мастерство растёт: +1 к спасброскам.
	if level >= 5:
		for k in c.saves:
			c.saves[k] = int(c.saves[k]) + 1
	c.weapon = _weapon(t.weapon, level)
	for a in t.get("abilities", []):
		c.abilities.append(String(a))
	c.uses = t.get("uses", {}).duplicate()
	if t.get("caster", false):
		c.slots = SLOTS_BY_LEVEL[level]
	c.max_slots = c.slots
	c.spell_attack = 3 + prof(level)
	c.spell_dc = 11 + prof(level)
	for tr in t.get("traits", []):
		c.traits.append(String(tr))
	c.str_mod = t.get("str_mod", 0)
	return c


static func _finish(c: Combatant) -> void:
	if c.traits.has("extra_attack"):
		c.attacks_per_action = 2
	for a in BASIC_ACTIONS:
		c.abilities.append(a)


# --- Бои по уровням ---------------------------------------------------------

## Карты 18×14: # — стена или телега, h — места отряда, буквы — враги (легенда у боя).
## Враги из списка trial_only есть только на «Испытании».
## boost — усиление врагов под гарантированный набор экипировки отряда (см. Items.KITS): hp — проценты к хитам.
const BATTLES := {
	1: {"title": "Пролог, бой 3: колонна у ворот рудника", "intro": "Надсмотрщики и первые мертвецы у ворот рудника.",
		"legend": {"C": "overseer_chief", "o": "overseer", "O": "overseer", "z": "zombie", "Z": "zombie",
			"a": "skeleton_archer", "A": "skeleton_archer"},
		"trial_only": ["O", "Z", "A"],
		"map": [
			"..........z.#.....",
			"......##....#..#..",
			"............#..a..",
			"...#.#...o..#.....",
			".....#......#.....",
			".....#.......#....",
			"hh...........C....",
			"hh..........#..#..",
			".....#......#.....",
			".....#...O..#.....",
			"...#.#......#.....",
			"............#.....",
			"......##....#..#..",
			"..........Z.#.....",
		]},
	2: {"title": "Глава 1: Верхние шахты", "intro": "Штольня у подъёмника: скелеты-лучники на мостках, мертвецы и надсмотрщики.",
		"legend": {"C": "overseer_chief", "o": "overseer", "O": "overseer", "z": "zombie", "Z": "zombie",
			"a": "skeleton_archer", "A": "skeleton_archer", "k": "skeleton", "K": "skeleton"},
		"trial_only": ["O", "Z", "A", "K"],
		"map": [
			"...........z..#...",
			"..##......#...#.a.",
			"..........#.......",
			".....##.......k...",
			"..........##......",
			"....#.......o..#..",
			"hh..#........C.#..",
			"hh..#..........#..",
			"....#..........#..",
			"..........##......",
			".....##...........",
			"..........#.......",
			"..##......#...#.A.",
			"...........Z..#...",
		]},
	3: {"title": "Глава 2: Затопленные выработки", "boost": {"hp": 12},
		"intro": "Тёмная вода, утопленники и гули; послушник некроманта бьёт издали.",
		"legend": {"u": "drowned", "U": "drowned", "g": "ghoul", "G": "ghoul", "p": "acolyte", "a": "skeleton_archer",
			"A": "skeleton_archer"},
		"trial_only": ["U", "G", "A"],
		"map": [
			"........#.....#...",
			"..##....#..u..#.a.",
			"..##..........#...",
			"...........##.....",
			".....#.....##..g..",
			".....#............",
			"hh...........p....",
			"hh................",
			".....#............",
			".....#.....##..G..",
			"...........##.....",
			"..##..........#...",
			"..##....#..U..#.A.",
			"........#.....#...",
		]},
	4: {"title": "Глава 3: Дварфийские залы", "boost": {"hp": 25},
		"intro": "Мёртвые дварфы в доспехах, умертвие и костяные стрелки на галерее.",
		"legend": {"d": "dwarf_dead", "S": "skeleton", "W": "wight", "l": "bone_archer", "g": "ghoul", "G": "ghoul"},
		"trial_only": ["G", "S"],
		"map": [
			"....#........#....",
			"....#...d....#..l.",
			"..........#.......",
			"..#.......#....g..",
			"......#...........",
			"......#.......#...",
			"hh.........W..#...",
			"hh............#...",
			"......#...........",
			"......#.......G...",
			"..#.......#.......",
			"..........#.......",
			"....#...S....#....",
			"....#........#....",
		]},
	5: {"title": "Глава 4: Кузницы плоти", "boost": {"hp": 40},
		"intro": "Мясной голем у горна, умертвие, послушник и гули.",
		"legend": {"M": "flesh_golem", "W": "wight", "p": "acolyte", "g": "ghoul", "G": "ghoul"},
		"trial_only": ["G"],
		"map": [
			".......#......#...",
			".......#....p.#...",
			"..##..............",
			"..##.......g...#..",
			"...........#...#..",
			"......#....#......",
			"hh....#.......M...",
			"hh....#...W.......",
			"......#....#......",
			"...........#...#..",
			"..##.......G...#..",
			"..##..............",
			".......#......#...",
			".......#......#...",
		]},
}


## Бой своего уровня: отряд героя того же уровня против врагов боя.
static func scenario(level: int, hero_class: String, archetype: String, with_velior: bool, diff := "trial") -> Dictionary:
	var bt: Dictionary = BATTLES[level]
	var heroes: Array[Combatant] = [make_hero(hero_class, level, archetype), make_companion("irena", level),
		make_companion("garret", level)]
	if with_velior:
		heroes.append(make_companion("velior", level))
	var hero_cells: Array[Vector2i] = []
	var enemies: Array[Combatant] = []
	var obstacles: Array[Vector2i] = []
	var counts := {}
	var rows: Array = bt.map
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var c := Vector2i(x, y)
			if ch == "#":
				obstacles.append(c)
			elif ch == "h":
				hero_cells.append(c)
			elif bt.legend.has(ch):
				if diff == "story" and bt.trial_only.has(ch) or exclude.has(ch):
					continue
				var kind: String = bt.legend[ch]
				counts[kind] = int(counts.get(kind, 0)) + 1
				var e := make_enemy(kind, counts[kind])
				_boost_enemy(e, boost_override if not boost_override.is_empty() else bt.get("boost", {}))
				e.cell = c
				enemies.append(e)
	for i in heroes.size():
		heroes[i].cell = hero_cells[i]
		if Items.mode != "none":
			Items.equip(heroes[i], Items.kit_for(heroes[i], level))
	return {"width": String(rows[0]).length(), "height": rows.size(), "units": heroes + enemies,
		"obstacles": obstacles, "title": "%s (уровень %d)" % [bt.title, level], "level": level}


## Усиление врагов боя под гарантированный набор экипировки отряда:
## hp — проценты к хитам, hit — к попаданию, dmg — к урону, ac — к КД.
static func _boost_enemy(e: Combatant, boost: Dictionary) -> void:
	if boost.is_empty():
		return
	e.max_hp = int(round(e.max_hp * (1.0 + float(boost.get("hp", 0)) / 100.0)))
	e.hp = e.max_hp
	e.ac += int(boost.get("ac", 0))
	var hit := int(boost.get("hit", 0))
	var dmg := int(boost.get("dmg", 0))
	if hit != 0 or dmg != 0:
		e.weapon = Items._boost(e.weapon, hit, dmg)
