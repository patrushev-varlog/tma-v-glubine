# Авторы и лицензии

Всё, что входит в сборку игры и сделано не нами, с лицензией и ссылкой на источник. Список нужен для
титров, страницы Steam и проверки перед каждой сборкой демо (DESIGN.md, раздел 8, «Звук»).

## Движок и библиотеки

| Что | Автор | Лицензия |
|---|---|---|
| Godot Engine 4.7 (.NET) | Juan Linietsky, Ariel Manzur и участники проекта Godot | MIT |
| GodotInk (`addons/GodotInk`) | Paul Joannon | MIT, `addons/GodotInk/LICENSE` |
| ink, рантайм | inkle Ltd | MIT |
| GUT (`addons/gut`, только тесты, в сборку не входит) | Tom «Butch» Wesley | MIT, `addons/gut/LICENSE.md` |

## Шрифты

| Шрифт | Автор | Лицензия |
|---|---|---|
| Literata (текст) | The Literata Project Authors (github.com/googlefonts/literata) | SIL OFL 1.1, `fonts/OFL-literata.txt` |
| Tiny5 (заголовки) | The Tiny5 Project Authors (github.com/Gissio/font_tiny5) | SIL OFL 1.1, `fonts/OFL-tiny5.txt` |

## Графика

Портреты, тайлы и спрайты сделаны генераторами (Midjourney, PixelLab, Retro Diffusion) и дочищены вручную
(art/PROMPTS.md). В анкете Steam это указывается в декларации ИИ.

## Музыка и звук

Звуки, шумы и треки демо — бесплатные паки с правом на коммерческое использование: CC0 (указывать не обязательно,
но указываем) и CC-BY / OGA-BY (указывать обязательно, в титрах и на странице Steam). Файлы собраны из них
скриптом `tools/audio_build.py` (обрезка, громкость, склейка шумов в петли); по каждому файлу — `audio/LICENSES.md`.

<!-- звук: собирается tools/audio_build.py -->

| Что | Автор | Лицензия | Источник |
|---|---|---|---|
| Fantasy SFX Pack Vol 1 (`sfx/arrow_hit`, `sfx/bow_shot`, `sfx/cast_fire`, `sfx/hit_arcane`, `sfx/hit_fire`, `sfx/ward`) | JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 |
| Nature Ambient Pack Vol 1 (`ambient/ashes_wind`, `ambient/camp`, `ambient/raid_night`, `ambient/rain`, `ambient/stream`) | JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1 |
| 8 Heals and Buffs SFX (`sfx/cast_holy`, `sfx/heal`, `sfx/hit_dark`, `sfx/ward`) | leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-heals-and-buffs-sfx |
| 8 Magic Attacks (`sfx/cast_arcane`, `sfx/explosion`, `sfx/hit_dark`, `sfx/thorns`, `sfx/thunder`) | leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-magic-attacks |
| Fantasy Sound Effects Library (`sfx/dash`, `sfx/defeat`, `sfx/step_mud`, `sfx/trap`, `sfx/victory`) | Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library |
| Horror Sound Effects Library (`sfx/hit_blade`, `sfx/hit_bone`) | Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/horror-sound-effects-library |
| Dark Descent (`music/dread`) | Matthew Pablo (www.matthewpablo.com) | CC-BY 3.0 | https://opengameart.org/content/dark-descent |
| Magic Smite (`sfx/hit_holy`) | spookymodem | CC-BY 3.0 | https://opengameart.org/content/magic-smite |
| Fleshy Fight Sounds (`sfx/hit_blade`, `sfx/hit_blunt`, `sfx/hit_claw`) | will_leamon | OGA-BY 3.0 | https://opengameart.org/content/fleshy-fight-sounds |
| Fight Them Until We Can't (`music/battle`) | Zander Noriega | CC-BY 3.0 | https://opengameart.org/content/fight-them-until-we-cant |
| Zombie / Skeleton / Monster Voice Effects (`sfx/shout`, `sfx/undead_death`) | ArcadeParty | CC0 | https://opengameart.org/content/zombie-skeleton-monster-voice-effects |
| Swishes Sound Pack (`sfx/miss`, `sfx/throw`, `sfx/whip`) | artisticdude | CC0 | https://opengameart.org/content/swishes-sound-pack |
| Zombies Sound Pack (`sfx/undead_groan`) | artisticdude | CC0 | https://opengameart.org/content/zombies-sound-pack |
| Bones rattle (`sfx/bones_collapse`) | congusbongus | CC0 | https://opengameart.org/content/bones-rattle |
| Loopable Dungeon Ambience (`ambient/temple`) | JaggedStone | CC0 | https://opengameart.org/content/loopable-dungeon-ambience |
| Impact Sounds (`sfx/body_fall`, `sfx/handbell`, `sfx/step_grass`, `sfx/step_stone`) | Kenney | CC0 | https://kenney.nl/assets/impact-sounds |
| RPG Audio (`sfx/book`, `sfx/cloth`, `sfx/coin`, `sfx/journal`, `sfx/page_turn`, `sfx/pickup`, …) | Kenney | CC0 | https://kenney.nl/assets/rpg-audio |
| UI Audio (`sfx/ui_click`, `sfx/ui_hover`) | Kenney | CC0 | https://kenney.nl/assets/ui-audio |
| wind1 (`ambient/ashes_wind`) | Luke.RUSTLTD | CC0 | https://opengameart.org/content/wind1 |
| Medieval sound effects - Weapon Textures (`sfx/bow_shot`, `sfx/crossbow_shot`, `sfx/swing`) | MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures |
| 3 dark magic spells (`sfx/cast_dark`) | qubodup | CC0 | https://opengameart.org/content/3-dark-magic-spells |
| Dripping water loop (`ambient/rain`) | qubodup | CC0 | https://opengameart.org/content/dripping-water-loop |
| Fantasy: Lament for a Warrior's Soul (`music/home`) | RandomMind | CC0 | https://opengameart.org/content/fantasy-lament-for-a-warriors-soul |
| 40 CC0 water / splash / slime SFX (`sfx/goo`) | rubberduck | CC0 | https://opengameart.org/content/40-cc0-water-splash-slime-sfx |
| Cure Magic (`sfx/heal`) | Someoneman | CC0 | https://opengameart.org/content/cure-magic |
| Crowd Shouting/Speaking Ambience (`ambient/raid_night`) | StarNinjas | CC0 | https://opengameart.org/content/crowd-shoutingspeaking-ambience |
| Their Coming (generic horn sound) (`sfx/spawn`) | StumpyStrust | CC0 | https://opengameart.org/content/their-coming-generic-horn-sound |
| Колокол часовни (`sfx/bell_far`, `sfx/bell_chapel`) | синтез, tools/audio_build.py | наш | — |
