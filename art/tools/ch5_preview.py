"""Глава 5: отобранные варианты тайлсета дна → art/chapter5/tiles/deep/<имя>.png и пробная сцена зала печати
→ art/chapter5/previews/deep_scene.png (как ch4_preview.py).

    python3 art/tools/ch5_preview.py
"""
import shutil
from PIL import Image, ImageEnhance
from pathlib import Path

A = Path(__file__).resolve().parents[1]
T = A / "chapter5/tiles/deep"
C = A / "prologue/characters"
C5 = A / "chapter5/characters"
PICK = {"floor_descent": "floor_descent_2", "floor_rock": "floor_descent_1", "floor_seal": "floor_seal_2",
        "floor_groove": "floor_seal_1", "floor_core": "floor_seal_core_1",
        "pedestal": "pedestal_2", "plaque": "plaque_1", "council_door": "council_door_1",
        "fallen_guard": "fallen_guard_1", "descent_stairs": "descent_stairs_1", "pale_brazier": "pale_brazier_2",
        "seal_light": "seal_light_1", "wall_bedrock": "wall_bedrock_b2", "wall_seal": "wall_seal_b1"}
"""Пол приглушён, чтобы фигуры читались поверх борозд: насыщенность и яркость (DIM)."""
DIM = {"floor_descent": (0.8, 0.85), "floor_rock": (0.8, 0.85), "floor_seal": (0.8, 0.85)}
N = 9
SCENE = dict(
    map=["sssssssss", "sssgsssss", "ssssgssss", "sssssgsss", "ssggsccss", "sssssgsss", "ssssgssss", "sssgsssss", "sssssssss"],
    key={"s": T / "floor_seal.png", "g": T / "floor_groove.png", "c": T / "floor_core.png"},
    objs={(2, 0): T / "wall_seal.png", (3, 0): T / "wall_seal.png", (5, 0): T / "wall_seal.png",
          (6, 0): T / "wall_seal.png", (0, 0): T / "council_door.png", (8, 0): T / "wall_bedrock.png",
          (0, 2): T / "pedestal.png", (0, 5): T / "pedestal.png", (4, 0): T / "pedestal.png", (2, 2): T / "pale_brazier.png",
          (7, 1): T / "plaque.png", (1, 7): T / "fallen_guard.png", (6, 4): T / "seal_light.png", (0, 8): T / "descent_stairs.png"},
    chars={(3, 5): C / "hero_fighter_m/composited/idle/south-east/00.png",
           (2, 4): C / "hero_cleric_f/base/Idle/rotations/south-east.png",
           (5, 2): C5 / "council_guard/base/Idle/rotations/south-west.png",
           (6, 2): C5 / "council_guard/base/Idle/rotations/south-west.png",
           (7, 5): C5 / "edric/base/Idle/rotations/south-west.png",
           (5, 7): C5 / "sleeper_shade/base/Idle/rotations/south-west.png"})


def main():
    for name, src in PICK.items():
        im = Image.open(T / "variants" / f"{src}.png").convert("RGBA")
        if name in DIM:
            c, b = DIM[name]
            a = im.getchannel("A")
            im = ImageEnhance.Brightness(ImageEnhance.Color(im).enhance(c)).enhance(b)
            im.putalpha(a)
        im.save(T / f"{name}.png")
    sc = SCENE
    Wd, H = N * 64 + 64, N * 32 + 240
    S = Image.new("RGBA", (Wd, H), (12, 12, 18, 255))
    ox, oy = Wd // 2 - 32, 170
    pos = lambda x, y: (ox + (x - y) * 32, oy + (x + y) * 16)
    for s in range(2 * N):
        for x in range(N):
            y = s - x
            if 0 <= y < N:
                px, py = pos(x, y)
                S.alpha_composite(Image.open(sc["key"][sc["map"][y][x]]).convert("RGBA"), (px, py - 22))
    for s in range(2 * N):
        for x in range(N):
            y = s - x
            if not (0 <= y < N):
                continue
            px, py = pos(x, y)
            f = sc["objs"].get((x, y)) or sc["chars"].get((x, y))
            if not f or not f.exists():
                continue
            im = Image.open(f).convert("RGBA")
            bb = im.getbbox()
            S.alpha_composite(im, (px + 32 - im.width // 2, py + 18 - bb[3] + (2 if (x, y) in sc["chars"] else 0)))
    S = S.resize((S.width * 2, S.height * 2), Image.NEAREST)
    out = A / "chapter5/previews/deep_scene.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    S.save(out)
    print(out)


if __name__ == "__main__":
    main()
