#!/usr/bin/env python3
"""Карты дварфийских залов главы 3 → data/locations/dwarf_*.json (формат — docs/LOCATIONS.md).

    python3 game/tools/dwarf_maps.py

Как mine_maps.py: пол строками, объекты списком, кольцо стен вокруг пола и сдвиг на клетку — там же.
Пол залов — тёсаные плиты (h) и плиты с рунами (r); пропасть над залом печати (c) — blocked_ground.
"""
from mine_maps import write, T, LAMP

D = "dwarf/"
F = "flooded/"
LEG = {"h": "dwarf_hall", "r": "dwarf_rune", "c": "dwarf_chasm", "#": "dwarf_hall"}
VAR = {"halls": {"tint": "#b4a690"}}
EXTRA = {"blocked_ground": ["dwarf_chasm"]}
WALL = {"char": "#", "sprites": ["dwarf/wall_block", "dwarf/wall_block", "dwarf/wall_block", "dwarf/wall_runes"]}


def halls(lid, comment, rows, scenes, objects, exits=()):
    write(lid, comment, rows, scenes, objects, exits, legend=LEG, variants=VAR, extra=EXTRA, wall=WALL)


def main():
    # --- 1. Арки --------------------------------------------------------------------------
    halls("dwarf_arches", "Глава 3, сцена 1 «Арки»: зал резных арок у лестницы от шлюза, стражи Молчащих в нишах. После боя — дверь с загадкой за аркой (охота главы, ch3_riddle_door).",
     ["      hh        ",
      "      hh        ",
      "  hhhhhhhhhhhh  ",
      "  hrhhhhhhhhrh  ",
      "  hhhhhrrhhhhh  ",
      "  hhhhrhhrhhhh  ",
      "  hhhhhrrhhhhh  ",
      "  hrhhhhhhhhrh  ",
      "  hhhhhhhhhhhh  ",
      "     hhhhhhh    ",
      "        hh      "],
     {"arches": {"variant": "halls", "spawn": [6, 0]}},
     [T((5, 0), F + "stairs", id="stairs_in", kind="decal", flat=True),
      T((2, 2), D + "rune_arch", id="arch_nw", size=[2, 2]),
      T((12, 2), D + "rune_arch", id="arch_ne", size=[2, 2]),
      T((2, 6), D + "stone_niche", id="niche_w"),
      T((13, 6), D + "stone_niche", id="niche_e"),
      T((4, 4), D + "rune_column", id="col_1"), T((11, 4), D + "rune_column", id="col_2"),
      T((4, 7), D + "rune_column", id="col_3"), T((11, 7), D + "rune_column", id="col_4"),
      T((7, 3), "", id="warden_1", kind="figure", unit="stone_guardian", face="sw", **{"if": "!won:chapter3_1"}),
      T((10, 5), "", id="warden_2", kind="figure", unit="stone_guardian", face="sw", **{"if": "!won:chapter3_1"}),
      T((5, 6), "", id="warden_3", kind="figure", unit="stone_guardian", face="ne", **{"if": "!won:chapter3_1"}),
      T((9, 8), D + "rubble", id="warden_rubble", **{"if": "won:chapter3_1"}),
      T((13, 4), D + "riddle_door", id="riddle_door", explore="ch3_riddle_door", label="LOC_CH3_RIDDLE_DOOR"),
      T((3, 8), D + "rune_brazier", id="brazier_w", **LAMP),
      T((12, 8), D + "rune_brazier", id="brazier_e", **LAMP),
      T((8, 10), D + "rune_column", id="hall_on")],
     exits=[(6, 0), (7, 0), (8, 10), (9, 10)])

    # --- 2. Кузница: лагерь спасённых -------------------------------------------------------
    halls("dwarf_forge", "Глава 3, сцена 2 «Лагерь спасённых»: дварфийская кузница — постоянный лагерь. Горн, наковальни, лари со сталью. Пивоварня Молчащих за горном (закоулок 1, слиток для кузницы).",
     ["    hhhh      ",
      "  hhhhhhhhhh  ",
      " hhhhhhhhhhhh ",
      " hhhhhhhhhhhhh",
      " hhhhrrrhhhhhh",
      " hhhhrrrhhhhh ",
      " hhhhhhhhhhhh ",
      "  hhhhhhhhhh  ",
      "     hhh      "],
     {"refuge": {"variant": "halls", "spawn": [6, 8]}},
     [T((5, 0), D + "great_forge", id="forge", size=[2, 2], light=40),
      T((4, 3), D + "anvil", id="anvil_1"), T((8, 3), D + "anvil", id="anvil_2"),
      T((11, 2), D + "steel_chest", id="steel_chests"),
      T((2, 6), D + "coal_heap", id="coal"),
      T((12, 3), D + "brew_door", id="brewery", explore="ch3_nook_brewery", label="LOC_CH3_BREWERY"),
      T((7, 4), "", id="smith", kind="figure", image="smith", face="south-west", **{"if": "column_choice=neighbors"}),
      T((3, 4), "", id="mab", kind="figure", image="mab", face="south-east", **{"if": "ch3_camp_leader=meb"}),
      T((3, 4), "", id="tobin", kind="figure", image="tobin", face="south-east", **{"if": "ch3_camp_leader=tobin"}),
      T((9, 6), "", id="fugitive_1", kind="figure", image="prisoner_f", face="north-west", **{"if": "ch3_fugitives_here"}),
      T((2, 5), "", id="fugitive_2", kind="figure", image="prisoner_m", face="north-east", **{"if": "ch3_fugitives_here"}),
      T((10, 5), F + "bedding", id="bedding_1", kind="decal", flat=True),
      T((1, 3), D + "rune_column", id="fresco_door"),
      T((12, 5), D + "rune_brazier", id="brazier", **LAMP)],
     exits=[(5, 8), (6, 8), (7, 8)])

    # --- 3. Архив Молчащих -------------------------------------------------------------------
    halls("dwarf_archive", "Глава 3, сцена 4 «Архив Молчащих»: длинный зал полок с каменными плитами, мёртвые архивариусы за столами. Детские таблички в боковой нише (подсказка к двери), плита у дальней стены (тайник плута, ch3_rogue_cache).",
     ["  hh              ",
      "  hhhhhhhhhhhhhh  ",
      " hhhhhhhhhhhhhhhh ",
      " hhhhhhhhhhhhhhhh ",
      " hhhhhhhhhhhhhhhhh",
      " hhhhhhhhhhhhhhhh ",
      " hhhhhhhhhhhhhhhh ",
      "  hhhhhhhhhhhhhh  ",
      "               hh "],
     {"archive": {"variant": "halls", "spawn": [2, 0]}},
     [T((4, 2), D + "tablet_shelf", id="shelf_1"), T((5, 2), D + "tablet_shelf", id="shelf_2"),
      T((8, 2), D + "tablet_shelf", id="shelf_3"), T((9, 2), D + "tablet_shelf", id="shelf_4"),
      T((12, 2), D + "tablet_shelf", id="shelf_5"), T((13, 2), D + "tablet_shelf", id="shelf_6"),
      T((4, 6), D + "tablet_shelf", id="shelf_7"), T((5, 6), D + "tablet_shelf", id="shelf_8"),
      T((8, 6), D + "tablet_shelf", id="shelf_9"), T((9, 6), D + "tablet_shelf", id="shelf_10"),
      T((12, 6), D + "tablet_shelf", id="shelf_11"),
      T((6, 4), D + "scribe_desk", id="desk_1"), T((10, 4), D + "scribe_desk", id="desk_2"),
      T((7, 3), "", id="archivist_1", kind="figure", unit="dwarf_archivist", face="sw", **{"if": "!won:chapter3_2"}),
      T((11, 5), "", id="archivist_2", kind="figure", unit="dwarf_archivist", face="sw", **{"if": "!won:chapter3_2"}),
      T((10, 3), "", id="archivist_3", kind="figure", unit="dwarf_archivist", face="sw", **{"if": "!won:chapter3_2"}),
      T((7, 5), "", id="old_archivist", kind="figure", image="dwarf_dead", face="south-west", **{"if": "won:chapter3_2"}),
      T((16, 4), D + "child_tablets", id="tablets", explore="ch3_look_tablet", label="LOC_CH3_TABLETS"),
      T((14, 7), D + "floor_slab", id="slab", kind="decal", flat=True, explore="ch3_rogue_cache", label="LOC_CH3_SLAB"),
      T((2, 4), D + "rune_brazier", id="brazier_1", **LAMP),
      T((15, 2), D + "rune_brazier", id="brazier_2", **LAMP),
      T((15, 8), D + "rune_column", id="archive_out")],
     exits=[(2, 0), (3, 0), (15, 8), (16, 8)])

    # --- 4. Галерея над залом печати -----------------------------------------------------------
    halls("dwarf_gallery", "Глава 3, сцена 6 «Хранитель печати»: галерея над пропастью, внизу светится плита печати. Обвалившийся боковой ход с костями беглых (закоулок 2, слиток). Торвин — в дальнем конце.",
     ["  hh             ",
      "  hhhhhhhhhhhhhh ",
      "  hhhhhhhhhhhhhhh",
      "  hhhhrhhhhrhhhh ",
      "  cccccccccccccc ",
      "  cccccccccccccc ",
      "  cccccccccccccc "],
     {"keeper": {"variant": "halls", "spawn": [2, 0]}},
     [T((5, 1), D + "rune_column", id="col_1"), T((9, 1), D + "rune_column", id="col_2"),
      T((13, 1), D + "stone_niche", id="niche_1"),
      T((7, 0), D + "rubble", id="side_rubble"),
      T((8, 0), D + "bones", id="side_passage", kind="decal", flat=True, explore="ch3_nook_gallery", label="LOC_CH3_GALLERY_NOOK"),
      T((14, 3), "", id="torvin", kind="figure", unit="torvin", face="sw", **{"if": "!won:chapter3_3"}),
      T((15, 2), D + "warhammer", id="hammer", kind="decal", flat=True, **{"if": "won:chapter3_3"}),
      T((3, 3), D + "rune_brazier", id="brazier_1", **LAMP),
      T((2, 1), D + "rune_column", id="gallery_out")],
     exits=[(2, 0), (3, 0)])


if __name__ == "__main__":
    main()
