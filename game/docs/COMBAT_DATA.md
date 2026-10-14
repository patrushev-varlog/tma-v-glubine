# Данные боя

Правила боя живут в `data/combat/*.json`, а `scripts/combat/battle.gd` — один исполнитель на всех:
героев, спутников и врагов (B7 плана, `review/06-improvement-plan.md`). Новое умение или состояние
добавляется записью в JSON и строкой перевода в `i18n/combat.csv`, без нового кода, пока хватает
операций ниже. На каждое умение и каждый приём есть тест (`tests/unit/test_abilities.gd`,
`tests/unit/test_traits.gd`); мета-тесты падают, если запись появилась без теста или без перевода.

Числа из JSON при загрузке приводятся к целым (`CombatData.whole_numbers`), поэтому `2` и `2.0`
одинаковы. Строка вида `"$имя"` в эффекте берётся из параметров умения (`params`, `radius`, `dice`
и правки приёмов через `ability_params`).

| Файл | Что в нём |
| --- | --- |
| `rules.json` | Общие числа: потолок боевой Тьмы `combat_dark_cap`, составы отряда `parties`, сложности. |
| `classes.json` | Классы героя: хиты, КД, спасброски, оружие, умения 1 уровня, две ветки и что они дают на 2–5 уровнях. |
| `companions.json` | Ирена, Гаррет, Велиор по уровням. |
| `enemies.json` | Враги: xp (по нему урезается состав под неполный отряд), boss, оружие, `weapon.on_hit`, умения и приёмы. |
| `battles.json` | Тестовые бои уровней 1–5 из прототипа, бои пролога (`prologue_*`) и главы 1 (`chapter1_*`, `ch1_hunt_foreman`) главы 2 (`chapter2_*`, `ch2_hunt_priest`) и главы 3 (`chapter3_*`): карта, legend, `trial_only`, `boost`, правила сюжетного боя (ниже). |
| `items.json` | Боевые свойства предметов (`fx`) и именные правила (`trait`). |
| `abilities.json` | Умения. |
| `statuses.json` | Состояния. |
| `traits.json` | Пассивные приёмы веток и предметов. |

## Умение (`abilities.json`)

| Поле | Значение |
| --- | --- |
| `cost` | `action`, `bonus` или `free`. |
| `resource` | `none`, `slot` (ячейка, `slot_cost` — сколько) или `use` (`uses` раз за бой; `fixed_uses` — не растёт с уровнем). |
| `dark` | Тёмный дар: `hp` (цена хитами) или `slot` (цена ячейкой). Дары ограничены числом за бой и потолком Тьмы. |
| `target` | `self`, `enemy`, `ally`, `cell`, `empty_cell`. `range` — дальность в клетках, `target_filter` — `not_status`, `not_down`. |
| `radius` | Радиус области (попадает в параметры как `radius`). |
| `dice`, `scale` | Кости умения и рост с уровнем: `cantrip` — вдвое на 5 ур.; `dark` — +1 кость на 3 и 5 ур.; `dark5`, `bomb` — +1 на 5 ур. |
| `params` | Свои параметры для `"$имя"` в эффектах. |
| `attack` | Удар внутри действия «Атака» (можно продолжить начатую атаку). |
| `requires` | Условия: `action_used`, `action_free`, `no_adjacent_foe`, `not_status:X`, `status_or_slot:X`. |
| `tags` | `spell`, `heal` и т. п. — для предметов и приёмов. |
| `effects` | Список эффектов, выполняются по порядку. |
| `aura_effects` | Эффекты ауры, которую умение вешает (например, «Духовные стражи»). |
| `ai` | Как умением пользуется ИИ (ниже). |

### Эффект

Каждый эффект — `{"op": …, "to": …, …}`. Кого задевает, решает `to`:

- `self`, `target` (по умолчанию), `area` (клетки `ability_area`), `most_wounded_ally`
  (`radius`, `conscious`), `nearest_foes` (`count` ближайших в `radius`), `adjacent_foe`
  (враг рядом с целью — для «Рассечения»).
- Для `area`: `who` — `all`, `foes`, `allies`, `others`; фильтры `undead`, `wounded`,
  `not_status`; `friendly_fire: true` — своих не задевает при приёме `no_friendly_fire`.

| `op` | Что делает | Поля |
| --- | --- | --- |
| `weapon_attack` | Атака оружием. | `weapon`: `main`, `ranged` или `{kind, damage}`; `extra_dice`; `drain_extra`; `on_hit` — эффекты при попадании. |
| `spell_attack` | Атака заклинанием. | `dice`, `repeat`, `retarget`. |
| `save_damage` | Спасбросок и урон. | `stat`, `half` (половина при успехе), `add_dice`. |
| `save` | Спасбросок с ветками. | `stat`, `dc` (`spell` или число), `not_undead`, `on_fail`, `on_success`. |
| `damage` | Урон без броска. | `dice` или `amount: "half_dealt"`. |
| `heal` | Лечение. | `dice`, `add: "level"`, `spell_heal`, `item_heal`, `amount: "half_dealt"`. |
| `heal_pool` | «Сохранение жизни»: `per_level` × уровень на раненых в радиусе. | `per_level`. |
| `status` | Наложить состояние. | `status`, `value` (число, кости, `$имя` или `dc`), `pay_slot`. |
| `zone` | Зона на поле. | `kind`: `trap`, `grease`, `web`, `spikes`; `dice`, `dc`. |
| `shove` | Толчок на клетку. | — |
| `hide` | Спрятаться. | `dc` (если врагу видно). |
| `refresh_action` | Вернуть действие. | — |
| `add_speed` | Добавить движение. | `amount` (по умолчанию скорость). |
| `bonus_dice` | Только в `on_weapon_hit` состояния: кости к попаданию. | `dice`, `drain`. |

### Поле `ai`

| Поле | Значение |
| --- | --- |
| `phase` | Когда ИИ думает об умении: `before` (до движения), `after`, `weapon` (вместо удара), `surge`. |
| `priority` | Порядок проверки внутри фазы. |
| `kind` | Как считать пользу: `ranged`, `zone`, `aura`, `fan`, `grease`, `web`, `trap`, `spikes`, `slow`, `turn`, `heal_pool`. |
| `pick` | Как выбрать цель: `wounded_ally`, `weakest_foe`, `guard_ally`. |
| `when` | Условия: `self_hp_below`, `self_hp_above`, `slots_at_least`, `status_or_slots`, `foes_within`, `no_foe_within`, `foe_within_move`, `wounded_allies`, `hp_above_dark_cost`, `target_reachable`, `target_out_of_reach`. |
| `min_value`, `min_need` | Порог пользы. |
| `foe`, `ally`, `foe_dice_mult`, `foe_per_attack`, `foe_skip` | Веса при подсчёте пользы. |
| `reach_down_ally`, `after` | Подойти к упавшему союзнику; `after: "down_ally"` — умение после подхода. |
| `skip` | ИИ умение не использует. |

## Состояние (`statuses.json`)

Свойства суммируются со свойствами приёмов (`mod_sum`, `mod_any`). `"$value"` — значение, которое
задал наложивший. Преимущество и помеха (`attack`, `defense` со знаком) не складываются.

- Броски: `attack`, `melee_attack`, `defense`, `defense_melee`, `defense_ranged` (+1 — преимущество
  у атакующего по носителю, −1 — помеха), `ac`, `melee_dmg`, `weapon_dr`.
- Ход: `skip_turn`, `no_actions`, `no_reactions`, `no_threat`, `immobile`, `speed_mult`,
  `max_attacks`, `flee`, `forced_target`, `untargetable`, `no_provoke`.
- Крючки: `turn_start` (`stand_up` и т. п.), `turn_end_save` — спасбросок в конце хода,
  `on_weapon_hit` — эффекты при попадании оружием, `aura_ability`.
- `ends` — когда состояние снимается: `own_turn_start`, `own_turn_end`, `src_turn_start`,
  `attack`, `attacked`, `weapon_hit`, `damaged`, `down`.
- Для ИИ и интерфейса: `ai_value`, `preview_mitigation`, `hide_expiry`.

## Приём (`traits.json`)

Те же свойства, что у состояний, плюс:

- `requires_trait` — действует только вместе с другим приёмом.
- `aura` — `{radius, who, mod}`, каждый вид ауры считается один раз.
- `ability_params` — правка параметров умений (`dice_bonus`, `radius`, `count`, свои поля).
- `uses_add`, `status_mod`, `start_status`.
- Именные правила веток: `attacks`, `cleave`, `relentless`, `assassinate`, `finisher`, `uncanny`,
  `crit_on`, `extra_on_hit`, `after_sneak`, `oa_stop`, `oa_adv`, `rescue`, `rally`, `save_reroll`,
  `undead_save_disadv`, `no_ranged_penalty`, `no_gift_limit`, `spell_heal`, `no_friendly_fire`.
- `note` — приём только для описания: правило не нужно в бою (так было и в прототипе).

## Сюжетный бой (`battles.json`)

Бои пролога (B8 плана `review/07-next-steps.md`) — те же карты из символов, плюс ключи ниже.
`CombatData.scenario()` собирает их в `scenario.stage`, а `Battle` исполняет и сохраняет вместе с боем.
Сюжетные флаги (переменные Ink на момент боя) приходят из `Game.battle_scenario()`.

| Ключ | Что делает |
| --- | --- |
| `party` | Отряд боя: список спутников (пусто — герой один). Без ключа отряд — из сюжета и `parties`. |
| `bound` | `[{"unit", "round"}]` — связанный союзник на клетке `b`: не ходит, враги его не трогают; вступает в бой в начале раунда `round` или когда герой встанет рядом (разрезает верёвки). |
| `timed` | `[{"unit", "status", "until_round", "log"}]` — состояние с начала боя до раунда (Ирена в храме: `hesitant`). |
| `waves` | `[{"round", "at", "units", "trial_units", "log"}]` — подкрепление в начале раунда; `at` — цифра на карте, клетки выхода. Пока волна не вышла, бой «до последнего врага» не кончается. |
| `objective` | `{"type": "survive", "rounds", "key"}` — победа, когда раунд `rounds` прошёл; `key` — строка цели для экрана. |
| `ambush_flag` | Флаг Ink: если он истинен, враги застигнуты врасплох (`surprised`) и пропускают первый ход. |
| `flag_drop` | `{флаг: [буквы]}` — враги, которых нет, если флаг истинен (арбалетчик ушёл до боя). Флаг — имя переменной Ink или `имя=значение` (`ch1_choice=riot`). |
| `flag_add` | `{флаг: [буквы]}` — наоборот: участники есть, только если флаг истинен (тревога и узники у клети при бунте). |
| `silver` | Добыча серебра за победу (идёт в `GameState.silver`). |
| `cannot_lose` | Поражения нет: если отряд выбыл, бой засчитан победой, `stage.rescued = true` (облава). |
| `ground` | Пол поля для рисовки: `yard`, `temple`, `ford`, `camp`, `gate`, `mine` (глава 1), `flooded`, `flooded_shrine` (глава 2), `dwarf`, `dwarf_archive`, `dwarf_seal` (глава 3); без ключа — серое поле тестовых боёв. |
| `cover` | Укрытия (глава 2): если линия выстрела или заклинания задевает препятствие рядом с целью (и не рядом со стрелком), КД цели +2 (`Battle.ac_against`). Без ключа укрытий нет, бои пролога и главы 1 не меняются. |
| `intro` | Ключ строки `combat.csv`, которая пишется в журнал боя в начале (правило поля: вода по пояс). |

Буква из `legend` с записью `"ally": true` в `enemies.json` — союзник отряда под ИИ (узники в бунте главы 1,
`docs/CHAPTER1_BATTLES.md`): ходит сам, в поражении не считается.

Приём `stone_armor: N` (стражи Молчащих, глава 3) — каменная броня: удар оружием теряет N урона, если оружие
не дробящее (`Battle.BLUNT_WEAPONS`) и цель не обойдена (`Battle.flanked`: союзник атакующего вплотную к цели с
другой стороны); заклинаний броня не держит. Прогноз атаки отдаёт поле `stone`.

Поле `tether` у врага в `enemies.json` — цепь: дальше этого числа клеток от клетки, где он стоял в начале
боя, он не уходит (страж шлюза главы 2, `stage.tether`, сохраняется с боем).

### Знаки карты

Буквы — враги по `legend`, `h` — места отряда, `b` — связанный союзник, цифры — выходы подкреплений.
Препятствия по правилам одинаковы (клетка занята, по диагонали мимо угла не пройти); знак задаёт только
рисовку (`CombatData.OBSTACLE_GLYPHS`, `BoardView.OBSTACLE_LOOK`):

| Знак | Препятствие | Знак | Препятствие |
| --- | --- | --- | --- |
| `#` | стена, дом | `%` | дерево, кусты |
| `\|` | колонна, столб ворот | `+` | забор |
| `_` | скамья | `=` | телега |
| `&` | алтарь | `@` | колодец |
| `*` | обломки, камни | `^` | костёр |
| `~` | глубокая вода (плоская) | | |

По знакам `,` (брод), `:` (дорога) и `;` (пепел) можно ходить: они меняют только вид пола. Знак `-` — вода
по пояс (глава 2): ходить можно, но шаг в такую клетку стоит 2 клетки движения (`Battle.step_cost`); приём
`swimmer` (утопленники, страж, жрец) снимает эту цену. Тайлы и объекты
по `ground` и виду препятствия задаёт `GROUND_ART` в `scripts/ui/board_view.gd` (дом, телега, скамья — один рисунок
на группу клеток); вид без рисунка остаётся заглушкой, правила от графики не зависят.

Состояния для этих правил: `bound` (связан), `hesitant` (`no_harm`: только защита и лечение — нельзя
атаковать и брать умения на врага или клетку), `surprised` (пропуск хода). Для ИИ: условие
`allies_within: [радиус, сколько]` в `ai.when` («Подгонять!» Брандта), а умение-контроль с эффектом
`save` (аркан) оценивается по `ai_value` накладываемого состояния.
