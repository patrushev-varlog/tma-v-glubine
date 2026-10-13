"""Пробные сцены 8×8 из тайлов пролога → previews/<сцена>_scene.png. Проверка стыков, масштаба и света.

    python3 art/tools/scene_preview.py [village_night village_morning temple]
"""
import sys
from PIL import Image
from pathlib import Path

A = Path(__file__).resolve().parents[1]
C = A / "prologue/characters"
W1 = A / "wave1/characters"
N = 8
HERO = C / "hero_fighter_m/composited/idle/south-east/00.png"
ROT = lambda n, d: C / n / "base/Idle/rotations" / f"{d}.png"
VILLAGE = ["ggggpggg", "ggggpggg", "ggggpggg", "gggpgggg", "ggpggggg", "gpggooog", "pgggooog", "pggggggg"]
SCENES = {
 "village_night": dict(
    map=VILLAGE, key={"p": "floor_path", "g": "floor_grass", "o": "floor_garden"}, bg=(16, 16, 26),
    objs={(1, 1): "house", (6, 1): "house_burning", (3, 3): "well", (0, 4): "woodpile", (7, 3): "bell_tower",
          (4, 3): "fence", (4, 4): "fence", (4, 5): "fence", (3, 5): "tools"},
    chars={(2, 5): HERO, (4, 2): W1 / "zombie/rotations/north-west.png", (5, 2): ROT("parishioner_m", "north-west"),
           (1, 6): ROT("neighbor", "north-east")}),
 "village_morning": dict(
    map=["ggggrggg", "gaaarggg", "gaaarggg", "gggrgggg", "ggrggggg", "grggooog", "rgggooog", "rggggggg"],
    key={"p": "floor_path", "g": "floor_grass", "o": "floor_garden", "a": "floor_ash", "r": "floor_ruts"}, bg=(58, 60, 66),
    objs={(1, 1): "house_burned", (6, 1): "house", (3, 3): "well", (0, 4): "woodpile", (7, 3): "bell_tower",
          (4, 3): "fence", (4, 4): "fence", (4, 5): "fence", (5, 3): "grave", (2, 6): "cart_abandoned",
          (3, 6): "list_scrap", (6, 6): "cellar_hatch"},
    chars={(2, 4): HERO, (3, 5): ROT("oldrik", "north-west"), (5, 5): ROT("neighbor_woman", "south-west")}),
 "gate": dict(
    map=["pppppppp", "mmmmmmmm", "mmsmmmum", "mmmmmmmm", "mumcccmm", "mmmcccsm", "mmmcccmm", "mmmmmmmm"],
    key={"m": "floor_mud", "s": "floor_straw", "u": "floor_puddle", "c": "floor_cobble", "p": "floor_mud"}, bg=(14, 14, 22),
    objs={(0, 0): "palisade", (1, 0): "palisade", (2, 0): "gatepost", (5, 0): "gatepost", (6, 0): "palisade", (7, 0): "palisade",
          (1, 2): "prison_cart", (6, 2): "tent", (3, 2): "campfire", (0, 4): "crates", (7, 5): "boulder",
          (4, 3): "bound_villagers", (6, 4): "hitching_post", (2, 6): "list_scrap"},
    chars={(4, 5): HERO, (3, 5): ROT("hero_cleric_f", "south-east"), (5, 6): W1 / "garret/unarmed/composited2/idle/south-east/00.png",
           (4, 1): W1 / "overseer_chief/rotations/south-west.png", (2, 3): W1 / "overseer/rotations/south-west.png",
           (6, 3): W1 / "skeleton_archer/rotations/south-west.png"}),
 "temple": dict(
    map=["ffffffff", "fdffffdf", "ffffffff", "fffsffff", "ffffffff", "ffffffff", "fdfffffd", "ffffffff"],
    key={"f": "floor_flagstone", "d": "floor_debris", "s": "floor_scorched"}, bg=(14, 13, 18),
    objs={(3, 0): "altar", (2, 0): "candelabrum", (5, 0): "candelabrum", (1, 2): "column", (6, 2): "column",
          (1, 5): "column", (6, 5): "column", (2, 4): "pew", (5, 4): "pew_broken", (2, 6): "pew", (5, 6): "roof_debris"},
    chars={(3, 5): HERO, (4, 3): W1 / "irena/rotations/south-east.png" if (W1 / "irena/rotations/south-east.png").exists() else None,
           (4, 1): ROT("parishioner_f", "south-west"), (6, 3): ROT("parishioner_m", "south-west")}),
}


def render(name):
    sc = SCENES[name]
    T = A / "prologue/tiles" / name
    Wd, H = N * 64 + 64, N * 32 + 220
    S = Image.new("RGBA", (Wd, H), sc["bg"] + (255,))
    ox, oy = Wd // 2 - 32, 150
    pos = lambda x, y: (ox + (x - y) * 32, oy + (x + y) * 16)
    for s in range(2 * N):
        for x in range(N):
            y = s - x
            if 0 <= y < N:
                px, py = pos(x, y)
                S.alpha_composite(Image.open(T / f"{sc['key'][sc['map'][y][x]]}.png").convert("RGBA"), (px, py - 22))
    for s in range(2 * N):
        for x in range(N):
            y = s - x
            if not (0 <= y < N):
                continue
            px, py = pos(x, y)
            f = sc["objs"].get((x, y)) or sc["chars"].get((x, y))
            if not f:
                continue
            p = T / f"{f}.png" if isinstance(f, str) else f
            if not p.exists():
                continue
            im = Image.open(p).convert("RGBA")
            bb = im.getbbox()
            S.alpha_composite(im, (px + 32 - im.width // 2, py + 18 - bb[3] + (0 if isinstance(f, str) else 2)))
    S = S.resize((S.width * 2, S.height * 2), Image.NEAREST)
    out = A / f"prologue/previews/{name}_scene.png"
    S.save(out)
    return out


if __name__ == "__main__":
    for n in sys.argv[1:] or SCENES:
        print(render(n))
