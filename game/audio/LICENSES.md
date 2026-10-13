# Лицензии звука

Каждый файл в `audio/` — строка в этой таблице, в том же PR, где появляется файл (art/prologue/ASSETS.md,
раздел 7). Подходят CC0, CC-BY (автор — в `CREDITS.md`) и купленные лицензии с правом на платную игру и
трейлер. NC не подходят.

Что куда класть (игра подхватывает файл сама, по `data/audio.json`):

| Папка | Что | Имена, которых ждёт игра |
|---|---|---|
| `music/` | треки, OGG Vorbis, зацикливаются | `home` (дом, меню), `battle` (бои), `dread` (тревога: храм, колонна, допрос, конец демо) |
| `ambient/` | петли окружения, OGG Vorbis | `rain`, `raid_night`, `ashes_wind`, `temple`, `stream`, `camp` |
| `sfx/` | короткие звуки, OGG Vorbis; `<id>_1`, `<id>_2`… — варианты, игра берёт случайный | таблицы `sfx` в `data/audio.json`, теги `# sfx:<id>` в Ink |

Все файлы собирает `tools/audio_build.py` из паков ниже: качает, режет, выравнивает громкость, шумы склеивает в
минутные петли. Поменять звук — поправить строку в скрипте и пересобрать; таблица ниже и раздел «Музыка и звук»
в `CREDITS.md` пишутся тем же скриптом. OGA-BY 3.0 — вариант CC-BY 3.0 от OpenGameArt без запрета на DRM:
для Steam подходит, автор указывается так же.

<!-- таблица ниже собирается tools/audio_build.py -->

| Файл | Название и автор | Лицензия | Источник | Дата |
|---|---|---|---|---|
| `ambient/ashes_wind.ogg` | [wind1](https://opengameart.org/content/wind1), Luke.RUSTLTD; [Nature Ambient Pack Vol 1](https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1), JC Sounds | CC-BY 4.0, CC0 | https://opengameart.org/content/wind1, https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1 | 2026-10-13 |
| `ambient/camp.ogg` | [Nature Ambient Pack Vol 1](https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1 | 2026-10-13 |
| `ambient/raid_night.ogg` | [Nature Ambient Pack Vol 1](https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1), JC Sounds; [Crowd Shouting/Speaking Ambience](https://opengameart.org/content/crowd-shoutingspeaking-ambience), StarNinjas | CC-BY 4.0, CC0 | https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1, https://opengameart.org/content/crowd-shoutingspeaking-ambience | 2026-10-13 |
| `ambient/rain.ogg` | [Nature Ambient Pack Vol 1](https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1), JC Sounds; [Dripping water loop](https://opengameart.org/content/dripping-water-loop), qubodup | CC-BY 4.0, CC0 | https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1, https://opengameart.org/content/dripping-water-loop | 2026-10-13 |
| `ambient/stream.ogg` | [Nature Ambient Pack Vol 1](https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1 | 2026-10-13 |
| `ambient/temple.ogg` | [Loopable Dungeon Ambience](https://opengameart.org/content/loopable-dungeon-ambience), JaggedStone | CC0 | https://opengameart.org/content/loopable-dungeon-ambience | 2026-10-13 |
| `music/battle.ogg` | [Fight Them Until We Can't](https://opengameart.org/content/fight-them-until-we-cant), Zander Noriega | CC-BY 3.0 | https://opengameart.org/content/fight-them-until-we-cant | 2026-10-13 |
| `music/dread.ogg` | [Dark Descent](https://opengameart.org/content/dark-descent), Matthew Pablo (www.matthewpablo.com) | CC-BY 3.0 | https://opengameart.org/content/dark-descent | 2026-10-13 |
| `music/home.ogg` | [Fantasy: Lament for a Warrior's Soul](https://opengameart.org/content/fantasy-lament-for-a-warriors-soul), RandomMind | CC0 | https://opengameart.org/content/fantasy-lament-for-a-warriors-soul | 2026-10-13 |
| `sfx/arrow_hit_1.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/arrow_hit_2.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/bell_chapel.ogg` | синтез в tools/audio_build.py (наш) | наш, без ограничений | — | 2026-10-13 |
| `sfx/bell_far.ogg` | синтез в tools/audio_build.py (наш) | наш, без ограничений | — | 2026-10-13 |
| `sfx/body_fall_1.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/body_fall_2.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/body_fall_3.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/bones_collapse_1.ogg` | [Bones rattle](https://opengameart.org/content/bones-rattle), congusbongus | CC0 | https://opengameart.org/content/bones-rattle | 2026-10-13 |
| `sfx/bones_collapse_2.ogg` | [Bones rattle](https://opengameart.org/content/bones-rattle), congusbongus | CC0 | https://opengameart.org/content/bones-rattle | 2026-10-13 |
| `sfx/bones_collapse_3.ogg` | [Bones rattle](https://opengameart.org/content/bones-rattle), congusbongus | CC0 | https://opengameart.org/content/bones-rattle | 2026-10-13 |
| `sfx/book.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/bow_shot_1.ogg` | [Medieval sound effects - Weapon Textures](https://opengameart.org/content/medieval-sound-effects-weapon-textures), MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures | 2026-10-13 |
| `sfx/bow_shot_2.ogg` | [Medieval sound effects - Weapon Textures](https://opengameart.org/content/medieval-sound-effects-weapon-textures), MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures | 2026-10-13 |
| `sfx/bow_shot_3.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/cast_arcane.ogg` | [8 Magic Attacks](https://opengameart.org/content/8-magic-attacks), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-magic-attacks | 2026-10-13 |
| `sfx/cast_dark_1.ogg` | [3 dark magic spells](https://opengameart.org/content/3-dark-magic-spells), qubodup | CC0 | https://opengameart.org/content/3-dark-magic-spells | 2026-10-13 |
| `sfx/cast_dark_2.ogg` | [3 dark magic spells](https://opengameart.org/content/3-dark-magic-spells), qubodup | CC0 | https://opengameart.org/content/3-dark-magic-spells | 2026-10-13 |
| `sfx/cast_fire_1.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/cast_fire_2.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/cast_holy.ogg` | [8 Heals and Buffs SFX](https://opengameart.org/content/8-heals-and-buffs-sfx), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-heals-and-buffs-sfx | 2026-10-13 |
| `sfx/cloth_1.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/cloth_2.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/cloth_3.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/coin_1.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/coin_2.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/crossbow_shot_1.ogg` | [Medieval sound effects - Weapon Textures](https://opengameart.org/content/medieval-sound-effects-weapon-textures), MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures | 2026-10-13 |
| `sfx/crossbow_shot_2.ogg` | [Medieval sound effects - Weapon Textures](https://opengameart.org/content/medieval-sound-effects-weapon-textures), MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures | 2026-10-13 |
| `sfx/dash_1.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/dash_2.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/defeat.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/explosion.ogg` | [8 Magic Attacks](https://opengameart.org/content/8-magic-attacks), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-magic-attacks | 2026-10-13 |
| `sfx/goo_1.ogg` | [40 CC0 water / splash / slime SFX](https://opengameart.org/content/40-cc0-water-splash-slime-sfx), rubberduck | CC0 | https://opengameart.org/content/40-cc0-water-splash-slime-sfx | 2026-10-13 |
| `sfx/goo_2.ogg` | [40 CC0 water / splash / slime SFX](https://opengameart.org/content/40-cc0-water-splash-slime-sfx), rubberduck | CC0 | https://opengameart.org/content/40-cc0-water-splash-slime-sfx | 2026-10-13 |
| `sfx/handbell_1.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/handbell_2.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/heal_1.ogg` | [8 Heals and Buffs SFX](https://opengameart.org/content/8-heals-and-buffs-sfx), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-heals-and-buffs-sfx | 2026-10-13 |
| `sfx/heal_2.ogg` | [Cure Magic](https://opengameart.org/content/cure-magic), Someoneman | CC0 | https://opengameart.org/content/cure-magic | 2026-10-13 |
| `sfx/heal_3.ogg` | [Cure Magic](https://opengameart.org/content/cure-magic), Someoneman | CC0 | https://opengameart.org/content/cure-magic | 2026-10-13 |
| `sfx/hit_arcane_1.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/hit_arcane_2.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/hit_blade_1.ogg` | [Fleshy Fight Sounds](https://opengameart.org/content/fleshy-fight-sounds), will_leamon | OGA-BY 3.0 | https://opengameart.org/content/fleshy-fight-sounds | 2026-10-13 |
| `sfx/hit_blade_2.ogg` | [Fleshy Fight Sounds](https://opengameart.org/content/fleshy-fight-sounds), will_leamon | OGA-BY 3.0 | https://opengameart.org/content/fleshy-fight-sounds | 2026-10-13 |
| `sfx/hit_blade_3.ogg` | [Horror Sound Effects Library](https://opengameart.org/content/horror-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/horror-sound-effects-library | 2026-10-13 |
| `sfx/hit_blade_4.ogg` | [Horror Sound Effects Library](https://opengameart.org/content/horror-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/horror-sound-effects-library | 2026-10-13 |
| `sfx/hit_blunt_1.ogg` | [Fleshy Fight Sounds](https://opengameart.org/content/fleshy-fight-sounds), will_leamon | OGA-BY 3.0 | https://opengameart.org/content/fleshy-fight-sounds | 2026-10-13 |
| `sfx/hit_blunt_2.ogg` | [Fleshy Fight Sounds](https://opengameart.org/content/fleshy-fight-sounds), will_leamon | OGA-BY 3.0 | https://opengameart.org/content/fleshy-fight-sounds | 2026-10-13 |
| `sfx/hit_blunt_3.ogg` | [Fleshy Fight Sounds](https://opengameart.org/content/fleshy-fight-sounds), will_leamon | OGA-BY 3.0 | https://opengameart.org/content/fleshy-fight-sounds | 2026-10-13 |
| `sfx/hit_bone_1.ogg` | [Horror Sound Effects Library](https://opengameart.org/content/horror-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/horror-sound-effects-library | 2026-10-13 |
| `sfx/hit_bone_2.ogg` | [Horror Sound Effects Library](https://opengameart.org/content/horror-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/horror-sound-effects-library | 2026-10-13 |
| `sfx/hit_bone_3.ogg` | [Horror Sound Effects Library](https://opengameart.org/content/horror-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/horror-sound-effects-library | 2026-10-13 |
| `sfx/hit_claw_1.ogg` | [Fleshy Fight Sounds](https://opengameart.org/content/fleshy-fight-sounds), will_leamon | OGA-BY 3.0 | https://opengameart.org/content/fleshy-fight-sounds | 2026-10-13 |
| `sfx/hit_claw_2.ogg` | [Fleshy Fight Sounds](https://opengameart.org/content/fleshy-fight-sounds), will_leamon | OGA-BY 3.0 | https://opengameart.org/content/fleshy-fight-sounds | 2026-10-13 |
| `sfx/hit_dark_1.ogg` | [8 Magic Attacks](https://opengameart.org/content/8-magic-attacks), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-magic-attacks | 2026-10-13 |
| `sfx/hit_dark_2.ogg` | [8 Heals and Buffs SFX](https://opengameart.org/content/8-heals-and-buffs-sfx), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-heals-and-buffs-sfx | 2026-10-13 |
| `sfx/hit_fire_1.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/hit_fire_2.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/hit_holy.ogg` | [Magic Smite](https://opengameart.org/content/magic-smite), spookymodem | CC-BY 3.0 | https://opengameart.org/content/magic-smite | 2026-10-13 |
| `sfx/journal_1.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/journal_2.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/miss_1.ogg` | [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack), artisticdude | CC0 | https://opengameart.org/content/swishes-sound-pack | 2026-10-13 |
| `sfx/miss_2.ogg` | [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack), artisticdude | CC0 | https://opengameart.org/content/swishes-sound-pack | 2026-10-13 |
| `sfx/miss_3.ogg` | [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack), artisticdude | CC0 | https://opengameart.org/content/swishes-sound-pack | 2026-10-13 |
| `sfx/page_turn_1.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/page_turn_2.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/page_turn_3.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/pickup_1.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/pickup_2.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/save.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio), Kenney | CC0 | https://kenney.nl/assets/rpg-audio | 2026-10-13 |
| `sfx/shout_1.ogg` | [Zombie / Skeleton / Monster Voice Effects](https://opengameart.org/content/zombie-skeleton-monster-voice-effects), ArcadeParty | CC0 | https://opengameart.org/content/zombie-skeleton-monster-voice-effects | 2026-10-13 |
| `sfx/shout_2.ogg` | [Zombie / Skeleton / Monster Voice Effects](https://opengameart.org/content/zombie-skeleton-monster-voice-effects), ArcadeParty | CC0 | https://opengameart.org/content/zombie-skeleton-monster-voice-effects | 2026-10-13 |
| `sfx/spawn.ogg` | [Their Coming (generic horn sound)](https://opengameart.org/content/their-coming-generic-horn-sound), StumpyStrust | CC0 | https://opengameart.org/content/their-coming-generic-horn-sound | 2026-10-13 |
| `sfx/step_grass_1.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/step_grass_2.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/step_grass_3.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/step_grass_4.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/step_mud_1.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/step_mud_2.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/step_mud_3.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/step_mud_4.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/step_stone_1.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/step_stone_2.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/step_stone_3.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds), Kenney | CC0 | https://kenney.nl/assets/impact-sounds | 2026-10-13 |
| `sfx/swing_1.ogg` | [Medieval sound effects - Weapon Textures](https://opengameart.org/content/medieval-sound-effects-weapon-textures), MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures | 2026-10-13 |
| `sfx/swing_2.ogg` | [Medieval sound effects - Weapon Textures](https://opengameart.org/content/medieval-sound-effects-weapon-textures), MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures | 2026-10-13 |
| `sfx/swing_3.ogg` | [Medieval sound effects - Weapon Textures](https://opengameart.org/content/medieval-sound-effects-weapon-textures), MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures | 2026-10-13 |
| `sfx/swing_4.ogg` | [Medieval sound effects - Weapon Textures](https://opengameart.org/content/medieval-sound-effects-weapon-textures), MedicineStorm | CC0 | https://opengameart.org/content/medieval-sound-effects-weapon-textures | 2026-10-13 |
| `sfx/thorns.ogg` | [8 Magic Attacks](https://opengameart.org/content/8-magic-attacks), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-magic-attacks | 2026-10-13 |
| `sfx/throw_1.ogg` | [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack), artisticdude | CC0 | https://opengameart.org/content/swishes-sound-pack | 2026-10-13 |
| `sfx/throw_2.ogg` | [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack), artisticdude | CC0 | https://opengameart.org/content/swishes-sound-pack | 2026-10-13 |
| `sfx/thunder.ogg` | [8 Magic Attacks](https://opengameart.org/content/8-magic-attacks), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-magic-attacks | 2026-10-13 |
| `sfx/trap_1.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/trap_2.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/ui_click_1.ogg` | [UI Audio](https://kenney.nl/assets/ui-audio), Kenney | CC0 | https://kenney.nl/assets/ui-audio | 2026-10-13 |
| `sfx/ui_click_2.ogg` | [UI Audio](https://kenney.nl/assets/ui-audio), Kenney | CC0 | https://kenney.nl/assets/ui-audio | 2026-10-13 |
| `sfx/ui_hover_1.ogg` | [UI Audio](https://kenney.nl/assets/ui-audio), Kenney | CC0 | https://kenney.nl/assets/ui-audio | 2026-10-13 |
| `sfx/ui_hover_2.ogg` | [UI Audio](https://kenney.nl/assets/ui-audio), Kenney | CC0 | https://kenney.nl/assets/ui-audio | 2026-10-13 |
| `sfx/undead_death_1.ogg` | [Zombie / Skeleton / Monster Voice Effects](https://opengameart.org/content/zombie-skeleton-monster-voice-effects), ArcadeParty | CC0 | https://opengameart.org/content/zombie-skeleton-monster-voice-effects | 2026-10-13 |
| `sfx/undead_death_2.ogg` | [Zombie / Skeleton / Monster Voice Effects](https://opengameart.org/content/zombie-skeleton-monster-voice-effects), ArcadeParty | CC0 | https://opengameart.org/content/zombie-skeleton-monster-voice-effects | 2026-10-13 |
| `sfx/undead_death_3.ogg` | [Zombie / Skeleton / Monster Voice Effects](https://opengameart.org/content/zombie-skeleton-monster-voice-effects), ArcadeParty | CC0 | https://opengameart.org/content/zombie-skeleton-monster-voice-effects | 2026-10-13 |
| `sfx/undead_groan_1.ogg` | [Zombies Sound Pack](https://opengameart.org/content/zombies-sound-pack), artisticdude | CC0 | https://opengameart.org/content/zombies-sound-pack | 2026-10-13 |
| `sfx/undead_groan_2.ogg` | [Zombies Sound Pack](https://opengameart.org/content/zombies-sound-pack), artisticdude | CC0 | https://opengameart.org/content/zombies-sound-pack | 2026-10-13 |
| `sfx/undead_groan_3.ogg` | [Zombies Sound Pack](https://opengameart.org/content/zombies-sound-pack), artisticdude | CC0 | https://opengameart.org/content/zombies-sound-pack | 2026-10-13 |
| `sfx/undead_groan_4.ogg` | [Zombies Sound Pack](https://opengameart.org/content/zombies-sound-pack), artisticdude | CC0 | https://opengameart.org/content/zombies-sound-pack | 2026-10-13 |
| `sfx/undead_groan_5.ogg` | [Zombies Sound Pack](https://opengameart.org/content/zombies-sound-pack), artisticdude | CC0 | https://opengameart.org/content/zombies-sound-pack | 2026-10-13 |
| `sfx/victory.ogg` | [Fantasy Sound Effects Library](https://opengameart.org/content/fantasy-sound-effects-library), Little Robot Sound Factory (www.littlerobotsoundfactory.com) | CC-BY 3.0 | https://opengameart.org/content/fantasy-sound-effects-library | 2026-10-13 |
| `sfx/ward_1.ogg` | [8 Heals and Buffs SFX](https://opengameart.org/content/8-heals-and-buffs-sfx), leohpaz | CC-BY 4.0 | https://opengameart.org/content/8-heals-and-buffs-sfx | 2026-10-13 |
| `sfx/ward_2.ogg` | [Fantasy SFX Pack Vol 1](https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1), JC Sounds | CC-BY 4.0 | https://opengameart.org/content/jc-sounds-fantasy-sfx-pack-vol-1 | 2026-10-13 |
| `sfx/whip.ogg` | [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack), artisticdude | CC0 | https://opengameart.org/content/swishes-sound-pack | 2026-10-13 |
