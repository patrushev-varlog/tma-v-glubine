#!/usr/bin/env python3
"""Карты затопленных выработок главы 2 → data/locations/flood_*.json (формат — docs/LOCATIONS.md).

    python3 game/tools/flood_maps.py

Как mine_maps.py: пол строками, объекты списком, кольцо стен вокруг пола и сдвиг на клетку — там же.
Вода по пояс (w) — пол, по ней ходят; глубокая вода (d) — blocked_ground, туда не пройти.
"""
from mine_maps import write, T, M, LAMP

F = "flooded/"
LEG = {"s": "mine_stone", "g": "mine_gravel", "p": "mine_planks", "e": "flood_wet", "w": "flood_wade", "d": "flood_deep",
       "#": "mine_stone"}
VAR = {"flood": {"tint": "#8e9ab8"}}
EXTRA = {"blocked_ground": ["flood_deep"]}


def flood(lid, comment, rows, scenes, objects, exits=()):
    write(lid, comment, rows, scenes, objects, exits, legend=LEG, variants=VAR, extra=EXTRA)


def main():
    # --- 1. Чёрная вода -------------------------------------------------------------
    flood("flood_black_water", "Глава 2, сцена 1 «Чёрная вода»: лестница от сторожки уходит в воду. Затопленная кладовая у лестницы (закоулок 1), утопленник на полке в ней (подсказка 1).",
     ["      ss       ",
      "      ss       ",
      "    eewwee     ",
      "   ewwwwwwe    ",
      "  ewwwwwwwwe   ",
      " ewwwddwwwwwe  ",
      " ewwwdddwwwwe  ",
      "  ewwwddwwwwe  ",
      "   ewwwwwwwe   ",
      "    eewwwee    ",
      "      www      ",
      "      www      "],
     {"black_water": {"variant": "flood", "spawn": [6, 1]}},
     [T((5, 0), M + "timber_support", id="stair_l"), T((8, 0), M + "timber_support", id="stair_r"),
      T((4, 2), F + "cellar_door", id="cellar", explore="ch2_nook_cellar", label="LOC_CH2_CELLAR"),
      T((3, 3), "", id="drowned_note", kind="figure", image="drowned_m", face="south-east", explore="ch2_look_drowned_note",
        label="LOC_CH2_DROWNED_NOTE", **{"if": "ch2_nook_cellar_done"}),
      T((10, 3), F + "pipes", id="pipes"),
      T((12, 6), M + "rockfall", id="fall"),
      T((2, 6), M + "timber_support", id="support_w"),
      T((10, 8), M + "timber_support", id="support_e"),
      T((5, 9), "", id="dead_1", kind="figure", unit="drowned", face="ne", **{"if": "!won:chapter2_1"}),
      T((8, 4), "", id="dead_2", kind="figure", unit="drowned", face="sw", **{"if": "!won:chapter2_1"}),
      T((7, 11), M + "timber_support", id="drift_on")],
     exits=[(6, 0), (7, 0), (6, 11), (7, 11), (8, 11)])

    # --- 2. Беглые: сухой уступ --------------------------------------------------------
    flood("flood_ledge", "Глава 2, сцена 2 «Беглые»: штрек поднимается из воды к сухому уступу с костром. Лёжка на дальнем краю уступа (закоулок 2), вожак беглых (подсказка 2).",
     ["  www          ",
      "  wwe          ",
      "  ewwe         ",
      "   eesss       ",
      "   ssssssss    ",
      "  sssgsssssss  ",
      "  ssssssssssgs ",
      "   ssssssssss  ",
      "     ssss  sss ",
      "            ss "],
     {"fugitives": {"variant": "flood", "spawn": [3, 0]}},
     [T((7, 5), "", id="fire", kind="fire"),
      T((6, 4), "", id="leader_mab", kind="figure", image="mab", face="south-west", explore="ch2_talk_fugitive_tale",
        label="LOC_CH2_FUGITIVE_TALE", **{"if": "ch2_fugitives_leader=meb"}),
      T((6, 4), "", id="leader_tobin", kind="figure", image="tobin", face="south-west", explore="ch2_talk_fugitive_tale",
        label="LOC_CH2_FUGITIVE_TALE", **{"if": "ch2_fugitives_leader=tobin"}),
      T((8, 6), "", id="fugitive_1", kind="figure", image="prisoner_f", face="north-west"),
      T((5, 6), "", id="fugitive_2", kind="figure", image="prisoner_m", face="north-east"),
      T((9, 4), "", id="fugitive_3", kind="figure", image="prisoner_m", face="south-west"),
      T((12, 9), F + "bedding", id="ledge_nook", kind="decal", flat=True, explore="ch2_nook_ledge", label="LOC_CH2_LEDGE"),
      T((13, 8), M + "rockfall", id="ledge_rocks"),
      T((4, 4), M + "lamp_post", id="lamp_1", **LAMP),
      T((5, 8), M + "timber_support", id="path_on")],
     exits=[(2, 0), (3, 0), (4, 0), (5, 8), (6, 8), (7, 8), (8, 8)])

    # --- 3. Насосная станция ------------------------------------------------------------
    flood("flood_pump", "Глава 2, сцена 3 «Контрабандисты»: насосная на сваях над водой. Помосты, причал с плоскодонками, конторка Ренны. Склад под помостом (закоулок 3), лодочники у причала (подсказка 3).",
     ["  sss             ",
      "  sss  pppppppp   ",
      " ssssspppppppppp  ",
      " sssssppppppppppp ",
      "  wwwwwwwwwwwwppp ",
      "  wwwddddddwwwppp ",
      "  wwwddddddwwwppp ",
      "  wwwwwwwwwwwwwpp ",
      "   ppppppwwwwwwpp ",
      "   pppppppwwwwpp  ",
      "    pppppp        "],
     {"smugglers": {"variant": "flood", "spawn": [3, 0]}},
     [T((7, 1), F + "pump_wheel", id="pump", size=[2, 2]),
      T((13, 2), F + "smuggler_desk", id="desk"),
      T((14, 1), "", id="renna", kind="figure", image="renna", face="south-west"),
      T((10, 1), F + "brazier", id="brazier_1", **LAMP),
      T((16, 6), F + "brazier", id="brazier_2", **LAMP),
      T((11, 3), "", id="xbow_1", kind="figure", unit="crossbowman", face="sw", **{"if": "!won:chapter2_2_smugglers"}),
      T((15, 4), "", id="xbow_2", kind="figure", unit="crossbowman", face="sw", **{"if": "!won:chapter2_2_smugglers"}),
      T((16, 9), "", id="smuggler_1", kind="figure", image="smuggler", face="north-west", **{"if": "!won:chapter2_2_smugglers"}),
      T((15, 3), F + "crates", id="stash", explore="ch2_nook_stash", label="LOC_CH2_STASH"),
      T((8, 6), F + "flatboat", id="boat_1", kind="decal", flat=True),
      T((4, 7), F + "flatboat", id="boat_2", kind="decal", flat=True),
      T((5, 8), "", id="boatman_1", kind="figure", image="boatman", face="north-east", explore="ch2_listen_boatmen",
        label="LOC_CH2_BOATMEN"),
      T((7, 9), "", id="boatman_2", kind="figure", image="boatman", face="north-west"),
      T((3, 9), F + "crates", id="pier_crates"),
      T((12, 8), F + "pipes", id="pipes"),
      T((5, 3), M + "lamp_post", id="lamp_1", **LAMP)],
     exits=[(2, 0), (3, 0), (4, 0)])

    # --- 4. Шлюз --------------------------------------------------------------------------
    flood("flood_sluice", "Глава 2, сцена 6 «Шлюз»: стена шлюза с затвором, страж на цепи. После боя вода уходит, открывается лестница в Дварфийские залы (точка невозврата охоты); малый рычаг и решётка часовни — место охоты.",
     ["     wwwwww     ",
      "    wwwwwwww    ",
      "  eewwwwwwwwee  ",
      "  eeewwwwwweee  ",
      "  ssseewweesss  ",
      "  ssssseessssss ",
      "   ssssssssss   ",
      "     ssssss     ",
      "      ssss      ",
      "      ssss      "],
     {"sluice": {"variant": "flood", "spawn": [7, 9]}},
     [T((6, 0), F + "sluice_gate", id="gate", size=[2, 2]),
      T((7, 2), "", id="guardian", kind="figure", unit="sluice_guardian", face="sw", **{"if": "!won:chapter2_3"}),
      T((10, 1), F + "small_lever", id="small_lever", explore="ch2_hunt_site", label="LOC_CH2_SMALL_LEVER"),
      T((12, 2), F + "grate", id="grate"),
      T((8, 3), F + "stairs", id="stairs", kind="decal", flat=True, leave_check=2, **{"if": "won:chapter2_3"}),
      T((3, 4), M + "lamp_post", id="lamp_1", **LAMP),
      T((13, 5), M + "lamp_post", id="lamp_2", **LAMP),
      T((4, 3), M + "timber_support", id="support_w"), T((12, 4), M + "timber_support", id="support_e")],
     exits=[(6, 9), (7, 9), (8, 9), (9, 9)])


if __name__ == "__main__":
    main()
