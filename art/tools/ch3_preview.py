"""Глава 3: отобранные варианты тайлсета дварфийских залов → art/chapter3/tiles/dwarf/<имя>.png и пробная
сцена → art/chapter3/previews/dwarf_scene.png (как ch2_preview.py).

    python3 art/tools/ch3_preview.py
"""
import shutil
from PIL import Image
from pathlib import Path

A = Path(__file__).resolve().parents[1]
T = A / "chapter3/tiles/dwarf"
C = A / "prologue/characters"
C1 = A / "chapter1/characters"
C3 = A / "chapter3/characters"
"""floor_hall_5, floor_rune_5 — floor_hall_4, floor_rune_3 с приглушённой насыщенностью (0.38) и яркостью (0.72)."""
PICK = {"floor_hall": "floor_hall_5", "floor_rune": "floor_rune_5", "great_forge": "great_forge_1",
        "riddle_door": "riddle_door_1", "rune_arch": "rune_arch_2", "tablet_shelf": "tablet_shelf_2"}
EXTRA = {}  # имя → вариант, добавляется партиями 2+
N = 9
SCENE = dict(
    map=["hhhhhhhhh", "hhrhhhhrh", "hhhhhhhhh", "hhhhrhhhh", "hhhhhhhhh", "hrhhhhhrh", "hhhhhhhhh", "hhhhhrhhh", "hhhhhhhhh"],
    key={"h": T / "floor_hall.png", "r": T / "floor_rune.png"},
    objs={(0, 0): T / "rune_arch.png", (4, 0): T / "riddle_door.png", (0, 4): T / "tablet_shelf.png",
          (0, 6): T / "tablet_shelf.png", (8, 0): T / "great_forge.png"},
    chars={(3, 5): C / "hero_fighter_m/composited/idle/south-east/00.png",
           (2, 6): C / "hero_cleric_f/base/Idle/rotations/south-east.png",
           (5, 2): C3 / "stone_guardian/base/Idle/rotations/south-west.png",
           (6, 4): C3 / "dwarf_dead/base/Idle/rotations/south-west.png",
           (7, 7): C1 / "smith/base/Idle/rotations/north-west.png"})


def main():
    for name, src in {**PICK, **EXTRA}.items():
        shutil.copy(T / "variants" / f"{src}.png", T / f"{name}.png")
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
    out = A / "chapter3/previews/dwarf_scene.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    S.save(out)
    print(out)


if __name__ == "__main__":
    main()
