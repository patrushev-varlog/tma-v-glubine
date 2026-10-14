"""Глава 1, партия 3: стены штреков для карт шахт (решение Валерия 14.10.2026) — пробы по два seed.

    python3 art/tools/ch1_batch3.py        # --reroll имя... — ещё seed 3 и 4
Варианты — art/chapter1/tiles/mines3/variants/<имя>_<seed>.png, отобранные копирует ch1_preview.py.
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import ISO
from ch1_batch1 import MINE

OUT = p.ROOT / "art" / "chapter1" / "tiles" / "mines3" / "variants"
OBJECTS = {
    "rock_wall": (MINE + "a straight section of rough dark grey rock tunnel wall, a solid block of stone one tile wide, "
                  "flat top edge, jagged rock face with cracks and a few small ore veins, no timber, no door", 64, 96),
    "rock_wall_timber": (MINE + "a straight section of rough dark grey rock tunnel wall with one old wooden support beam "
                         "set against it, a solid block of stone one tile wide, flat top", 64, 96),
    "rock_low": (MINE + "a low ridge of rough dark grey rock and rubble at the edge of a tunnel, knee high, one tile wide", 64, 64),
}


# Объекты выше вышли комнатами с дверью и факелом; стена — куб скалы через create-isometric-tile (block).
BLOCKS = {
    "rock_block": "solid cube of rough natural dark grey rock, cracked uneven rock faces on all visible sides, "
                  "a few thin rusty ore veins, the rock wall of a mine tunnel, no bricks, no door, no torch, no floor",
    "rock_block_ore": "solid cube of rough natural dark grey rock with a small vein of dull copper ore, cracked faces, "
                      "the rock wall of a mine tunnel, no bricks, no door, no torch, no floor",
}


def block(name, seed):
    out = OUT / f"{name}_{seed}.png"
    if out.exists():
        return out
    return p.iso_tile(name, BLOCKS[name] + ", " + p.STYLE_ISO, out, shape="block", seed=seed)


def one(name, spec, seed):
    out = OUT / f"{name}_{seed}.png"
    if out.exists():
        return out
    d, w, h = spec
    return p.map_object(name, d + ", " + ISO + p.STYLE_ISO, out, w, h, seed=seed)


if __name__ == "__main__":
    args = sys.argv[1:]
    seeds = (3, 4) if args[:1] == ["--reroll"] else (1, 2)
    names = set(args[1:]) if args[:1] == ["--reroll"] else set(OBJECTS)
    if args[:1] == ["--blocks"]:
        futs = lambda ex: [ex.submit(block, n, s) for n in BLOCKS for s in (1, 2)]
    else:
        futs = lambda ex: [ex.submit(one, n, OBJECTS[n], s) for n in OBJECTS if n in names for s in seeds]
    with cf.ThreadPoolExecutor(4) as ex:
        for f in cf.as_completed(futs(ex)):
            try:
                print("ok", f.result().name, flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
    print(p.balance()["subscription"])
