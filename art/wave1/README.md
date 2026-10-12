# Первая волна арта — рабочие файлы

Состояние на 2026-10-12. Схема анимированного персонажа утверждена на Гаррете (PROMPTS.md, раздел 2a).

## Гаррет
- `characters/garret/base_v3/` — единая основа (v3 из стойки лицом к камере), `rotations/` 8 направлений, `animations/` — пробы режимов (skeleton-v3, v3 по описанию). Основа утверждена.
- `characters/garret/unarmed/` — **утверждённый набор**: `rotations/` тело без меча (щит на теле), `sword.png` меч отдельным спрайтом, `animations/` тело (idle, walk, hit, down, attack по скелету), `composited2/` кадры с мечом — результат схемы. `skeletons2.json` — точки скелета по кадрам.
- `characters/garret/states/`, `animations_v2/`, `animations_unified/`, `bare/`, `_rejected_*` — отбракованные пробы: состояния-позы, template-режим, перенос облика, щит отдельным спрайтом. Хранятся для истории, в игру не идут.
- `previews/garret_v3.html` — страница сравнения всех вариантов.

## Остальные персонажи
`characters/<имя>/rotations/` — основы в режиме pro со стилем Гаррета (утверждены). Анимации по схеме 2a генерируются конвейером; результат — `characters/<имя>/composited/`.

## Тайлы, иконки, интерфейс
`tiles/upper_mines/` — тайлсет Верхних шахт (часть объектов ждёт переделки, см. manifest.json). `icons/`, `ui/` — черновики Retro Diffusion. `manifest.json` — журнал генераций с id PixelLab.
