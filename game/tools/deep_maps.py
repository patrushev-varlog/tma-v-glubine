#!/usr/bin/env python3
"""Карты дна главы 5 → data/locations/deep_*.json (формат — docs/LOCATIONS.md).

    python3 game/tools/deep_maps.py

Как dwarf_maps.py: пол строками, объекты списком, кольцо стен вокруг пола и сдвиг на клетку — в mine_maps.py.
Своих листов у дна пока нет: пол и камень — Молчащих и шахт (тёсаные плиты h, плиты с бороздами r, камень
спуска s), пустота под карнизом (c) — blocked_ground, решётки загонов — клетки из кузниц плоти.
"""
from mine_maps import write, T, LAMP

D = "dwarf/"
F = "forge/"
M = "mines/"
LEG = {"h": "dwarf_hall", "r": "dwarf_rune", "s": "mine_stone", "c": "dwarf_chasm", "#": "dwarf_hall"}
VAR = {"descent": {"tint": "#a0a2b8"}, "seal": {"tint": "#b8bcd8"}}
EXTRA = {"blocked_ground": ["dwarf_chasm"]}
WALL = {"char": "#", "sprites": ["mines/rock_block", "mines/rock_block", "dwarf/wall_block", "mines/rock_block"]}
HALL_WALL = {"char": "#", "sprites": ["dwarf/wall_runes", "dwarf/wall_block", "dwarf/wall_block", "dwarf/wall_runes"]}

GARRISON = "!won:chapter5_1_garrison"
GUARDS = "!won:chapter5_2&!won:chapter5_2_raised"


def deep(lid, comment, rows, scenes, objects, exits=(), wall=WALL):
    write(lid, comment, rows, scenes, objects, exits, legend=LEG, variants=VAR, extra=EXTRA, wall=wall)


def main():
    # --- 1. Спуск ---------------------------------------------------------------------------
    # Лестница от литейной сверху слева, караульня совета у её подножия (закоулок). У третьей опоры развилка:
    # вправо — трещина и карниз над пустотой (тайный путь Велиора), вниз — главный спуск, загоны по бокам,
    # гарнизон поперёк, внизу — арка к залу печати.
    deep("deep_descent", "Глава 5, сцена 1 «Спуск»: лестница от литейной, караульня совета (закоулок, памятная доска — подсказка охоты), третья опора — развилка. Тайный путь Велиора — трещина и карниз над пустотой (Велиор показывает дверцу в зале — подсказка). Главный спуск — гарнизон и загоны с узниками, арка к залу печати внизу.",
     ["  ss              ",
      "  ss              ",
      "hhhhhh            ",
      "hhhhhhh  ssssssss ",
      "  hhhhhssscccccss ",
      "  hhhhhh ccccccss ",
      " hhhhhhhh      ss ",
      " hhhhhhhh      ss ",
      " hhhhhhhh         ",
      " hhhhhhhh         ",
      " hhhhhhhh         ",
      " hhhhhhhh         ",
      "    rr            "],
     {"descent": {"variant": "descent", "spawn": [2, 0]}},
     [T((1, 0), "flooded/stairs", id="stairs_in", kind="decal", flat=True),
      T((0, 2), M + "guard_hut", id="guardroom", size=[2, 1], explore="ch5_look_plaque", label="LOC_CH5_GUARDROOM"),
      T((5, 2), D + "rune_brazier", id="brazier_top", **LAMP),
      T((6, 4), D + "rune_column", id="third_pillar"),
      T((8, 4), M + "rockfall", id="crack_stones", **{"if": "!velior_fate=forgiven"}),
      T((1, 7), F + "cage", id="pen_w1", size=[1, 2]), T((1, 10), F + "cage", id="pen_w2", size=[1, 2]),
      T((8, 7), F + "cage", id="pen_e1", size=[1, 2]), T((8, 10), F + "cage", id="pen_e2", size=[1, 2]),
      T((2, 8), "", id="prisoner_1", kind="figure", image="prisoner_m", face="south-east"),
      T((7, 10), "", id="prisoner_2", kind="figure", image="prisoner_f", face="south-west"),
      T((4, 8), "", id="garrison_1", kind="figure", unit="dead_soldier", face="nw", **{"if": GARRISON}),
      T((6, 8), "", id="garrison_2", kind="figure", unit="dead_soldier", face="nw", **{"if": GARRISON}),
      T((5, 10), "", id="garrison_3", kind="figure", unit="vat_overseer", face="nw", **{"if": GARRISON}),
      T((14, 4), "", id="ledge_edge", kind="decal", explore="ch5_talk_velior_niche", label="LOC_CH5_LEDGE",
        **{"if": "ch5_secret_path"}),
      T((15, 7), "flooded/stairs", id="ledge_end", kind="decal", flat=True),
      T((3, 11), D + "rune_brazier", id="brazier_low", **LAMP),
      T((4, 12), D + "rune_arch", id="hall_gate", size=[2, 1])],
     exits=[(2, 0), (3, 0), (4, 12), (5, 12), (15, 7), (16, 7)])

    # --- 2. Зал печати ----------------------------------------------------------------------
    # Круглый зал: пол — печать, борозды сходятся в центре. Вдоль стены — тринадцать постаментов стражи совета,
    # тринадцатый пуст, за ним дверца (место охоты). Центр печати — точка невозврата охоты.
    deep("deep_seal_hall", "Глава 5, сцена 2 «Зал печати»: пол-печать с бороздами, стража совета у входа, вдоль стены постаменты. После боя — павшие стражи (подсказка охоты) и дверца за пустым тринадцатым постаментом (место охоты, Печать совета). Центр печати — выход к супругу, проверка охоты (leave_check: 5).",
     ["      hh        ",
      "  hhhhhhhhhhhh  ",
      " hhhrhhhhhhrhhh ",
      " hhhhrhhhhrhhhh ",
      "hhhhhhrrrrhhhhhh",
      "hhhhhhrrrrhhhhhh",
      " hhhhrhhhhrhhhh ",
      " hhhrhhhhhhrhhh ",
      "  hhhhhhhhhhhh  ",
      "     hhhhhh     "],
     {"seal_hall": {"variant": "seal", "spawn": [6, 0]}},
     [T((2, 1), D + "stone_niche", id="pedestal_1"), T((4, 1), D + "stone_niche", id="pedestal_2"),
      T((10, 1), D + "stone_niche", id="pedestal_3"), T((12, 1), D + "stone_niche", id="pedestal_4"),
      T((0, 4), D + "stone_niche", id="pedestal_5"), T((15, 5), D + "stone_niche", id="pedestal_6"),
      T((2, 8), D + "stone_niche", id="pedestal_7"), T((12, 8), D + "stone_niche", id="pedestal_8"),
      T((5, 2), D + "bones", id="fallen_guards", kind="decal", flat=True, explore="ch5_look_crests", label="LOC_CH5_CRESTS",
        **{"if": "won:chapter5_2|won:chapter5_2_raised"}),
      T((1, 6), D + "stone_niche", id="pedestal_13", explore="ch5_hunt_site", label="LOC_CH5_NICHE"),
      T((5, 3), "", id="guard_1", kind="figure", unit="dead_soldier", face="nw", **{"if": GUARDS}),
      T((9, 3), "", id="guard_2", kind="figure", unit="dead_soldier", face="ne", **{"if": GUARDS}),
      T((7, 3), "", id="guard_3", kind="figure", unit="dead_soldier", face="nw", **{"if": GUARDS}),
      T((3, 3), D + "rune_brazier", id="brazier_w", **LAMP), T((12, 3), D + "rune_brazier", id="brazier_e", **LAMP),
      T((7, 4), "", id="seal_center", kind="decal", light=60, leave_check=5)],
     exits=[(6, 0), (7, 0)], wall=HALL_WALL)


if __name__ == "__main__":
    main()
