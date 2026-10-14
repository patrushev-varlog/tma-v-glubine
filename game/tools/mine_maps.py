#!/usr/bin/env python3
"""Карты шахт главы 1 → data/locations/mine_*.json (формат — docs/LOCATIONS.md).

    python3 game/tools/mine_maps.py

Пол задаётся строками, объекты — списком; клетки — как в рисунке строк. Скрипт сам обводит штреки
стеной: вокруг пола кладётся кольцо клеток «#», на них LocationMap ставит кубы скалы (поле wall),
а все координаты сдвигаются на клетку вправо-вниз, чтобы кольцу хватило места у края.
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "data" / "locations"
LEG = {"s": "mine_stone", "g": "mine_gravel", "o": "mine_ore", "p": "mine_planks", "r": "mine_rails", "R": "mine_rails_b",
       "#": "mine_stone"}
VAR = {"mine": {"tint": "#9a96b4"}}
WALL = {"char": "#", "sprites": ["mines/rock_block", "mines/rock_block", "mines/rock_block", "mines/rock_block", "mines/rock_block_ore"]}


def T(cell, sprite, **kw):
    d = {"id": kw.pop("id", sprite.split("/")[-1] + "_%d_%d" % tuple(cell)), "kind": kw.pop("kind", "box"), "cell": list(cell)}
    d.update(kw)
    if sprite:
        d["sprite"] = sprite
    return d


def _walled(rows, exits=()):
    """Сдвиг на клетку и кольцо «#» вокруг пола (8 соседей). Штрек, который упирается в край рисунка,
    уходит в темноту там, где указан выход (exits — клетки пола у края рисунка): напротив него стены нет."""
    w = max(len(r) for r in rows) + 2
    g = [list(" " * w)] + [list((" " + r).ljust(w)) for r in rows] + [list(" " * w)]
    floor = {(x, y) for y, r in enumerate(g) for x, c in enumerate(r) if c != " "}
    for y, r in enumerate(g):
        for x, c in enumerate(r):
            edge = x in (0, w - 1) or y in (0, len(g) - 1)
            if edge and any((n[0] - 1, n[1] - 1) in exits for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                continue
            if c == " " and any((x + dx, y + dy) in floor for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                r[x] = "#"
    return ["".join(r) for r in g]


def _shift(v):
    return [v[0] + 1, v[1] + 1]


def write(lid, comment, rows, scenes, objects, exits=(), legend=None, variants=None, extra=None):
    """legend и variants — свои у карт других глав (flood_maps.py), extra — поля карты сверх обычных (blocked_ground)."""
    rows = _walled(rows, {tuple(e) for e in exits})
    for sc in scenes.values():
        sc["spawn"] = _shift(sc["spawn"])
    for o in objects:
        o["cell"] = _shift(o["cell"])
    s = "{\n"
    s += ' "id": %s,\n "comment": %s,\n "size": %s,\n' % (json.dumps(lid), json.dumps(comment, ensure_ascii=False),
        json.dumps([len(rows[0]), len(rows)]))
    s += ' "legend": %s,\n' % json.dumps(legend or LEG)
    for k, v in (extra or {}).items():
        s += ' %s: %s,\n' % (json.dumps(k), json.dumps(v))
    s += ' "wall": %s,\n' % json.dumps(WALL)
    s += ' "ground": [\n' + ",\n".join("  " + json.dumps(r) for r in rows) + "\n ],\n"
    s += ' "variants": %s,\n' % json.dumps(variants or VAR)
    s += ' "scenes": %s,\n' % json.dumps(scenes)
    s += ' "objects": [\n' + ",\n".join("  " + json.dumps(o, ensure_ascii=False) for o in objects) + "\n ]\n}\n"
    (OUT / f"{lid}.json").write_text(s)


M = "mines/"
LAMP = dict(light=34)

def main():
    # --- 1. Ворота: пост верхнего ворота --------------------------------------------------
    write("mine_gate", "Глава 1, сцена 1 «Ворота»: пост Хольта на верхнем горизонте. После боя — караулка с картой горизонта (подсказка охоты) и боковой забой (закоулок 1).",
     ["      sRs       ",
      "      sRs       ",
      "ggsssssRs       ",
      "ogsgsssRs       ",
      "      sRs       ",
      "   ssssRsssss   ",
      "   ssgsRsssss   ",
      "   sssoRssgss   ",
      "   ssssRsssss   ",
      "   ssssRsssss   ",
      "      sRs       ",
      "      sRs       ",
      "      sRs       ",
      "      sRs       "],
     {"gate": {"variant": "mine", "spawn": [7, 1]}},
     [T((6, 0), M + "timber_support", id="arch_in"), T((8, 0), M + "timber_support", id="arch_in_b"),
      T((0, 2), M + "rockfall", id="face", explore="ch1_nook_face", label="LOC_CH1_FACE"),
      T((1, 3), M + "ore_heap", id="face_ore"),
      T((3, 5), M + "notice_board", id="notice"),
      T((3, 8), M + "winch", id="winch"),
      T((6, 5), M + "lamp_post", id="lamp_1", **LAMP),
      T((12, 5), M + "timber_support", id="post_support"),
      T((10, 6), "", id="holt", kind="figure", unit="holt", image="holt", face="south-west", color="#7a5135", head="#d8c8b0"),
      T((11, 8), M + "guard_hut", id="holt_hut", size=[2, 2], explore="ch1_look_holt_map", label="LOC_CH1_HOLT_MAP"),
      T((9, 9), M + "scaffold", id="walkway"),
      T((8, 10), M + "lamp_post", id="lamp_2", **LAMP),
      T((7, 11), M + "minecart", id="cart"),
      T((7, 13), M + "timber_support", id="drift_on")],
     exits=[(6, 0), (7, 0), (8, 0), (6, 13), (7, 13), (8, 13)])

    # --- 2. Клетка: лагерь надсмотрщиков ------------------------------------------------
    write("mine_cage", "Глава 1, сцена 2 «Клетка»: лагерь надсмотрщиков в широкой выработке. Кладовая крепи за нарами (закоулок 2).",
     ["  sRs           ",
      "  sRs           ",
      " ssRsssssss     ",
      "ssssssgsssss    ",
      "ssgsssssssssss  ",
      "ssssssssssosss  ",
      "sssssssssssss   ",
      "sosssssgssssss  ",
      "ssssssssssssss  ",
      " sssssssssss    ",
      "   sssssss      "],
     {"cage": {"variant": "mine", "spawn": [3, 1]}},
     [T((2, 0), M + "timber_support", id="arch_in"),
      T((0, 4), M + "bunk", id="bunks_w", size=[1, 4], each=True),
      T((0, 8), M + "scaffold", id="timber_store", explore="ch1_nook_timber", label="LOC_CH1_TIMBER"),
      T((7, 5), M + "cage", id="cage"),
      T((7, 8), M + "rockfall", id="hearth"),
      T((4, 7), M + "lamp_post", id="lamp_1", **LAMP),
      T((11, 3), M + "minecart", id="cart"),
      T((12, 4), M + "ore_heap", id="ore"),
      T((12, 7), M + "rockfall", id="fall"),
      T((10, 9), M + "timber_support", id="support_s"),
      T((9, 2), M + "timber_support", id="support_n")],
     exits=[(2, 0), (3, 0), (4, 0)])

    # --- 3. Бараки --------------------------------------------------------------------
    B = []
    for x in range(1, 15):
        if x not in (5,):
            B.append(T((x, 3), M + "bars_b", id="bars_n_%d" % x))
        if x not in (10,):
            B.append(T((x, 6), M + "bars_b", id="bars_s_%d" % x))
    write("mine_barracks", "Глава 1, сцена 4 «Бараки»: галерея с решётками бараков. Сторожка десятника в конце галереи (закоулок 3), после бунта — старый узник у решётки (подсказка охоты).",
     ["                ssss",
      " gggogggggggggg ssss",
      " ggggggggggoggg ssss",
      " sssssssssssssssssss",
      "sssgsssssssssssssgss",
      "ssssssssssgsssssosss",
      " sssssssssssssssssss",
      " gggggggggggggg ssss",
      " ggggogggggggog ssss",
      "                ssss"],
     {"barracks": {"variant": "mine", "spawn": [0, 4]}},
     B + [
      T((5, 3), M + "bars_b", id="door_n", **{"if": "!won:chapter1_2_riot"}),
      T((10, 6), M + "bars_b", id="door_s", **{"if": "!won:chapter1_2_riot"}),
      T((1, 1), M + "bunk", id="bunks_n", size=[14, 1], each=True),
      T((1, 8), M + "bunk", id="bunks_s", size=[14, 1], each=True),
      T((3, 2), "", id="dead_1", kind="figure", unit="zombie", face="ne", **{"if": "!won:chapter1_2_riot"}),
      T((12, 7), "", id="dead_2", kind="figure", unit="zombie", face="sw", **{"if": "!won:chapter1_2_riot"}),
      T((4, 2), "", id="mab", kind="figure", image="mab", face="south-east", **{"if": "!won:chapter1_2_riot"}),
      T((8, 2), "", id="prisoner_1", kind="figure", unit="prisoner_f", image="prisoner_f", face="south-west", **{"if": "!won:chapter1_2_riot"}),
      T((7, 7), "", id="prisoner_2", kind="figure", unit="prisoner", image="prisoner_m", face="north-west", **{"if": "!won:chapter1_2_riot"}),
      T((6, 2), "", id="boy", kind="figure", image="boy", face="south-west", **{"if": "column_choice=trail"}),
      T((11, 5), "", id="old_prisoner", kind="figure", unit="prisoner", image="prisoner_m", face="north-west", explore="ch1_talk_old_prisoner", label="LOC_CH1_OLD_PRISONER", **{"if": "won:chapter1_2_riot"}),
      T((3, 5), M + "lamp_post", id="lamp_1", **LAMP),
      T((9, 4), M + "lamp_post", id="lamp_2", **LAMP),
      T((14, 5), M + "lamp_post", id="lamp_3", **LAMP),
      T((17, 1), M + "guard_hut", id="foreman_hut", size=[2, 2], explore="ch1_nook_hut", label="LOC_CH1_HUT"),
      T((16, 8), M + "boards", id="guardroom"),
      T((17, 9), M + "tag_box", id="tags", kind="decal", flat=True),
      T((19, 4), M + "timber_support", id="gallery_end")],
     exits=[(0, 4), (0, 5), (19, 4), (19, 5)])

    # --- 4. Подъёмник ------------------------------------------------------------------
    write("mine_lift", "Глава 1, сцена 6 «Подъёмник»: площадка над стволом, клеть и рычаг (точка невозврата охоты). Сбоку — заложенный досками штрек (место охоты).",
     ["      ssss    ",
      "     ppppppp  ",
      "sss  ppppppp  ",
      "ssgsspppppppp ",
      "sssspppppppppp",
      "     pppppppp ",
      "     ppppppp  ",
      "      ppppp   ",
      "      sRs     ",
      "      sRs     ",
      "      sRs     "],
     {"lift": {"variant": "mine", "spawn": [7, 10]}},
     [T((0, 2), M + "boards", id="drift_boards", explore="ch1_hunt_site", label="LOC_CH1_BOARDS"),
      T((0, 4), M + "rockfall", id="drift_fall"),
      T((9, 2), M + "lift_cage", id="lift_cage", size=[2, 2]),
      T((11, 3), M + "shaft", id="shaft"),
      T((8, 1), M + "winch", id="lever", leave_check=1),
      T((6, 0), M + "timber_support", id="beam_w"), T((9, 0), M + "timber_support", id="beam_e"),
      T((5, 3), M + "lamp_post", id="lamp_1", **LAMP),
      T((12, 5), M + "lamp_post", id="lamp_2", **LAMP),
      T((6, 6), M + "tag_box", id="crate", kind="decal", flat=True),
      T((5, 1), M + "scaffold", id="rack"),
      T((7, 6), "", id="prisoner_1", kind="figure", unit="prisoner", image="prisoner_m", face="north-east", **{"if": "ch1_choice=riot"}),
      T((9, 6), "", id="prisoner_2", kind="figure", unit="prisoner_f", image="prisoner_f", face="north-east", **{"if": "ch1_choice=riot"}),
      T((6, 8), M + "timber_support", id="arch_in")],
     exits=[(6, 10), (7, 10), (8, 10)])


if __name__ == "__main__":
    main()
