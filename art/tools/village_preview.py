"""Пробная сцена деревни ночью 8×8 (бой 1 «Облава») из tiles/village_night → previews/village_night_scene.png."""
from PIL import Image
from pathlib import Path

A = Path(__file__).resolve().parents[1]
T = A / "prologue/tiles/village_night"
C = A / "prologue/characters"
W1 = A / "wave1/characters"
N = 8
# p — тропа, g — трава, o — огород
M = ["ggggpggg", "ggggpggg", "ggggpggg", "gggpgggg", "ggpggggg", "gpggooog", "pgggooog", "pggggggg"]
KEY = {"p": "floor_path", "g": "floor_grass", "o": "floor_garden"}
OBJS = {(1, 1): "house", (6, 1): "house_burning", (3, 3): "well", (0, 4): "woodpile", (7, 3): "bell_tower",
        (4, 4): "fence", (5, 4): "fence", (6, 4): "fence", (3, 5): "tools"}
CHARS = {(2, 5): C / "hero_fighter_m/composited/idle/south-east/00.png",
         (4, 2): W1 / "zombie/rotations/north-west.png", (5, 2): C / "parishioner_m/base/Idle/rotations/north-west.png",
         (1, 6): C / "neighbor/base/Idle/rotations/north-east.png"}


def main():
    Wd, H = N * 64 + 64, N * 32 + 200
    S = Image.new("RGBA", (Wd, H), (16, 16, 26, 255))
    ox, oy = Wd // 2 - 32, 130
    pos = lambda x, y: (ox + (x - y) * 32, oy + (x + y) * 16)
    for s in range(2 * N):
        for x in range(N):
            y = s - x
            if 0 <= y < N:
                px, py = pos(x, y)
                S.alpha_composite(Image.open(T / f"{KEY[M[y][x]]}.png").convert("RGBA"), (px, py - 22))
    for s in range(2 * N):
        for x in range(N):
            y = s - x
            if not (0 <= y < N):
                continue
            px, py = pos(x, y)
            f = OBJS.get((x, y)) or CHARS.get((x, y))
            if not f:
                continue
            p = T / f"{f}.png" if isinstance(f, str) else f
            if not p.exists():
                continue
            im = Image.open(p).convert("RGBA")
            bb = im.getbbox()
            S.alpha_composite(im, (px + 32 - im.width // 2, py + 18 - bb[3] + (0 if isinstance(f, str) else 2)))
    S = S.resize((S.width * 2, S.height * 2), Image.NEAREST)
    out = A / "prologue/previews/village_night_scene.png"
    S.save(out)
    return out


if __name__ == "__main__":
    print(main())
