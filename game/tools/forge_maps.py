#!/usr/bin/env python3
"""Карты кузниц плоти главы 4 → data/locations/forge_*.json (формат — docs/LOCATIONS.md).

    python3 game/tools/forge_maps.py

Как dwarf_maps.py: пол строками, объекты списком, кольцо стен вокруг пола и сдвиг на клетку — в mine_maps.py.
Пол цехов — закопчённые плиты (w) и решётки стоков (g); желоба с жидким железом (m) — blocked_ground.
"""
from mine_maps import write, T, LAMP

F = "forge/"
D = "dwarf/"
LEG = {"w": "forge_works", "g": "forge_grate", "m": "forge_molten", "#": "forge_works"}
VAR = {"works": {"tint": "#c8a088"}}
EXTRA = {"blocked_ground": ["forge_molten"]}
WALL = {"char": "#", "sprites": ["forge/wall_block", "forge/wall_block", "forge/wall_block", "forge/wall_pipes"]}


def works(lid, comment, rows, scenes, objects, exits=()):
    write(lid, comment, rows, scenes, objects, exits, legend=LEG, variants=VAR, extra=EXTRA, wall=WALL)


def main():
    # --- 1. Цеха ---------------------------------------------------------------------------
    works("forge_works", "Глава 4, сцена 1 «Цеха»: ряд чанов с чёрной жижей, конвейер, ворота, у которых узники ждали очереди. После боя — стена с именами (подсказка охоты), кузня в конце ряда чанов (закоулок 1), седая узница у остывшего чана (подсказка, если ломали руками).",
     ["   ww           ",
      "   ww           ",
      " wwwwwwwwwwwwww ",
      " wwgwwwgwwwgwwww",
      " wwwwwwwwwwwwwww",
      " wwwwwwwwwwwwwww",
      " wwwwwwwwwwwwwww",
      " wwgwwwgwwwgwwww",
      " wwwwwwwwwwwwww ",
      "            ww  "],
     {"workshops": {"variant": "works", "spawn": [3, 0]}},
     [T((5, 2), F + "vat", id="vat_1"), T((8, 2), F + "vat", id="vat_2"), T((11, 2), F + "vat", id="vat_3"),
      T((5, 6), F + "vat", id="vat_4"), T((8, 6), F + "vat", id="vat_5"), T((11, 6), F + "vat", id="vat_6"),
      T((4, 4), F + "conveyor", id="conveyor_1", size=[3, 1]), T((9, 4), F + "conveyor", id="conveyor_2", size=[3, 1]),
      T((1, 2), F + "names_wall", id="names_wall", explore="ch4_look_names", label="LOC_CH4_NAMES",
        **{"if": "won:chapter4_1"}),
      T((14, 3), F + "smithy", id="smithy", explore="ch4_nook_smith", label="LOC_CH4_SMITHY"),
      T((2, 7), F + "gong", id="gong"),
      T((7, 3), "", id="soldier_1", kind="figure", unit="dead_soldier", face="sw", **{"if": "!won:chapter4_1"}),
      T((7, 5), "", id="soldier_2", kind="figure", unit="dead_soldier", face="sw", **{"if": "!won:chapter4_1"}),
      T((10, 5), "", id="overseer", kind="figure", unit="vat_overseer", face="sw", **{"if": "!won:chapter4_1"}),
      T((9, 7), "", id="survivor", kind="figure", image="prisoner_f", face="north-west",
        explore="ch4_talk_prisoners", label="LOC_CH4_SURVIVOR", **{"if": "ch4_vats=hands"}),
      T((1, 5), F + "brazier", id="brazier_w", **LAMP), T((14, 7), F + "brazier", id="brazier_e", **LAMP),
      T((12, 8), F + "stairs_up", id="office_stairs")],
     exits=[(3, 0), (4, 0), (12, 9), (13, 9)])

    # --- 2. Контора и оружейная ----------------------------------------------------------------
    works("forge_office", "Глава 4, сцена 2 «Отчёты»: побелённая контора с окном на конвейер, оружейная гарнизона за ней (закоулок 2: латы, слиток и книга кладовщика — подсказка охоты), сейф писаря под окном (закоулок 3: плут или фонарь штейгера).",
     ["  ww          ",
      "  wwwwwwwwwwww",
      " wwwwwwwwwwwww",
      " wwwwwwwwwwwww",
      " wwwwwwwwwwwww",
      " wwwwwwwwwwwww",
      "  wwwwwwwwwww ",
      "         ww   "],
     {"reports": {"variant": "works", "spawn": [2, 0]}},
     [T((3, 1), F + "clerk_desk", id="desk_1"), T((6, 1), F + "clerk_desk", id="desk_2"),
      T((9, 1), F + "report_shelf", id="shelf_1"), T((10, 1), F + "report_shelf", id="shelf_2"),
      T((1, 3), F + "window_works", id="window"),
      T((2, 4), F + "safe", id="safe", explore="ch4_nook_safe", label="LOC_CH4_SAFE"),
      T((6, 3), F + "locked_drawer", id="drawer"),
      T((12, 3), F + "armory_door", id="armory", explore="ch4_nook_armory", label="LOC_CH4_ARMORY"),
      T((12, 5), F + "weapon_rack", id="rack"),
      T((11, 5), F + "store_book", id="store_book", explore="ch4_look_iron_note", label="LOC_CH4_STORE_BOOK",
        **{"if": "ch4_nook_armory_done"}),
      T((8, 5), F + "brazier", id="lamp", **LAMP),
      T((9, 6), F + "door_bright", id="hall_door")],
     exits=[(2, 0), (3, 0), (9, 7), (10, 7)])

    # --- 3. Анатомический зал и старая вагранка -----------------------------------------------
    works("forge_anatomy", "Глава 4, сцена 3 «Мастер плоти»: светлый зал с каменными столами в ряд. За ним, в боковом ходе, — старая вагранка (место охоты за Цепью Безымянных, после боя 2). Лестница наверх, в зал казней, — точка невозврата охоты.",
     ["  ww             ",
      "  wwwwwwwwwwwww  ",
      " wwwwwwwwwwwwwww ",
      " wwwgwwwwwwgwwww ",
      " wwwwwwwwwwwwwwwww",
      " wwwwwwwwwwwwwww ",
      " wwwgwwwwwwgwwww ",
      "  wwwwwwwwwwwww  ",
      "              ww "],
     {"flesh_master": {"variant": "works", "spawn": [2, 0]}},
     [T((4, 2), F + "anatomy_table", id="table_1", size=[2, 1]), T((9, 2), F + "anatomy_table", id="table_2", size=[2, 1]),
      T((4, 5), F + "anatomy_table", id="table_3", size=[2, 1]), T((9, 5), F + "anatomy_table", id="table_4", size=[2, 1]),
      T((13, 3), F + "master_table", id="master_table"),
      T((12, 4), "", id="gessar", kind="figure", unit="gessar", face="sw", **{"if": "!won:chapter4_2"}),
      T((7, 4), "", id="work_1", kind="figure", unit="stitched", face="sw", **{"if": "!won:chapter4_2"}),
      T((16, 4), F + "cupola_door", id="cupola", explore="ch4_hunt_site", label="LOC_CH4_CUPOLA",
        **{"if": "won:chapter4_2"}),
      T((1, 4), F + "brazier", id="lamp_w", **LAMP), T((14, 7), F + "brazier", id="lamp_e", **LAMP),
      T((14, 8), F + "stairs_up", id="stairs_up", leave_check=4)],
     exits=[(2, 0), (3, 0), (14, 8), (15, 8)])

    # --- 4. Литейная ------------------------------------------------------------------------
    works("forge_foundry", "Глава 4, сцена 5 «Литейная»: желоба с жидким железом, ковши на цепях, последняя печь у арки спуска на дно. После боя — видение Лиары в остывающем железе; у печи — лагерь главы.",
     ["  ww            ",
      "  wwwwwwwwwwwww ",
      " wwwwwwwwwwwwwww",
      " mmmmmwwmmmmmwww",
      " wwwwwwwwwwwwwww",
      " wwwwwwwwwwwwwww",
      " wwwmmmmmwwmmmmm",
      " wwwwwwwwwwwwwww",
      "  wwwwwwwwwwwww "],
     {"foundry": {"variant": "works", "spawn": [2, 0]}},
     [T((4, 1), F + "ladle", id="ladle_1"), T((11, 4), F + "ladle", id="ladle_2"),
      T((7, 5), F + "slag_heap", id="slag"),
      T((5, 4), "", id="founder_1", kind="figure", unit="foundry_dead", face="sw", **{"if": "!won:chapter4_3&!won:chapter4_3_refuse"}),
      T((9, 7), "", id="soldier_1", kind="figure", unit="dead_soldier", face="sw", **{"if": "!won:chapter4_3&!won:chapter4_3_refuse"}),
      T((13, 7), F + "furnace", id="last_furnace", size=[2, 1], light=40),
      T((1, 7), F + "brazier", id="lamp", **LAMP)],
     exits=[(2, 0), (3, 0)])


if __name__ == "__main__":
    main()
