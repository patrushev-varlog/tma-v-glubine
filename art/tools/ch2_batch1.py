"""Глава 2, партия 1: пробы тайлсета затопленных выработок и двух персонажей перед массовой генерацией.

Тайлы и объекты — по два seed в art/chapter2/tiles/<набор>/variants/<имя>_<seed>.png, отобранный
копируется в art/chapter2/tiles/<набор>/<имя>.png. Персонажи — основы в стиле Гаррета (как ch1_batch2.py).

    python3 art/tools/ch2_batch1.py [tiles|chars|набор ...]     # --reroll имя... — ещё seed 3 и 4
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import ISO, FLAT
from ch1_batch2 import NO_SHADOW, EMPTY

TILES = p.ROOT / "art" / "chapter2" / "tiles"
CHARS_OUT = p.ROOT / "art" / "chapter2" / "characters"
FLOOD = "inside a flooded underground mine, cold dim lantern light, wet dark grey stone, black still water, "
SETS = {
 "flooded": {
  "tiles": {
   "floor_wade": FLAT + "waist-deep still black water with a thin film of rust and a faint reflection of lantern light, flooded mine tunnel floor seen through dark water, low contrast, seamless edges",
   "floor_wet": FLAT + "wet dark grey mine stone floor with shallow puddles and a slick of rusty mud, dim cold light, low contrast, seamless edges",
   "floor_deep": FLAT + "deep black water surface with very faint ripples, nothing visible underneath, very low contrast, seamless edges",
  },
  "objects": {
   "sluice_gate": (FLOOD + "huge ancient dwarven sluice gate: a massive black iron shutter set in a carved stone wall, angular deep-cut runes above it, a big iron lever and a heavy chain, water up to its base", 128, 128),
   "pump_wheel": (FLOOD + "giant rusty iron pump wheel of an old pumping station on stone pillars, thick pipes going into the water", 96, 96),
   "flatboat": (FLOOD + "a long narrow wooden flat-bottomed boat loaded with lashed wooden crates, floating, a pole lying across it", 96, 64),
   "smuggler_desk": (FLOOD + "a merchant's writing desk on a wooden platform: ledgers, a brass lamp, a strongbox and a stack of letters under a heavy paperweight", 64, 64),
   "shrine_altar": (FLOOD + "a small rough stone altar covered in old river silt, a single lit candle burning warm yellow on top", 64, 64),
  },
 },
}
CHARS = {
 "drowned_m": "a drowned undead man risen from black mine water, bloated grey-blue skin, soaked rags of a miner's shirt dripping water, long wet hair plastered to the face, milky white eyes, strands of dark weed, reaching forward with bare hands, ",
 "renna": "a short sharp-featured woman smuggler boss in her fifties, neatly cropped grey hair, fitted dark-green man's doublet with brass buttons, high boots, a thin rapier at the hip, ledger under one arm, cool amused face, " + EMPTY,
}


def one(kind, s, name, spec, seed):
    out = TILES / s / "variants" / f"{name}_{seed}.png"
    if out.exists():
        return out
    if kind == "tiles":
        return p.iso_tile(name, spec + ", " + p.STYLE_ISO, out, seed=seed)
    d, w, h = spec
    return p.map_object(name, d + ", " + ISO + p.STYLE_ISO, out, w, h, seed=seed)


def char(name, desc):
    if (CHARS_OUT / name / "id.txt").exists():
        return name, "exists", 0
    cid, j = p.create_character(name, desc + NO_SHADOW + p.STYLE_CHAR)
    p.character_zip(cid, CHARS_OUT / name / "base")
    (CHARS_OUT / name / "id.txt").write_text(cid + "\n")
    return name, cid, (j.get("usage") or {}).get("generations")


if __name__ == "__main__":
    args = sys.argv[1:]
    jobs, chars = [], []
    if args[:1] == ["--reroll"]:
        names = set(args[1:])
        jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                if n in names for seed in (3, 4)]
    else:
        what = args or ["tiles", "chars"]
        if "tiles" in what or any(a in SETS for a in what):
            sets = [a for a in what if a in SETS] or list(SETS)
            jobs = [(k, s, n, sp, seed) for s in sets for k in ("tiles", "objects") for n, sp in SETS[s][k].items() for seed in (1, 2)]
        if "chars" in what:
            chars = list(CHARS)
    with cf.ThreadPoolExecutor(4) as ex:
        fs = [ex.submit(one, *j) for j in jobs] + [ex.submit(char, n, CHARS[n]) for n in chars]
        for f in cf.as_completed(fs):
            try:
                r = f.result()
                print("ok", r.name if hasattr(r, "name") else r, flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
