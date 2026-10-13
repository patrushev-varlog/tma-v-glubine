"""K3, партия 6: деревня Эшмур ночью (бой 1, PROMPTS.md 3.7). По одному варианту; удачное идёт в tiles/village_night/."""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p

OUT = p.ROOT / "art" / "prologue" / "tiles" / "village_night"
ISO = "isolated object, standing directly on the ground, no base, no platform, no ground tile under it, no pedestal, transparent background around it, "
FLAT = "flat thin ground surface filling the whole tile edge to edge, no raised sides, no border, no rim, "
NIGHT = "night, cold moonlight with warm firelight from the left, "

TILES = {
 "floor_path": (FLAT + "packed dirt village path with grass tufts and a small puddle, night, low contrast, seamless edges", "thin tile"),
 "floor_grass": (FLAT + "trampled muted green grass with a few fallen brown leaves, night, low contrast, seamless edges", "thin tile"),
 "floor_garden": (FLAT + "dug-up dark soil with small cabbages growing in it, night, low contrast, seamless edges", "thin tile"),
 "edge": ("ground block with a dark earth cross-section on the sides and trampled grass on top, night", "thick tile"),
}
OBJECTS = {
 "house": ("small timber-and-wattle village cottage with a thatched roof and a small shuttered window glowing warm", 128, 128),
 "house_burning": ("small timber-and-wattle village cottage on fire, bright flames on the thatched roof, sparks", 128, 128),
 "fence": ("short straight section of a woven wattle fence", 64, 64),
 "woodpile": ("stacked firewood logs under a small lean-to roof", 64, 64),
 "well": ("old round stone village well with a wooden crank and a bucket", 64, 64),
 "bell_tower": ("base of a wooden village bell tower with a hanging bell rope", 64, 96),
 "tools": ("a pitchfork and a rake leaning on a wooden fence post", 32, 48),
}


def tile(name, spec):
    d, shape = spec
    return p.iso_tile(name, d + ", " + p.STYLE_ISO, OUT / f"{name}.png", shape=shape)


def tile_seed(name, spec, seed):
    d, shape = spec
    return p.iso_tile(name, d + ", " + p.STYLE_ISO, OUT / "variants" / f"{name}_{seed}.png", shape=shape, seed=seed)


def obj(name, spec, seed=None):
    d, w, h = spec
    out = OUT / (f"variants/{name}_{seed}.png" if seed is not None else f"{name}.png")
    return p.map_object(name, d + ", " + ISO + NIGHT + p.STYLE_ISO, out, w, h, seed=seed)


def reroll(names, seeds=(1, 2)):
    """Повторы с разными seed в variants/ — для отбора."""
    jobs = [(tile_seed if n in TILES else obj, n, (TILES | OBJECTS)[n], s) for n in names for s in seeds]
    with cf.ThreadPoolExecutor(4) as ex:
        for f in cf.as_completed([ex.submit(fn, n, sp, s) for fn, n, sp, s in jobs]):
            try:
                print("ok", f.result().name, flush=True)
            except Exception as e:
                print("ERR", e, flush=True)


if __name__ == "__main__":
    if sys.argv[1:2] == ["--reroll"]:
        reroll(sys.argv[2:])
        sys.exit()
    only = set(sys.argv[1:])
    jobs = [(tile, n, s) for n, s in TILES.items()] + [(obj, n, s) for n, s in OBJECTS.items()]
    with cf.ThreadPoolExecutor(4) as ex:
        fs = [ex.submit(f, n, s) for f, n, s in jobs if not only or n in only]
        for f in cf.as_completed(fs):
            try:
                print("ok", f.result().name, flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
