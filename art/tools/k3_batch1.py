"""K3, партия 1: основы 6 героев (волшебница уже есть) и пробный набор брода."""
import sys, json, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p

OUT = p.ROOT / "art" / "prologue"
PAL = p.ROOT / "art" / "palette" / "resurrect-64.png"
EMPTY = "both hands empty, fists clenched, no weapon in hands, no sheaths, "

HEROES = {
 "hero_fighter_m": "a man in his early thirties, villager who once served as a soldier, short brown hair, stubble, dented steel breastplate over a padded quilted gambeson, short dark-blue cloak pinned at the shoulder, round wooden shield with an iron rim strapped to the left forearm, worn boots, determined, " + EMPTY,
 "hero_fighter_f": "a woman in her early thirties, villager who once served as a soldier, brown hair cut short at the neck, dented steel breastplate over a padded quilted gambeson, short dark-blue cloak pinned at the shoulder, round wooden shield with an iron rim strapped to the left forearm, worn boots, determined, " + EMPTY,
 "hero_rogue_m": "a lean man in his early thirties, rogue, short dark hair, dark leather armor with the hood down, dark-blue hood lining, dark face scarf pulled down around the neck, fitted dark trousers and soft boots, wary crouched-ready stance, " + EMPTY,
 "hero_rogue_f": "a lean woman in her early thirties, rogue, dark hair tied back, dark leather armor with the hood down, dark-blue hood lining, dark face scarf pulled down around the neck, fitted dark trousers and soft boots, wary crouched-ready stance, " + EMPTY,
 "hero_cleric_m": "a man in his early thirties, village priest, close-cropped dark hair, short dark beard, grey-white vestments over a chainmail shirt, dark-blue stole over the shoulders, small wooden candle-flame pendant, small round wooden shield with a painted candle-flame symbol strapped to the left forearm, calm, " + EMPTY,
 "hero_cleric_f": "a woman in her early thirties, village priestess, hair under a simple grey head scarf, grey-white vestments over a chainmail shirt, dark-blue stole over the shoulders, small wooden candle-flame pendant, small round wooden shield with a painted candle-flame symbol strapped to the left forearm, calm, " + EMPTY,
}

FORD_TILES = {
 "floor_grass": "wet riverside grass with pebbles, dusk, low contrast, seamless edges",
 "water_shallow": "shallow clear stream water over pebbles with a few ripples, dusk light, seamless edges",
 "water_deep": "darker deeper stream water with a current, seamless edges",
 "bank_mud": "muddy stream bank with reeds, seamless edges",
}
FORD_OBJECTS = {
 "campfire": ("isometric campfire with logs, a cooking pot on a tripod, bedrolls nearby", 64, 64),
 "bushes": ("isometric dense dark green bushes, ambush cover", 64, 64),
 "fallen_tree": ("isometric fallen tree trunk with moss lying diagonally", 64, 64),
 "boulder": ("isometric large mossy boulder", 64, 64),
 "willow": ("isometric willow tree trunk with drooping branches", 64, 128),
}


def hero(name, desc):
    cid, j = p.create_character(name, desc + p.STYLE_CHAR)
    p.character_zip(cid, OUT / "characters" / name / "base")
    return name, cid, (j.get("usage") or {}).get("generations")


def tile(name, desc):
    p.iso_tile(name, desc + ", " + p.STYLE_ISO, OUT / "tiles" / "ford" / f"{name}.png")
    return name


def obj(name, spec):
    d, w, h = spec
    p.map_object(name, d + ", dusk, " + p.STYLE_ISO, OUT / "tiles" / "ford" / f"{name}.png", w, h)
    return name


if __name__ == "__main__":
    with cf.ThreadPoolExecutor(8) as ex:
        futs = [ex.submit(hero, n, d) for n, d in HEROES.items()]
        futs += [ex.submit(tile, n, d) for n, d in FORD_TILES.items()]
        futs += [ex.submit(obj, n, s) for n, s in FORD_OBJECTS.items()]
        for f in cf.as_completed(futs):
            try:
                print("ok", f.result(), flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
    print(p.balance()["subscription"])
