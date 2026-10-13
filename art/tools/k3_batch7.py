"""K3, партия 7: деревня утром (сцена 3) и храм (бой 2), PROMPTS.md 3.7.

Каждый ассет — два seed в <набор>/variants/<имя>_<seed>.png; отобранный копируется в <набор>/<имя>.png.
Утренние полы и постройки, общие с ночью, делаются перекраской (`morning.py`), здесь только новое.

    python3 art/tools/k3_batch7.py [набор ...]
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import ISO, FLAT

TILES = p.ROOT / "art" / "prologue" / "tiles"
MORNING = "grey cold morning light, overcast, "
TEMPLE = "inside a ruined village temple, dim candlelight, "
SETS = {
 "village_morning": {
  "tiles": {
   "floor_ash": FLAT + "grey ash and charred straw over dirt, morning, low contrast, seamless edges",
   "floor_ruts": FLAT + "muddy ground with two deep cart wheel ruts running straight across the tile diagonally, morning, low contrast, seamless edges",
  },
  "objects": {
   "house_burned": (MORNING + "ruins of a burned-down cottage: only a blackened low stone foundation, a few charred standing wooden posts and fallen black beams, no roof, no fire, no flames, thin grey smoke, the ruins fill the whole canvas", 160, 160),
   "grave": (MORNING + "fresh grave mound of dark earth with a simple wooden marker", 64, 48),
   "cart_abandoned": (MORNING + "abandoned broken wooden cart with one wheel off lying beside it, a dull red crown-in-circle emblem painted on the side", 96, 96),
   "list_scrap": (MORNING + "a single small torn sheet of paper with neat handwritten lines lying flat in the mud", 32, 32),
   "cellar_hatch": (MORNING + "flat wooden trapdoor lying flat on the ground, a square cellar door in the ground, one half lifted open showing a dark hole, no building, no walls, no roof", 64, 48),
  },
 },
 "temple": {
  "tiles": {
   "floor_flagstone": FLAT + "cracked grey temple flagstones with a faded painted pattern and candle wax drips, dim, low contrast, seamless edges",
   "floor_debris": FLAT + "grey temple flagstones with scattered broken roof tiles and dust, dim, low contrast, seamless edges",
   "floor_scorched": FLAT + "grey temple flagstones with a black scorched circle burned into the stone, dim, low contrast, seamless edges",
  },
  "objects": {
   "pew": (TEMPLE + "long plain wooden church pew bench with a backrest, seats four people", 96, 96),
   "pew_broken": (TEMPLE + "long wooden church pew bench with a backrest broken in the middle, two halves lying at an angle, splinters", 96, 96),
   "altar": (TEMPLE + "stone altar with a carved candle-flame symbol on the front and many melted lit candles on top", 64, 64),
   "column": (TEMPLE + "cracked round stone column with a fallen chunk at its base", 64, 96),
   "candelabrum": (TEMPLE + "tall iron floor candelabrum with lit candles", 32, 64),
   "roof_debris": (TEMPLE + "large heap of fallen charred wooden roof beams and broken clay roof tiles lying on the floor, the heap fills the canvas", 96, 96),
  },
 },
}


def one(kind, s, name, spec, seed):
    out = TILES / s / "variants" / f"{name}_{seed}.png"
    if out.exists():
        return out
    if kind == "tiles":
        return p.iso_tile(name, spec + ", " + p.STYLE_ISO, out, seed=seed)
    d, w, h = spec
    return p.map_object(name, d + ", " + ISO + p.STYLE_ISO, out, w, h, seed=seed)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["--reroll"]:  # --reroll имя... : ещё seed 3 и 4
        names = set(args[1:])
        jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                if n in names for seed in (3, 4)]
    else:
        sets = args or list(SETS)
        jobs = [(k, s, n, sp, seed) for s in sets for k in ("tiles", "objects") for n, sp in SETS[s][k].items() for seed in (1, 2)]
    with cf.ThreadPoolExecutor(4) as ex:
        for f in cf.as_completed([ex.submit(one, *j) for j in jobs]):
            try:
                print("ok", f.result().name, flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
