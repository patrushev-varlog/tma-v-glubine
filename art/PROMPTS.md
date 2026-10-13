# Промпты для пиксель-арта «Тьмы в глубине»

Задача: заменить серые ромбы и прямоугольники прототипа боя (`prototypes/combat`) на графику, близкую к финальной. Документ содержит список нужных ассетов, правила стиля и готовые промпты под **PixelLab** (персонажи, анимации, изометрические тайлы, объекты) и **Retro Diffusion** (тайлы, предметы, иконки, интерфейс, эффекты). Портреты — универсальной моделью с пикселизацией, как записано в DESIGN.md, раздел 4.

Промпты на английском: обе модели понимают его заметно лучше. Пояснения на русском.

Названия полей и пресетов сверены с документацией сервисов на 2026-10 (PixelLab: Camera view, Outline, Shading, Details, Target palette, isometric tile shapes Thin/Thick/Block; Retro Diffusion: стили `isometric`, `isometric_asset`, `item_sheet`, `skill_icon`, `ui_element`, `character_turnaround`, `environment`, параметры `input_palette`, `remove_bg`, `tile_x/tile_y`, размер 16–384). Если в интерфейсе что-то названо иначе, ориентируйтесь на смысл.

---

## 0. Порядок работы

1. **Сначала якоря стиля, потом всё остальное.** Сгенерировать и вычистить в Aseprite три образца: один персонаж (Гаррет), один тайл пола и одно препятствие Верхних шахт. Утвердить. Дальше эти три картинки идут в каждую генерацию как *style reference / init image*, а палитра — как *target palette* (PixelLab) или `input_palette` (Retro Diffusion). Без этого 200 ассетов разъедутся по стилю.
   *Статус на 2026-10-12: выбраны Гаррет v4, пол v3, крепь v4 — файлы в `art/anchors/approved/`, подробности в [art/anchors/README.md](anchors/README.md). Палитра — Resurrect 64 (`art/palette/`), якоря в неё переведены. Ждут ручной чистки.*
2. **Первая волна (приблизить прототип):** тайлсет Верхних шахт, отряд (герой-волшебник обеих веток + Ирена, Гаррет, Велиор), враги уровней 1–2 (надсмотрщик, старший надсмотрщик, зомби, скелет, скелет-лучник), 10 основных эффектов, иконки умений отряда, значки состояний, рамка интерфейса. Этого хватает, чтобы бои 1–2 выглядели «как игра».
3. **Вторая волна:** остальные четыре локации, оставшиеся классы героя, враги уровней 3–5, все эффекты, портреты.
4. **Третья волна:** иконки ~60 предметов, Darkness-варианты портрета героя, ассеты пролога и главы 5 вне прототипа (раздел 10).
5. **Каждый ассет проходит чистку** (раздел 9): палитра, контур, точка опоры, мусорные пиксели.

*Дальше по плану [review/07-next-steps.md](../review/07-next-steps.md) (поток K, 2026-10-12): портреты к демо — [art/portraits/README.md](portraits/README.md), стиль-тест на людях — [art/style-test/README.md](style-test/README.md), полный список ассетов пролога со звуком — [art/prologue/ASSETS.md](prologue/ASSETS.md).*

---

## 1. Правила стиля (одинаковые для всех ассетов)

| Параметр | Значение |
|---|---|
| Проекция | Изометрия 2:1 (dimetric), как в прототипе: ромб клетки 64×32. |
| Масштаб | Всё рисуется в масштабе 1:1 к сетке, без апскейла внутри ассета. Увеличение только камерой, целыми шагами (×2, ×3). |
| Палитра | Одна на всю игру, 48–64 цвета. По умолчанию **Resurrect 64** (Lospec): есть тёплые рампы под факелы и холодные под камень и нежить. Альтернатива **Apollo** (46 цветов). Финальный выбор делаем на якорях стиля. |
| Свет | Ключевой — тёплый свет факела сверху слева. Заполняющий — холодный сине-серый из глубины снизу справа. Тени холодные, блики тёплые. |
| Насыщенность | Приглушённая. Яркие цвета только у магии, огня, крови и интерфейсных подсветок, чтобы они читались. |
| Контур | Персонажи и предметы: однопиксельный контур *самым тёмным цветом палитры*, не чистым чёрным; на освещённой стороне можно selective outline. Тайлы пола: без контура. Препятствия: контур только по внешнему силуэту. |
| Затенение | Medium shading: 3–4 тона на материал. Без сглаживания (anti-aliasing), без градиентного дизеринга на персонажах; дизеринг допустим на больших поверхностях стен. |
| Детали | Medium detail. Персонаж читается по силуэту и одному-двум цветовым пятнам с расстояния. |
| Фон | Прозрачный у всего, кроме портретов. |
| Цветовые коды отряда | Сохраняем из прототипа как акцент в одежде: герой — холодный синий, Ирена — бледное золото, Гаррет — ржаво-оранжевый, Велиор — болотно-зелёный. Враги: живые люди Короля — чёрное с тускло-красным, нежить — костяной и сине-зелёное свечение. |
| Знак Короля | Простая трёхзубая корона, вписанная в круг. Один и тот же знак на надсмотрщиках, телегах, оружии мастерских. |

### Размеры холстов

| Ассет | Холст | Опора (ноги/центр клетки) |
|---|---|---|
| Тайл пола (плоский ромб) | 64×32 | центр ромба (32, 16) |
| Тайл пола с толщиной (край карты) | 64×48 | центр верхнего ромба (32, 16) |
| Низкое препятствие (ящик, валун, вагонетка) | 64×64 | (32, 48) |
| Высокое препятствие (колонна, статуя, горн) | 64×96 | (32, 80) |
| Персонаж обычного роста | 64×64, фигура 40–46 px | (32, 56) |
| Дварф | 64×64, фигура 32–36 px | (32, 56) |
| Крупный враг (зомби-огр, мясной голем) | 96×96, фигура 72–84 px | (48, 84) |
| Эффект на клетке | 64×64 | (32, 48) |
| Эффект по площади (радиус 1, 3×3 клетки) | 192×96 | центр |
| Снаряд | 16×16 или 32×16 | центр |
| Иконка умения | 32×32 | — |
| Иконка предмета | 32×32 (по DESIGN.md) | — |
| Значок состояния | 12×12 | — |
| Портрет в панели боя | 64×64 | — |
| Портрет в диалоге | 128×128 | — |

### Направления и анимации

По DESIGN.md: 4 диагональных направления, 2 из них зеркалом. В изометрии клетки прототипа движение идёт по диагоналям экрана, поэтому нужны **SE** (вниз-вправо, лицом к камере) и **NE** (вверх-вправо, спиной к камере). SW и NW получаются отражением.

В PixelLab создаём персонажа в 8 направлениях (south-east и north-east в их терминах) и берём только два нужных.

| Анимация | Кадров | Где нужна |
|---|---|---|
| idle (стойка, дыхание) | 4 | все |
| walk | 6 | все |
| attack_melee | 5 | бойцы ближнего боя, все враги ближнего боя |
| attack_ranged (лук) | 5 | плут-ловкач, скелеты-лучники, костяной стрелок |
| cast (заклинание) | 6 | жрец, волшебник, Ирена, послушник |
| throw (бросок) | 4 | Велиор (бомбы, ловушки), плут-ловкач (веер кинжалов) |
| hit (урон) | 3 | все |
| down (выбывание) | 5, последний кадр держится | отряд (при 0 хитов выбывает, не умирает) |
| death (гибель) | 5–6 | враги; нежить рассыпается, люди падают |
| prone (сбит с ног) | 1 статичный кадр | все, кто может быть сбит (Гаррет «Сбить с ног») |

### Общий «хвост» промптов

Подставляйте в конец каждого промпта соответствующий блок.

**STYLE_ISO** (тайлы и объекты):
```
isometric pixel art, 2:1 dimetric projection, dark fantasy underground mine, muted desaturated palette, warm torchlight from upper left, cool blue-grey shadows from lower right, crisp hard pixels, no anti-aliasing, game asset, transparent background
```

**STYLE_CHAR** (персонажи):
```
pixel art game sprite, single full-body character, isometric 3/4 view, dark fantasy, muted desaturated palette with one accent color, warm torchlight from upper left, 1px dark outline (not pure black), medium shading, readable silhouette, feet at bottom center, transparent background
```

**NEGATIVE** (где поле есть):
```
blurry, anti-aliasing, smooth gradients, photorealistic, 3d render, text, watermark, signature, frame, chibi, cute, bright saturated colors, front orthographic view, top-down view, cropped, multiple characters, extra limbs
```

---

## 2. Настройки инструментов

### PixelLab — персонажи
- Инструмент: Create character (8 directions; V3 или Pro, если доступен). Для быстрых черновиков — Create instant character (только 32×32 или 32×40, годится на пробу силуэта).
- Size: 64×64 (крупные враги — 96×96 или максимум, который даёт тариф).
- Camera view: **low top-down** (ближе всего к изометрии 2:1). Если есть флажок *isometric* — включить.
- Outline: single color outline (затем перекрасить контур в тёмный цвет палитры). Shading: medium. Details: medium.
- Target palette: PNG палитры (Resurrect 64 или утверждённая).
- Style reference / init image: утверждённый Гаррет.
- Анимации: Animate with text (описания ниже) или Animate with skeleton для атак со сложной траекторией.

### PixelLab — тайлы и объекты
- Create isometric tile: tile size **32** (это размер стиля, холст ставим 64), shape **Thin** для пола, **Thick** для края карты, **Block** для кубических препятствий.
- Create map object (или 1-direction object) для препятствий и реквизита: холст 64×64 или 64×96, view low top-down.

### Retro Diffusion
- Модель RD Plus (качество) или RD Fast (черновики, перебор вариантов).
- Стиль: `isometric_asset` для препятствий и реквизита, `isometric` для пола, `item_sheet` для листов предметов, `skill_icon` для иконок умений, `ui_element` для интерфейса, `character_turnaround` для разворотов персонажа (как референс для PixelLab).
- `input_palette`: PNG утверждённой палитры. `remove_bg: true` для всего, кроме пола и портретов.
- Минимальный размер генерации 16, максимальный 384: иконки 32×32 генерировать листом 128×128 (4×4) или 256×256 и резать.
- `seed` фиксировать для серий, чтобы варианты одного тайла были родственными.

---

## 2a. Схема анимированного персонажа (утверждена на Гаррете, 2026-10-12)

Проверено на Гаррете: только эта схема даёт одного и того же персонажа во всех анимациях и стабильное оружие. Все остальные способы (template-режим, v3 по описанию, перенос облика, щит отдельным спрайтом) отбракованы — подробности в `art/wave1/README.md`.

1. **Одна основа.** Персонаж создаётся один раз: `create_character` в режиме **pro** со стилевым образцом Гаррета (`style_character_id`) или в режиме **v3** из спрайта, повёрнутого строго лицом к камере. Все анимации делаются от этой основы, а не от её состояний.
2. **Основа сразу без оружия.** В описании персонажа: «обе руки пустые, кулаки сжаты, без оружия», щит и снаряжение на теле (отдельный щит выглядел плохо). Так шаг `create_character_state` не нужен (экономия 10–25 генераций) и нет риска, что состояние уйдёт от основы. Для уже созданных персонажей с оружием — состояние «оружие и ножны убраны, кулак сжат».
3. **Шаблонные анимации только в режиме `skeleton-v3`.** Стойка `breathing-idle`, ходьба `walking-6-frames` (зомби — `scary-walk`), урон `taking-punch`, выбывание/гибель `falling-back-death`, бросок `throw-object`. Режим `template` перерисовывает кадры и теряет лицо и предметы.
4. **Удар — по заданному скелету** (`animate_with_skeleton_v3`). Шаблона рубящего удара в PixelLab нет. Позы: стойка → замах из-за правого плеча → клинок над головой → косой удар вниз-вперёд → конец удара у колена → возврат. Позы заданы смещениями относительно правого плеча, поэтому переносятся на любого персонажа. Название действия — «мах пустым кулаком», иначе генератор дорисовывает клинок в руку.
5. **Оружие отдельным спрайтом.** Один раз генерируется объектом на холсте 32×32 (посох 32×48), лезвием вверх, вид сбоку, в промпте «perfectly vertical, pointing straight up, not diagonal». **Обязательная проверка:** ширина обрезки ≤ половины высоты, иначе спрайт косой и повторяется с другим сидом (косое оружие даёт неверный угол хвата и выглядит вдвое длиннее). Проверить, что остриё сверху (кинжал Велиора вышел вверх ногами). Длина клинка 25–30 px при росте персонажа ~46 px, кинжал ~18 px. Хват: у клинков — гарда + 3 px, у булавы без гарды — 0,72 высоты, у посоха и лука — середина; лук в левой руке всегда вертикален. Рукоять крепится к правой кисти: кисть берётся из `estimate-skeleton` по каждому кадру (0,1 генерации), в кадрах удара уточняется по кулаку (пятно кожи рядом с кистью). Кулак рисуется поверх рукояти.
6. **Угол клинка с учётом хвата.** Клинок не продолжает предплечье: к направлению предплечья добавляется поправка, подобранная так, чтобы в стойке клинок смотрел вперёд с небольшим наклоном вниз (ЮВ ≈105°, СВ ≈75°, где 0° — вверх, по часовой). В ударе, уроне и выбывании углы заданы кривыми по кадрам: удар ЮВ `105, −40, −10, 50, 125, 105`; урон — рывок клинка вверх на 10–20° и возврат; выбывание — клинок постепенно ложится на землю.
7. **Палитра и чистка** — как в разделах 1 и 9. Готовые кадры с мечом — промежуточный результат: в игре оружие лучше крепить в движке к тем же точкам кисти, тогда смена экипировки не требует перегенерации.

Стоимость на персонажа: основа 1–10, тело без оружия 10–25, шаблонные анимации ~16–32, удар 4–6, оружие 1, скелеты ~5 — всего 40–80 генераций. Скрипты конвейера: `wave_lib.py`, `compose3.py` (в рабочей папке сессии; перенести в `tools/` репозитория).

## 3. Тайлсеты пяти локаций прототипа

Каждая локация: 4 варианта пола (основной, два вариативных, один «грязный» или с трещиной), 1 край карты с толщиной, 4–6 препятствий (в прототипе `#` — непроходимая клетка, укрытие), 3–4 предмета декора без коллизии, зона старта отряда (`hh` в карте) — отдельный вариант пола.

Пол — простая поверхность, без крупных объектов: на нём будут лежать подсветки хода и эффекты, поэтому контраст низкий.

### 3.1. Пролог, бой у ворот рудника (уровень 1)

Ночь, утоптанная грязь у ворот, костры колонны, телеги с короной.

**Пол** (PixelLab isometric tile Thin / RD `isometric`, 64×32):
```
isometric floor tile, trampled muddy earth with cart ruts and scattered gravel, wet patches, night, faint warm firelight, low contrast, seamless edges, STYLE_ISO
```
Варианты: `...with scattered straw and a dropped shackle`, `...with a puddle reflecting firelight`, `...with old cobblestones half buried in mud` (зона старта отряда).

**Край карты** (Thick, 64×48):
```
isometric ground tile with visible earth cross-section on the side, mud on top, layered soil and stones on the edge, STYLE_ISO
```

**Препятствия** (RD `isometric_asset` / PixelLab map object):
```
isometric wooden prison cart with iron cage bars, a painted crown-in-circle emblem on the side, 64x64, STYLE_ISO
isometric stack of mining supply crates and a barrel, rope bindings, 64x64, STYLE_ISO
isometric large mossy boulder, 64x64, STYLE_ISO
isometric section of a sharpened wooden palisade, 64x64, STYLE_ISO
isometric stone gatepost of an old mine entrance with a rusted iron lantern, 64x96, STYLE_ISO
```

**Декор:**
```
isometric campfire with logs and embers, small, glowing, 64x64, STYLE_ISO
isometric pile of chains and shackles on the ground, 64x32, STYLE_ISO
isometric dropped torn sheet of paper with a list of names, tiny, 32x16, STYLE_ISO
```

### 3.2. Глава 1. Верхние шахты (уровень 2)

Штольня у подъёмника, деревянная крепь, рельсы, мостки.

**Пол:**
```
isometric floor tile, rough grey mine tunnel stone floor with rock dust and small ore fragments, dim torchlight, low contrast, STYLE_ISO
```
Варианты: `...with a section of narrow minecart rails`, `...with wooden plank walkway boards`, `...with a crack and loose gravel`.

**Препятствия:**
```
isometric mine timber support frame, two thick wooden posts and a crossbeam, iron brackets, a hanging oil lamp, 64x96, STYLE_ISO
isometric rusty iron minecart full of dark ore on rails, 64x64, STYLE_ISO
isometric heap of raw ore and broken rock, 64x64, STYLE_ISO
isometric wooden scaffolding platform with ladder, 64x96, STYLE_ISO
isometric collapsed rock pile blocking the tunnel, 64x64, STYLE_ISO
```

**Декор:**
```
isometric pickaxe and shovel leaning against nothing, lying on floor, 64x32, STYLE_ISO
isometric small oil lamp on the floor with warm glow, 32x32, STYLE_ISO
isometric bucket of water and a coil of rope, 32x32, STYLE_ISO
```

### 3.3. Глава 2. Затопленные выработки (уровень 3)

Тёмная вода, ил, обрушенная крепь, холодный свет.

**Пол:**
```
isometric floor tile, wet black stone mine floor covered by a thin film of dark water, silt and drowned weeds, cold blue-green reflections, low contrast, STYLE_ISO
```
Варианты: `...with a shallow puddle`, `...with slick algae`, `...with half-submerged rails`.

**Вода (декор и анимация, 4 кадра):**
```
isometric shallow black water tile with subtle ripples, cold faint reflection, seamless, STYLE_ISO
```
Генерировать 4 варианта с одним seed и разной фазой ряби; в Aseprite собрать в цикл.

**Препятствия:**
```
isometric half-sunken minecart covered in slime and weeds, 64x64, STYLE_ISO
isometric broken rotten timber support, collapsed, dripping water, 64x96, STYLE_ISO
isometric limestone stalagmite cluster, wet, 64x96, STYLE_ISO
isometric pile of waterlogged crates and a drowned lantern, 64x64, STYLE_ISO
isometric deep dark water pool, impassable, black surface, 64x32, STYLE_ISO
```

### 3.4. Глава 3. Дварфийские залы (уровень 4)

Залы Молчащих: резной камень, руны, колонны, статуи, холодная красота.

**Пол:**
```
isometric floor tile, large carved dwarven stone slab with a thin engraved rune border, ancient, dusty, cold grey-blue stone with faint gold inlay, low contrast, STYLE_ISO
```
Варианты: `...cracked slab`, `...with a circular rune seal fragment`, `...with fallen dust and bone fragments`.

**Препятствия:**
```
isometric massive dwarven stone pillar with geometric carvings and a bronze ring band, 64x96, STYLE_ISO
isometric statue of a hooded dwarf with a finger to its lips, guardian of silence, weathered stone, 64x96, STYLE_ISO
isometric dwarven stone sarcophagus with runes on the lid, 64x64, STYLE_ISO
isometric collapsed archway rubble with carved fragments, 64x64, STYLE_ISO
isometric bronze brazier on a stone base with cold blue flame, 64x96, STYLE_ISO
```

**Декор:**
```
isometric scattered dwarven runic tablets on the floor, 64x32, STYLE_ISO
isometric broken bronze shield and helmet on the floor, 32x32, STYLE_ISO
```

### 3.5. Глава 4. Кузницы плоти (уровень 5)

Чугун, жар горнов, решётки стоков, цепи. Жестокость показываем намёком: силуэты, ткань, крюки, без натурализма.

**Пол:**
```
isometric floor tile, black iron foundry floor plates with rivets, soot and scorch marks, faint red heat glow from below, low contrast, STYLE_ISO
```
Варианты: `...with an iron drainage grate`, `...with dark stains and slag drips`, `...with stone floor and chalk markings`.

**Препятствия:**
```
isometric blazing forge furnace of black iron with glowing orange mouth and chimney, 64x96, STYLE_ISO
isometric large iron vat with steaming dark liquid, chains hanging, 64x64, STYLE_ISO
isometric heavy anvil on a stone block with tongs, 64x64, STYLE_ISO
isometric wooden work table covered by a stained cloth, surgical tools on top, 64x64, STYLE_ISO
isometric rack of iron hooks with hanging chains, 64x96, STYLE_ISO
```

**Декор:**
```
isometric pile of discarded armor and helmets bearing a crown emblem, 64x32, STYLE_ISO
isometric bucket of glowing coal, 32x32, STYLE_ISO
```

### 3.6. Тайловые отметки боя (вместо цветных ромбов)

Эти отметки лучше рисовать вручную в Aseprite: они простые, должны быть полупрозрачными и идеально совпадать с ромбом. Генерация здесь даёт только идею.

| Отметка | Что | Совет |
|---|---|---|
| Досягаемость хода | Синий ромб | Тонкая рамка 1 px + заливка 25% |
| Цель-враг | Красный ромб | Рамка + уголки-скобки |
| Цель-союзник | Зелёный ромб | Как у врага, зелёный |
| Площадь умения | Янтарный ромб | Пульсация 2 кадра |
| Путь | Белая линия | Точки-следы по центрам клеток |
| Выбранная клетка | Белая рамка | Мигание |
| Активный участник | Жёлтое кольцо под ногами | 4 кадра вращения рун |
| Ловушка Велиора | Жёлтый крест | Иконка капкана (см. 5.4) |

### 3.7. Пролог: деревня Эшмур, храм, брод

Локации пролога вне прототипа боя; список и порядок — [art/prologue/ASSETS.md](prologue/ASSETS.md). Бой 4 (колонна у ворот) использует тайлсет 3.1. Деревня нужна в двух видах: ночь облавы (бой 1) и утро после пожара (сцена 3) — это один набор, утренний вариант делается перекраской и заменой целых домов на сгоревшие.

**Деревня, ночь облавы (бой 1):**
```
Пол: isometric floor tile, packed dirt village path with grass tufts and puddles, night, warm glow of a nearby fire, low contrast, seamless edges, STYLE_ISO
Пол, вариант: isometric floor tile, trampled grass with a few fallen leaves, night, low contrast, seamless edges, STYLE_ISO
Пол, огород: isometric floor tile, dug-up vegetable garden bed with cabbages, night, STYLE_ISO
Край карты (Thick, 64x48): isometric ground tile with earth cross-section on the side, grass on top, STYLE_ISO
Стена дома: isometric corner of a timber-and-wattle cottage with a thatched roof edge and a small shuttered window glowing warm, 64x96, STYLE_ISO
Горящий дом: isometric corner of a timber-and-wattle cottage on fire, flames on the thatched roof, sparks, 64x96, STYLE_ISO
Плетень: isometric section of a woven wattle fence, 64x64, STYLE_ISO
Поленница: isometric stacked firewood under a small lean-to roof, 64x64, STYLE_ISO
Колодец: isometric old stone village well with a wooden crank and bucket, 64x64, STYLE_ISO
Телега с короной: isometric wooden prison cart with iron cage bars, a painted crown-in-circle emblem on the side (как в 3.1, один ассет)
Колокольня: isometric wooden village bell tower base with a rope, 64x96, STYLE_ISO
Вилы и грабли: isometric pitchfork and rake leaning on a fence post, 32x48, STYLE_ISO
```

**Деревня, утро после облавы (сцена 3, осмотр без боя):** перекраска ночных тайлов в холодный серый утренний свет и
```
Сгоревший дом: isometric burned cottage ruins with charred beams and smoldering ashes, thin smoke, grey morning light, 64x96, STYLE_ISO
Пепел на полу: isometric floor tile, grey ash and charred straw over dirt, morning, low contrast, seamless edges, STYLE_ISO
Свежая могила: isometric fresh grave mound with a simple wooden marker, 64x32, STYLE_ISO
Брошенная телега: isometric abandoned broken cart with one wheel off, a crown-in-circle emblem on the side, 64x64, STYLE_ISO
Обрывок списка: isometric torn sheet of paper with neat handwritten names lying in the mud, tiny, 32x16, STYLE_ISO
Колея: isometric floor tile, deep cart ruts in mud leading in one direction, STYLE_ISO
Погреб: isometric wooden cellar hatch in the ground, half open, 64x32, STYLE_ISO
```

**Разрушенный храм, внутри (бой 2):**
```
Пол: isometric floor tile, cracked temple flagstones with faded painted pattern, candle wax drips, low contrast, seamless edges, STYLE_ISO
Пол, вариант: isometric floor tile, temple flagstones with scattered broken roof tiles and dust, STYLE_ISO
Пол у алтаря (зона Ирены): isometric floor tile, flagstones with a scorched circle burned into the stone, STYLE_ISO
Скамья: isometric wooden church pew, some knocked over, 64x64, STYLE_ISO
Сломанная скамья: isometric broken wooden pew split in half, 64x64, STYLE_ISO
Алтарь: isometric stone altar with a carved candle-flame symbol, many melted candles, 64x64, STYLE_ISO
Колонна: isometric stone column, cracked, with a fallen chunk at its base, 64x96, STYLE_ISO
Подсвечник: isometric tall iron candelabrum with lit candles, 32x64, STYLE_ISO
Обломки кровли: isometric pile of fallen roof beams and broken tiles, 64x64, STYLE_ISO
```

**Брод у ручья, вечер (бой 3):**
```
Пол: isometric floor tile, wet riverside grass with pebbles, dusk, low contrast, seamless edges, STYLE_ISO
Мелководье (проходимо): isometric floor tile, shallow clear stream water over pebbles with a few ripples, dusk light, STYLE_ISO
Глубокая вода (непроходимо): isometric floor tile, darker deeper stream water with a current, STYLE_ISO
Берег: isometric floor tile, muddy stream bank with reeds, STYLE_ISO
Костёр охотников: isometric campfire with logs, a cooking pot on a tripod, bedrolls nearby, 64x64, STYLE_ISO
Кусты (укрытие засады): isometric dense dark green bushes, 64x64, STYLE_ISO
Поваленное дерево: isometric fallen tree trunk with moss, 64x64 (лежит по диагонали ромба), STYLE_ISO
Валун: isometric large mossy boulder (как в 3.1, один ассет)
Ива: isometric willow tree trunk with drooping branches, 64x128, STYLE_ISO
```

**Колонна у ворот (бой 4), дополнение к 3.1:** в варианте «соседи» бой идёт у костров колонны, поэтому кроме 3.1 нужны
```
Связанные соседи: isometric group of three bound villagers sitting on the ground by a fire, roped together, 64x64, STYLE_ISO (декор, без коллизии; на клетку не ставится)
Коновязь: isometric hitching post with a sack of supplies, 64x64, STYLE_ISO
Палатка надсмотрщиков: isometric small canvas tent with a crown-in-circle pennant, 64x96, STYLE_ISO
```

**Дом героя (сцена 1, без боя):** если сцена 1 показывается картой, а не только диалогом, нужен маленький интерьер
```
Пол: isometric floor tile, worn wooden floorboards, warm hearth light, seamless edges, STYLE_ISO
Очаг: isometric stone hearth with a low fire and a hanging kettle, 64x96, STYLE_ISO
Стол: isometric rough wooden table with two stools, a bowl and a candle, 64x64, STYLE_ISO
Ведро под течью: isometric wooden bucket catching drips from the roof, small puddle, 32x32, STYLE_ISO
Полка класса: isometric wooden shelf with a few old books and a candle (волшебник) / a sword hanging on a wall peg (воин), 64x96, STYLE_ISO
```

---

## 4. Персонажи

Сначала для каждого персонажа делаем разворот (RD `character_turnaround` или PixelLab character 8 directions), утверждаем внешность, потом анимации.

Описания внешности спутников и врагов ниже — предложение. В сюжете зафиксированы только: Гаррет — бывший надсмотрщик, дезертир; Велиор — в сером плаще без знаков, на щеке выжжена корона, перечёркнутая ножом (глава 1, «Клетка» и лагерь: клеймо поставил сам Король, перечеркнул сам Велиор); Ирена — жрица разрушенного храма, в бою с посохом (пролог, сцена 4). Остальное можно править.

*Поправка 2026-10-12:* в первой редакции клеймо по ошибке было у Гаррета. Спрайты первой волны это не задело: шрама при 64 px не видно.

### 4.1. Герой: 4 класса × 2 ветки

В прототипе ветка задаёт оружие и броню, поэтому делаем 8 спрайтов. Пол героя в прототипе не выбирается: для первой волны делаем мужской вариант, женский добавляется второй серией с тем же промптом (`female` вместо `male`). Акцент — холодный синий (шарф, плащ или кушак).

```
Воин-страж: a {male|female} human villager-turned-soldier, dented steel breastplate over a padded gambeson, round wooden shield with an iron rim, longsword, short dark-blue cloak, worn boots, determined, STYLE_CHAR
Воин-берсерк: a {male|female} human warrior, leather jerkin with one chainmail pauldron, bare scarred forearms, two-handed greatsword held low, wild hair, ash smears on face, dark-blue sash, STYLE_CHAR
Плут-убийца: a {male|female} lean human rogue, dark hooded leather armor, face scarf, short sword and a curved dagger, dark-blue hood lining, crouched ready stance, STYLE_CHAR
Плут-ловкач: a {male|female} human rogue, light leather armor, shortbow in hand, quiver on the back, bandolier of throwing knives across the chest, dark-blue scarf, agile stance, STYLE_CHAR
Жрец (жизнь): a {male|female} human village priest, grey-white vestments over chainmail, iron mace, small wooden shield with a painted candle-flame symbol, dark-blue stole, calm, STYLE_CHAR
Жрец (свет): a {male|female} human priest, pale vestments with a sun-flame embroidered hem over chainmail, brass-headed mace that faintly glows, bright candle-flame pendant, dark-blue stole, STYLE_CHAR
Волшебник-воплотитель: a {male|female} human wizard, long dark-blue robe with burned singed hems, quarterstaff topped with an ember-glowing crystal, leather satchel, sharp gaze, STYLE_CHAR
Волшебник-сковыватель: a {male|female} human wizard, dark-blue robe with a rune-stitched sash, quarterstaff wrapped in iron chain, grimoire chained to the belt, hood down, STYLE_CHAR
```

Позже по DESIGN.md внешность меняется палитрой и наложением экипировки: держите оружие и доспех на отдельных слоях Aseprite с первого спрайта, это сильно упростит наложение.

### 4.2. Спутники

```
Ирена: a young human woman priestess of a ruined village temple, soot-stained pale grey habit with the hood down, chain shirt underneath, dark braided hair, wooden processional staff with an iron head, wooden prayer beads, a small bronze bell on her belt, pale gold accents, grieving but steady, STYLE_CHAR
Гаррет: a big broad-shouldered human man in his forties, deserter mine overseer, heavy chainmail under a black overseer tabard with the crown emblem torn off, longsword and a battered kite shield, short grey hair and a short grey beard, weathered face, rust-orange scarf, STYLE_CHAR
Велиор: a lean wiry human scout, grey hooded cloak with no insignia, dark leather armor, short sword, belt with alchemical bomb flasks and a coil of trap wire, sharp pale face with a branded crown on one cheek crossed out by a knife scar, swamp-green inner lining, watchful, STYLE_CHAR
```

### 4.3. Враги (по уровням прототипа)

| Id | Уровни | Холст | Анимации сверх idle/walk/hit/death |
|---|---|---|---|
| overseer | 1–2 | 64 | attack_melee |
| overseer_chief | 1–2 | 64 | attack_melee |
| zombie | 1–2 | 64 | attack_melee |
| skeleton_archer | 1–3 | 64 | attack_ranged |
| skeleton | 2, 4 | 64 | attack_melee |
| drowned | 3 | 64 | attack_melee (хватка) |
| ghoul | 3–5 | 64 | attack_melee (когти) |
| acolyte | 3, 5 | 64 | cast (луч болезни) |
| dwarf_dead | 4 | 64 | attack_melee (молот) |
| wight | 4–5 | 64 | attack_melee, двойной удар |
| bone_archer | 4 | 64 | attack_ranged |
| ogre_zombie | в контенте, в боях пока нет | 96 | attack_melee (дубина) |
| flesh_golem | 5 | 96 | attack_melee, двойной удар |

```
Надсмотрщик: a human mine overseer, black padded jacket with a dull-red iron crown-in-circle badge, leather cap, sabre in hand, coiled whip on the belt, cruel tired face, STYLE_CHAR
Старший надсмотрщик: a tall human overseer captain, chain shirt under a long black coat, silver crown-in-circle badge, longsword, a rolled list of names tucked in the belt, cold commanding posture, dull-red accents, STYLE_CHAR
Зомби: a freshly risen villager corpse, torn peasant work clothes, grey-green skin, slack jaw, empty eyes with a faint green glint, shambling hunched pose, STYLE_CHAR
Скелет: a skeleton soldier in rusted kingdom guard remnants, cracked helmet, rusty short sword, torn faded tabard, faint cold blue glow in the eye sockets, STYLE_CHAR
Скелет-лучник: a skeleton archer with a tattered hood, short bow, quiver of ragged arrows, faint cold blue glow in the eye sockets, STYLE_CHAR
Утопленник: a bloated drowned miner corpse, waterlogged pale blue skin, silt and weeds hanging from limbs, broken miner's lamp on the chest, dripping water, grasping hands, STYLE_CHAR
Гуль: a gaunt hunched ghoul, grey stretched skin, long black claws, lank hair, crouching low ready to pounce, hungry yellow eyes, STYLE_CHAR
Послушник некроманта: a human necromancer acolyte, dark hooded robe with bone ornaments, pale crown-in-circle sigil on the chest, one hand raised with sickly green energy, gaunt face, STYLE_CHAR
Мёртвый дварф: a short stocky undead dwarf warrior in heavy ancient dwarven plate armor with engraved runes, rotting braided beard, warhammer, cold blue glow from the helmet eye slits, dwarf proportions about 34 px tall, STYLE_CHAR
Умертвие: a tall wight, undead knight in ornate old royal guard plate armor, tattered dark cape, longsword, gaunt grey face with icy blue eyes, cold mist at the feet, STYLE_CHAR
Костяной стрелок: an elite skeletal archer with bone-plated armor and a longbow made of bone, ragged dark hood, cold blue eye glow, tall, STYLE_CHAR
Зомби-огр (96x96): a huge undead ogre corpse, grey rotting skin, iron collar and broken chains, massive wooden club, hunched, about 80 px tall, STYLE_CHAR
Мясной голем (96x96): a huge flesh golem stitched from many corpses, iron staples, riveted plates and chains, furnace burn scars, small head sunk between massive shoulders, two enormous fists, about 84 px tall, STYLE_CHAR
```

### 4.4. Промпты анимаций (PixelLab, Animate with text)

Описание действия добавляется к утверждённому персонажу. Указывайте направление (south-east / north-east).

```
idle: breathing idle, subtle chest and shoulder movement, weapon held ready, 4 frames, loop
walk: walking cycle, steady pace, 6 frames, loop
attack_melee: steps forward and swings {weapon} in a diagonal downward strike, then recovers, 5 frames
attack_melee (тяжёлое оружие): winds up overhead and smashes {weapon} down, heavy impact, 5 frames
attack_ranged: draws the bow, aims, releases the arrow, 5 frames
cast: raises {staff|hand|holy symbol}, magic gathers, then thrusts it forward releasing the spell, 6 frames
throw: reaches to the belt and throws a small object in an arc, 4 frames
hit: flinches backward from a blow, 3 frames
down (отряд): staggers, drops to one knee, then collapses to the ground wounded but alive, 5 frames, last frame held
death (люди): falls backward to the ground and lies still, 5 frames
death (нежить): body collapses and crumbles into a pile of bones and dust, 6 frames
prone: lying on the ground on the side, trying to get up, single frame
```

### 4.5. Персонажи пролога сверх первой волны

Делаются по схеме 2a. Состав и анимации — [art/prologue/ASSETS.md](prologue/ASSETS.md).

```
Прихожанин-мертвец (бой 2): a freshly risen village parishioner corpse in a simple clean Sunday tunic and a wool shawl, grey-green skin, slack jaw, empty eyes with a faint green glint, shambling pose, STYLE_CHAR
Прихожанка-мертвец (бой 2): a freshly risen old village woman corpse in a dark Sunday dress and a white head scarf, grey-green skin, empty eyes with a faint green glint, shambling pose, STYLE_CHAR
Арбалетчик-надсмотрщик (бой 3): a human mine overseer with a loaded crossbow, black padded jacket with a dull-red iron crown-in-circle badge, bolt quiver on the hip, leather cap, STYLE_CHAR
Сосед с вилами (бой 1, добивает последнего мертвеца): a middle-aged male villager in a nightshirt and boots, holding a pitchfork, scared but resolute, STYLE_CHAR
Супруга героя (сцены 1–2): a woman in her early thirties, villager, plain homespun dress, dark wool shawl, chestnut hair loosely pinned up, STYLE_CHAR
Супруг героя (сцены 1–2): a man in his early thirties, villager, plain linen shirt, dark wool vest, short chestnut hair, short beard, STYLE_CHAR
Олдрик (сцена 3): an old villager man in his seventies, wool cap, sheepskin vest, soot-stained face, white stubble, slightly hunched, STYLE_CHAR
Соседка (сцены 3, 6): a village woman in a plain dress and apron, head scarf, soot-stained, STYLE_CHAR
```

Снаряд арбалета: `single short crossbow bolt in flight, 16x16, STYLE_FX`.

Позы-состояния (один кадр, по схеме 2a как `create_character_state` от готовой основы):
```
Гаррет связан (сцена 5): lying on the ground on his side, hands tied behind the back, ropes around the ankles
Брандт связан (сцена 7): sitting on the ground, hands tied in front, wounded, head lowered
Супруг в телеге (сцена 2): standing behind the cage bars of the cart, hands on the bars (поверх ассета телеги)
```

---

## 5. Эффекты умений

Эффекты держим яркими (единственное место с полной насыщенностью) и короткими: 4–8 кадров. Генерация: RD (стиль `default` или `isometric_asset`, `remove_bg`) по кадру-ключу, затем анимация в PixelLab (Animate object/image) или вручную. Хвост для всех:

**STYLE_FX:**
```
pixel art visual effect, isometric view, bright saturated magic colors against transparency, hard pixels, no anti-aliasing, transparent background
```

### 5.1. Отряд и герой

| Умение (id) | Что видно | Промпт |
|---|---|---|
| Священное пламя (sacred_flame) | столб белого огня падает на цель | `a pillar of radiant white-gold holy fire descending onto a single target, 64x64, STYLE_FX` |
| Слово исцеления (healing_word) | золотые искры над союзником | `soft golden healing sparkles rising in a spiral, 64x64, STYLE_FX` |
| Массовое слово исцеления (mass_healing_word) | то же над несколькими + волна от жреца | `expanding ring of golden light with rising sparkles, 192x96, STYLE_FX` |
| Огненный снаряд (fire_bolt) | снаряд + вспышка | `small fire bolt projectile with a short ember trail, 32x16, STYLE_FX`; попадание: `small fiery burst impact, 64x64, STYLE_FX` |
| Волшебная стрела (magic_missile) | 3 фиолетовых дротика | `three glowing violet magic darts, 32x16, STYLE_FX` |
| Громовая волна (thunderwave) | кольцо сжатого воздуха | `expanding shockwave ring of pale blue distorted air on the ground, 192x96, STYLE_FX` |
| Палящий луч (scorching_ray) | три тонких огненных луча | `thin straight beam of searing orange fire, 64x16, STYLE_FX` |
| Огненный шар (fireball) | бусина + взрыв 3×3 | `huge fireball explosion on the ground, orange and yellow flames with black smoke, 192x128, STYLE_FX` |
| Освящённая земля (hallowed_ground) | светящийся круг рун, держится | `glowing circle of golden holy runes on the ground, looping, 192x96, STYLE_FX` |
| Щит веры (shield_of_faith) | купол у союзника | `faint translucent golden shield dome around a character, 64x64, STYLE_FX` |
| Направляющий снаряд (guiding_bolt) | луч света + метка на цели | `bolt of bright white-blue light, 32x16, STYLE_FX`; метка: `glowing marker sigil hovering above a target, 32x32, STYLE_FX` |
| Изгнание нежити (turn_undead) | вспышка символа | `burst of holy light from a raised candle-flame symbol, rays outward, 192x96, STYLE_FX` |
| Духовное оружие (spiritual_weapon) | призрачная булава | `spectral floating mace made of pale golden light, 64x64, STYLE_FX` |
| Духовные стражи (spirit_guardians) | кружащие духи вокруг жреца | `ring of translucent spectral guardian spirits circling around a character, looping, 192x96, STYLE_FX` |
| Сохранение жизни (preserve_life) | золотые нити к союзникам | `golden threads of light streaming outward, 192x96, STYLE_FX` |
| Жир (grease) | лужа на 3×3 | `slick yellow-brown grease puddle on stone floor, isometric, 192x96, STYLE_FX` |
| Паутина (web) | паутина на 3×3 | `thick white magical spider web covering the floor, isometric, 192x96, STYLE_FX` |
| Каменные шипы (spike_growth) | шипы из камня на 5×5 | `sharp stone spikes jutting from the floor, isometric, 64x32 tile, STYLE_FX` (тайл повторяется по клеткам) |
| Замедление (slow) | синие песочные искры | `slow time aura, drifting pale blue hourglass sand particles around a character, 64x64, STYLE_FX` |
| Второе дыхание (second_wind) | тёплая вспышка | `quick warm green-gold burst of renewed vigor, 64x64, STYLE_FX` |
| Всплеск действий (action_surge) | рывок силуэта | `afterimage burst, sharp white speed lines, 64x64, STYLE_FX` |
| Ярость (rage) | красная аура | `pulsing dark-red rage aura with steam, looping, 64x64, STYLE_FX` |
| Провокация (taunt) | красный восклицательный знак, волна | `red shouting shockwave ripple, 128x64, STYLE_FX` |
| Сбить с ног (trip), Толчок (shove) | пыль удара | `small dust puff impact on the ground, 64x32, STYLE_FX` |
| Спрятаться (hide) | дым, силуэт тает | `thin grey smoke wisps dissolving, 64x64, STYLE_FX` |
| Яд на клинке (poison_blade) | зелёные капли на оружии | `dripping toxic green poison droplets, 32x32, STYLE_FX` |
| Рывок (dash), Отход (disengage), Уклонение (dodge) | линии скорости, пыль | `dust trail behind running feet, 64x32, STYLE_FX` |
| Выстрел из лука (shoot) | стрела | `single wooden arrow in flight, 16x16, STYLE_FX` |
| Веер кинжалов (knife_fan) | веер клинков | `fan of spinning throwing knives, 32x16, STYLE_FX` |
| Алхимическая бомба (bomb) | склянка + взрыв | `small glass alchemical flask with green liquid, 16x16, STYLE_FX`; взрыв: `alchemical explosion with green-yellow fire and glass shards, 192x96, STYLE_FX` |
| Ловушка (trap) | капкан на клетке | `isometric iron bear trap with a tripwire, 32x32, STYLE_ISO` |

### 5.2. Тёмные дары

Единый язык для всей некромантии и Тьмы: чёрно-фиолетовый дым с бледно-зелёными искрами. Тот же язык у послушника и Бледного Короля, чтобы игрок узнавал «чужую» силу в своих руках.

| Умение | Промпт |
|---|---|
| Проклятый клинок (cursed_blade) | `weapon wreathed in black-violet necrotic smoke with pale green sparks, slash trail, 64x64, STYLE_FX` |
| Шаг в тень (shadow_step) | `character dissolves into black-violet shadow smoke and reappears, 64x64, STYLE_FX` |
| Иссушение (wither) | `tendrils of black-violet necrotic energy wrapping a target, withering, 64x64, STYLE_FX` |
| Высасывание жизни (life_drain) | `stream of red life essence pulled from a target into the caster, pale green sparks, 128x32, STYLE_FX` |
| Луч болезни (послушник) | `sickly green necrotic ray, 64x16, STYLE_FX` |

### 5.3. Общие эффекты боя

```
hit spark (оружие): small white-yellow impact spark, 32x32, STYLE_FX
critical hit: larger red-white impact burst with star shape, 48x48, STYLE_FX
miss: small grey whoosh arc, 32x32, STYLE_FX
blood hit (живые): small dark-red splatter, minimal, 32x32, STYLE_FX
bone hit (нежить): bone chips and dust burst, 32x32, STYLE_FX
undead death: pile of bones collapsing into dust with a fading cold blue wisp, 64x64, STYLE_FX
paralysis (гуль): pale yellow stiffening sparks around a character, 64x64, STYLE_FX
spike damage: small stone shards burst, 32x32, STYLE_FX
```

---

## 6. Иконки

### 6.1. Умения (32×32)

Retro Diffusion, стиль `skill_icon`, лист 4×4 на 128×128 или по одной. Общий хвост:

**STYLE_ICON:**
```
pixel art skill icon, 32x32, dark fantasy, centered symbol on a dark stone square background with a thin bevel border, bold readable silhouette, limited palette
```

Рамка по типу ресурса (рисуется отдельно, один раз): бронзовая — без ограничений, серебряная — ячейка заклинания, синяя — «раз за бой», чёрно-фиолетовая — тёмный дар.

| Id | Символ |
|---|---|
| move_attack (Движение и атака) | `a boot print and a crossed sword` |
| end_turn (Конец хода) | `an hourglass` |
| dodge | `a cloak swirling aside` |
| shove | `an open palm pushing` |
| second_wind | `a green-gold breath of air over a heart` |
| disengage | `a footstep moving backward with an arrow` |
| action_surge | `a lightning-struck sword` |
| rage | `a roaring red face mask` |
| reckless | `a cracked shield with a sword through it` |
| trip | `a boot sweeping a leg` |
| taunt | `a shouting mouth with red sound waves` |
| hide | `a hooded eye half in shadow` |
| poison_blade | `a dagger dripping green poison` |
| shoot | `a drawn bow with an arrow` |
| dash | `a winged boot` |
| knife_fan | `a fan of three throwing knives` |
| bomb | `a round alchemical flask with a lit fuse` |
| trap | `an iron bear trap` |
| sacred_flame | `a white-gold flame pillar` |
| healing_word | `a glowing golden word sigil over an open hand` |
| mass_healing_word | `three golden sigils in a circle` |
| hallowed_ground | `a golden rune circle on stone` |
| shield_of_faith | `a golden shield with a candle-flame emblem` |
| guiding_bolt | `a white-blue bolt striking a target mark` |
| turn_undead | `a raised candle-flame symbol repelling a skull` |
| spiritual_weapon | `a ghostly floating mace` |
| spirit_guardians | `three spectral spirits circling` |
| preserve_life | `a heart bound by golden threads` |
| fire_bolt | `a small fire bolt` |
| magic_missile | `three violet darts` |
| thunderwave | `a blue shockwave ring` |
| scorching_ray | `three orange fire rays` |
| fireball | `a large fireball` |
| grease | `a slick yellow puddle with a slipping foot` |
| web | `a white spider web` |
| spike_growth | `stone spikes rising from the ground` |
| slow | `a blue hourglass with drifting sand` |
| cursed_blade | `a sword wreathed in black-violet smoke` |
| shadow_step | `a footprint dissolving into shadow` |
| wither | `a withering black-violet hand` |
| life_drain | `a red stream flowing from a skull into an open hand` |

Промпт: `{символ}, STYLE_ICON`.

### 6.2. Значки состояний (12×12)

Генерировать листом 64×64 в RD (`ui_element`), потом чистить вручную: при 12 px ручная работа быстрее.

| Состояние в прототипе | Символ |
|---|---|
| уклон (dodging) | серый плащ-вихрь |
| бежит (turned) | белый символ-пламя с убегающей стрелкой |
| метка (guided_by) | бело-синий прицел |
| медл. (slowed) | синие песочные часы |
| опутан (restrained) | белая паутина |
| паралич (stunned) | жёлтая молния-звезда |
| ярость (raging) | красная маска |
| яд (poisoned) | зелёная капля |
| +2 КД (ac_bonus) | маленький золотой щит |
| провокация (taunted_by) | красный «!» |
| сбит с ног (prone) | ботинок вверх подошвой |
| скрыт (hidden) | полузакрытый глаз |

```
sheet of tiny 12x12 pixel art status effect icons on a 4x4 grid: {список символов}, dark fantasy, bold simple shapes, 1px dark outline, transparent background
```

### 6.3. Предметы (32×32)

Retro Diffusion, стиль `item_sheet` (лист из нескольких предметов) или `topdown_item` (по одному). Цвет фона за иконкой задаёт ступень, а не генерация: обычное — серый, добротное — зелёный, редкое — синий, легендарное — золотой, тёмное — фиолетовая кайма.

**STYLE_ITEM:**
```
pixel art inventory item icon, 32x32, dark fantasy, single object centered at a slight diagonal, 1px dark outline, medium shading, warm light from upper left, transparent background
```

| Предмет | Описание для промпта |
|---|---|
| Меч стражи ворот | `a plain steel longsword with a leather-wrapped grip and an iron crossguard` |
| Жало следопыта | `a slim short sword with a grey leather grip and a scout's notch on the blade` |
| Рудничный двуручник | `a crude heavy two-handed sword forged from mine iron, rough edges` |
| Лук охотника из Эшмура | `a simple yew shortbow with a green string wrap` |
| Булава причетника | `a wooden-handled iron mace with a small brass candle emblem` |
| Оружие из мастерских Короля | `a black steel weapon stamped with a crown-in-circle emblem` (варианты: меч, двуручник, короткий меч, лук, булава, посох) |
| Тесак Эшмура | `a broad village cleaver-sword with a hand-forged pattern` |
| Серебряный лук контрабандистов | `a recurve bow with silver-inlaid limbs` |
| Клык архивариуса | `a dwarven short sword with a fang-shaped blade and runes` |
| Молот-кадило Молчащих | `a dwarven bronze war hammer with a censer cage in the head, faint smoke` |
| Клинок эльдмарской гвардии | `an ornate royal guard longsword with a faded blue-gold hilt` |
| Булава литейной | `a heavy foundry mace of cast black iron with glowing seams` |
| ☾ Чёрная сталь | `a matte black blade leaking violet smoke` |
| Кольчуга надсмотрщика | `a chainmail shirt with a torn black tabard` |
| Кожанка разведчика | `a dark leather scout jerkin` |
| Мантия с оберегами | `a dark robe with small stitched protective charms` |
| Куртка контрабандиста | `an oiled leather jacket with many pockets` |
| Кольчуга деревенской кузни | `a hand-forged chainmail hauberk with uneven rings` |
| Плащ подводного хода | `a waxed dark-green cloak, dripping water` |
| Доспех Молчащих | `ancient dwarven plate armor with engraved runes` (варианты по классу: латы, кожаный доспех, мантия) |
| Плащ литейщика | `a heavy soot-stained leather foundry cloak` |
| Латы литейной | `thick black iron plate armor with rivets` |
| ☾ Саван утопленника | `a pale wet burial shroud with weeds, violet glow` |
| Чётки храма Эшмура | `wooden prayer beads with a small candle-flame pendant` |
| Жетон десятника | `a round iron overseer token on a cord` |
| Оберег рудокопа | `a lump of ore on a leather string` |
| Дварфийский оберег | `a bronze dwarven amulet with a geometric rune` |
| Печать мастера | `an iron signet seal with a hammer emblem` |
| Сердце горна | `a glowing orange ember crystal in an iron cage pendant` |
| ☾ Костяной фокус | `a carved bone wand-focus with violet runes` |
| Клятва Молчащих (Л) | `a legendary dwarven greatsword with gold rune inlay and a hooded-face pommel` |
| Шёпот Молчащих (Л) | `a legendary dwarven short blade, dark bronze, faint silver whisper glow` |
| Светильник Молчащих (Л) | `a legendary dwarven bronze lamp amulet with a steady white flame` |
| Посох Молчащих (Л) | `a legendary dwarven staff of dark stone with a gold rune head` |
| Бирка жены (Л) | `a small tin miner's tag on a string with a scratched name` |
| Колокол разрушенного храма (Л) | `a small cracked bronze temple bell` |
| Кинжал с короной (Л) | `a fine dagger with a crown-in-circle pommel` |
| Венец Молчащих (Л) | `a simple dwarven bronze circlet with a single rune` |
| Тенекожа (Л) | `a supple black leather armor that seems to swallow light` |
| ☾ Перстень Бледного Короля (Л) | `a pale bone-white ring with a tiny crown and a violet gem` |
| Фонарь первого штейгера (Л) | `an old brass miner's lantern with a warm steady light` |
| Острога затопленного святилища (Л) | `a barbed fishing spear of silver-blue metal with weeds` |
| Цепь Безымянных (Л) | `a chain of mismatched iron links, each scratched with a mark` |
| Печать совета (Л) | `a royal wax seal with a broken ribbon and an old council emblem` |
| Зелье лечения | `a small round red potion bottle with a cork` |
| Большое зелье | `a large red potion flask with a wax seal` |
| Масло против нежити | `a vial of silver-white oil` |
| Свиток щита веры | `a rolled scroll with a golden shield seal` |
| Свиток громовой волны | `a rolled scroll with a blue wave seal` |
| Дварфийский эль | `a stone dwarven ale mug with foam` |
| Соль-оберег | `a small cloth pouch spilling white salt` |
| ☾ Кровавый эликсир | `a dark red elixir vial with violet glow` |
| Слиток дварфийской стали | `a blue-grey metal ingot with a rune stamp` |
| Серебро | `a small pile of silver coins` |

---

## 7. Интерфейс боя

Retro Diffusion `ui_element`, `remove_bg`. Хвост:

**STYLE_UI:**
```
pixel art game UI element, dark fantasy, weathered dark iron and old stone with thin bronze trim, muted palette, clean edges for 9-slice scaling, no text
```

```
Панель (9-slice): a rectangular UI panel frame, dark iron border with rivets at the corners, dark stone interior, 48x48, STYLE_UI
Кнопка (норма/наведение/нажата/недоступна): a rectangular button, dark iron frame, 3 states side by side: normal, highlighted with warm bronze glow, pressed, 96x32 each, STYLE_UI
Слот иконки умения: a square slot frame for a 32x32 icon, iron border, 40x40, STYLE_UI
Полоса хитов: a horizontal health bar frame in iron with an empty dark interior, 64x8, STYLE_UI (заливку красим в коде)
Рамка портрета: a square portrait frame in iron and bronze, 72x72, STYLE_UI
Рамка активного: same portrait frame with a warm golden glow, 72x72, STYLE_UI
Индикатор Тьмы: a small round vessel of dark glass with black-violet smoke inside, 4 states from almost empty to full, 32x32 each, STYLE_UI
Курсор: a pixel art mouse cursor shaped like an iron gauntlet pointer, 16x16, STYLE_UI
Курсор атаки: a small crossed-swords cursor, 16x16, STYLE_UI
Курсор заклинания: a small glowing rune cursor, 16x16, STYLE_UI
Фон меню: dark mine tunnel descending into blackness, faint torchlight at the top, pixel art background, 384x216, isometric pixel art
```

Шрифты не генерируем: подбираем готовые с кириллицей под OFL/CC0 (DESIGN.md, раздел 4).

---

## 8. Портреты

По DESIGN.md: универсальная модель (Midjourney, GPT Image, Flux) → пикселизация → чистка в Aseprite. Схема проверена на портрете волшебника (срез стека, 2026-10-12): Midjourney, 1254 px → [`art/tools/portrait.py`](tools/portrait.py) → 128×128 и 64×64 в Resurrect 64 → Aseprite. Порядок работы, список портретов к демо и состояние каждого — [art/portraits/README.md](portraits/README.md).

### 8.1. Правила кадра (одинаковые для всех портретов)

Портреты одного размера стоят в одной рамке интерфейса и в одной панели диалога, а слои Тьмы и повязка травмы ложатся по координатам лица. Поэтому кадр у всех один, как у волшебника:

- погрудный портрет, лицо повёрнуто на три четверти **вправо** (персонаж смотрит в сторону текста диалога);
- голова в верхней половине кадра, глаза примерно на трети высоты сверху, макушка почти касается верхнего края;
- плечи уходят за нижний край, руки и оружие в кадр не попадают, кроме верхушки посоха у края;
- **ровный однотонный фон**: скрипт отделяет фигуру по цвету фона. У волшебника фон тёмный и сливается с волосами, поэтому там фон чистится руками;
- квадрат 1:1, не меньше 1024 px.

### 8.2. Хвост промпта и параметры

**STYLE_PORTRAIT** (обновлён 2026-10-12: ровный фон и правила кадра):
```
bust portrait, head and shoulders, face turned three-quarters to the right, eyes at one third from the top of the frame, dark fantasy, painterly but simple shapes, flat color areas, strong rim light from the upper left torchlight, cool shadows, muted desaturated palette, plain flat dusty teal background with no gradient and no scenery, no hands, no text, designed to be converted to 128x128 pixel art
```

**Midjourney** (так делался волшебник): в конце каждого промпта
```
--ar 1:1 --v 7 --style raw --sref <ссылка на портрет волшебника> --sw 150
```
`--sref` с портретом волшебника держит одну манеру у всех персонажей. Ссылку на картинку волшебника можно скопировать в Midjourney (правый клик → Copy image address) или загрузить `art/portraits/source/hero_wizard_m.png` как Style Reference. Если персонаж начинает походить на волшебника лицом, снизить `--sw` до 80–100.

**Если Midjourney нет:** Flux или GPT Image с тем же промптом; в GPT Image приложить портрет волшебника и написать «in the same painting style as the attached image, different person».

### 8.3. Эмоции

Эмоция — не новая генерация, а **правка лица в той же картинке**, иначе голова сдвинется и слои Тьмы не лягут. В Midjourney: открыть утверждённый нейтральный портрет → **Editor** (или **Vary Region**) → выделить только лицо от бровей до подбородка → в промпте заменить описание эмоции. Всё остальное (волосы, одежда, кадр) не трогать.

Эмоции берутся из тегов `# mood:` в Ink: что стоит в тексте, то и рисуем. В прологе встречаются:

| Тег | Добавка к промпту |
|---|---|
| без тега (нейтрально) | `calm neutral expression, steady gaze` |
| `smile` | `a faint warm smile, softened eyes` |
| `sad` | `sad expression, brows drawn up, eyes lowered, lips pressed together` |
| `tense` | `tense expression, brows drawn together, jaw clenched, wary eyes` |
| `away` | `looking away and down, avoiding eye contact, head slightly lowered` |

Эмоции глав 1–5 из таблицы DESIGN.md (гнев, стыд, страх, вина, ирония) добавляются, когда до них дойдёт очередь, той же правкой лица.

### 8.4. Промпты персонажей

Каждый промпт = описание + эмоция из 8.3 + STYLE_PORTRAIT + параметры Midjourney. Внешность совпадает со спрайтами первой волны (`art/wave1/characters/*/rotations/`): у кого спрайт уже есть, цвет волос и одежды взяты с него.

**Герой.** В прологе у героя первый уровень и ещё нет ветки, поэтому портрет показывает класс, а не ветку; акцент холодный синий у всех. Каждый класс в двух вариантах: `man` / `woman`.
```
Волшебник: bust portrait of a {man|woman} in {his|her} early thirties, village scholar turned wizard, long dark-blue robe with burned singed edges, hood down, dark hair, {short beard|hair tied back with loose strands}, tired intelligent eyes, leather satchel strap across the chest, the ember-glowing crystal top of a quarterstaff at the left edge of the frame
Воин: bust portrait of a {man|woman} in {his|her} early thirties, villager who once served as a soldier, dented steel breastplate over a padded gambeson, short dark-blue cloak pinned at the shoulder, short brown hair, {stubble|hair cut short at the neck}, a pale old scar through one eyebrow, determined eyes
Плут: bust portrait of a lean {man|woman} in {his|her} early thirties, dark leather armor with the hood down, dark-blue hood lining, a dark face scarf pulled down around the neck, short dark hair, narrow wary eyes, a thin scar at the corner of the mouth, the hilts of throwing knives on a chest strap
Жрец: bust portrait of a {man|woman} in {his|her} early thirties, village priest, grey-white vestments over a chainmail shirt, dark-blue stole over the shoulders, a small wooden candle-flame pendant on a cord, {close-cropped hair|hair under a simple grey head scarf}, calm tired kind face
```

**Спутники.**
```
Ирена: bust portrait of a young woman in her mid twenties, priestess of a ruined village temple, soot-stained pale grey habit with the hood down, chain shirt underneath, dark hair in a single braid over the shoulder, wooden prayer beads, thin pale gold embroidery at the collar, soot on one cheek, grieving but steady eyes
Гаррет: bust portrait of a big broad-shouldered man in his late forties, deserter mine overseer, heavy chainmail under a black overseer tabard with a torn pale patch where a badge was ripped off, short grey hair and a short grey beard, weathered face, once-broken nose, rust-orange scarf, heavy-lidded tired eyes
Велиор: bust portrait of a lean wiry man in his thirties, scout and former royal agent, grey hooded cloak with no insignia, hood up but the face fully visible, swamp-green inner lining, dark leather armor, sharp pale face, a crown branded into the cheek facing the viewer and crossed out by a deep knife scar, watchful ironic eyes
```
У Велиора клеймо рисуется на щеке, обращённой к зрителю: в тексте сторона не названа.

**Супруг героя** (вводит игрок, по умолчанию Эйла или Эйвин). Главное лицо сцены 1 пролога и финала: в прологе 27 реплик и все пять эмоций из 8.3.
```
Эйла: bust portrait of a woman in her early thirties, villager, plain homespun dress with a dark wool shawl over the shoulders, chestnut hair loosely pinned up with strands falling, kind tired face, gentle eyes that hold a hidden sorrow
Эйвин: bust portrait of a man in his early thirties, villager, plain linen shirt with a dark wool vest, short chestnut hair, short beard, kind tired face, gentle eyes that hold a hidden sorrow
```

**Второстепенные лица пролога** (один портрет, у Олдрика ещё `sad`).
```
Брандт: bust portrait of a tall man in his fifties, overseer captain, chain shirt under a long black coat with dull red trim, a silver crown-in-circle badge on the chest, grey hair combed back, clean-shaven, thin lips, cold tired eyes
Олдрик: bust portrait of an old man in his seventies, village survivor, soot-stained face, white stubble, wool cap, worn sheepskin vest, red-rimmed wet eyes
```

### 8.5. Портреты героя по Тьме и травма

Тьма на портрете — композит, а не новые картинки (DESIGN.md, раздел 4): один базовый портрет, три накопительных слоя (Сумрак — тени под глазами; Мрак — вены у висков и тёмная радужка; Бездна — прожилки и бледно-зелёный отблеск глаз) и шейдер, который бледнит четыре тона кожи. Слои рисует `art/tools/portrait.py` по координатам лица из `art/portraits/portraits.json`, затем они дочищаются в Aseprite. Сборка в игре — `prototypes/stack-slice/scripts/portrait/dark_portrait.gd`.

**В демо слои не видны:** за пролог Тьма набирает не больше 20 (DESIGN.md, таблица Тьмы), а Сумрак начинается с 25. Слои нужны к главе 1; сейчас их достаточно у волшебника как образца. Условие, которое важно уже сейчас: у всех эмоций одной внешности лицо стоит на тех же пикселях (8.3).

Повязка травмы («Испытание», DESIGN.md, раздел 3) — такой же слой поверх базового портрета, один на внешность; рисуется в Aseprite по тем же координатам лица.

---

## 9. Чистка и импорт в Godot

**Aseprite, для каждого ассета:**
1. Перевести в Indexed по утверждённой палитре, убрать «почти одинаковые» цвета.
2. Удалить одиночные мусорные пиксели и полупрозрачные пиксели на краях (альфа только 0 или 255, кроме эффектов).
3. Контур перекрасить в тёмный цвет палитры, проверить, что он сплошной.
4. Персонажи: выставить точку опоры (ноги) в одну и ту же точку холста во всех кадрах и направлениях, проверить, что анимации не «плывут». Оружие и доспех на отдельных слоях.
5. Тайлы: проверить края ромба на стыке 3×3 копий, без светлых швов.
6. Экспорт: спрайт-лист PNG + JSON (Aseprite «Export Sprite Sheet», Packed, с тегами анимаций).

**Godot 4 (прототип):**
- Project Settings → Rendering → Textures → Default Texture Filter: **Nearest**.
- TileSet: Tile Shape Isometric, Tile Size 64×32, layout Diamond (Right или Down: выбрать тот, при котором координаты совпадают с `BoardView.cell_to_world()`, где +x идёт вниз-вправо, +y вниз-влево); препятствия — отдельный слой TileMapLayer с Y-sort, или отдельные Sprite2D, как сейчас сортировка по `x + y` в `board_view.gd`.
- Персонажи: AnimatedSprite2D, offset так, чтобы точка опоры (32, 56) совпала с центром клетки `BoardView.cell_to_world()`.
- Зум камеры целыми шагами, иначе пиксели будут разной ширины.
- Подсветки клеток (раздел 3.6) остаются отрисовкой в коде или отдельным TileMapLayer поверх пола.
- Большие файлы графики под Git LFS (DESIGN.md, раздел 2).

---

## 10. Дальше прототипа (по сюжету, вне текущих 5 боёв)

Короткие промпты, чтобы список был полным, когда дойдёт очередь. Пролог (деревня, храм, брод, его персонажи) перенесён в разделы 3.7 и 4.5.

```
Дно, глава 5: isometric floor tile of black glassy stone with faint violet veins, cold silence, STYLE_ISO; isometric enormous circular seal stone with dwarven runes and a crack, center piece 192x96, STYLE_ISO
Контрабандист Ренны Сол: a human smuggler in an oiled leather coat, hooked knife, lantern, STYLE_CHAR
Страж-конструкт Молчащих: a dwarven stone-and-bronze guardian construct, hooded statue face with a finger to its lips, glowing rune core, 96x96, STYLE_CHAR
Мастер плоти: a human flesh master in a leather apron and a bone mask, surgical hooks, STYLE_CHAR
Бледный Король (Эдрик): a tall gaunt old human archmage-king, pale skin, simple iron crown, worn ceremonial robe of a former royal court mage, an old order medal on the chest, sorrowful calm face, black-violet smoke at the hands, 64x64 or 96x96, STYLE_CHAR
Лиара (видения): a translucent woman in a simple white dress, pale glowing outline, sad calm face, ghostly, STYLE_CHAR
```

---

## 11. Объём первой волны (для оценки)

| Группа | Состав | Картинок или кадров примерно |
|---|---|---|
| Тайлсет Верхних шахт | 4 пола + край + 5 препятствий + 3 декора | 13 |
| Отряд: герой-волшебник ×2, Ирена, Гаррет, Велиор | 5 персонажей × 2 направления × 6–7 анимаций | ~550 |
| Враги уровней 1–2 | 5 × 2 направления × 5 анимаций | ~250 |
| Эффекты | 10 | ~60 |
| Иконки умений отряда и волшебника | ~20 | 20 |
| Значки состояний | 12 | 12 |
| Интерфейс | ~10 элементов | 10 |

Сервисы считают генерации по-разному; перед покупкой тарифа проверить, что он даёт коммерческие права (DESIGN.md, раздел 4).
