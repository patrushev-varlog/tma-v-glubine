"""Глава 1: отобранные варианты тайлсета шахт → art/chapter1/tiles/mines/<имя>.png и пробная сцена 8×8
→ art/chapter1/previews/mines_scene.png (как scene_preview.py для пролога).

    python3 art/tools/ch1_preview.py
"""
import shutil
from PIL import Image
from pathlib import Path

A = Path(__file__).resolve().parents[1]
T = A / "chapter1/tiles/mines"
C = A / "prologue/characters"
W1 = A / "wave1/characters"
PICK = {"floor_stone": "floor_gravel_2", "floor_ore": "floor_stone_2", "floor_rails": "floor_rails_2", "floor_planks": "floor_planks_4",
        "floor_gravel": "floor_gravel_1", "minecart": "minecart_2", "ore_heap": "ore_heap_2", "rockfall": "rockfall_2",
        "scaffold": "scaffold_2", "cage": "cage_3", "winch": "winch_2"}
N = 8
SCENE = dict(
    map=["sssrssss", "sgsrssps", "sssrsspp", "sssrsspp", "ssgrssss", "sssrssss", "sssrssgs", "sssrssss"],
    key={"s": "floor_stone", "r": "floor_rails_b", "p": "floor_planks", "g": "floor_ore"}, bg=(12, 12, 18),
    objs={(0, 0): "timber_support", (5, 0): "timber_support", (3, 1): "minecart", (7, 1): "scaffold", (1, 3): "ore_heap",
          (6, 4): "cage", (0, 6): "rockfall", (6, 7): "winch", (4, 7): "timber_support"},
    chars={(2, 5): C / "hero_fighter_m/composited/idle/south-east/00.png",
           (1, 6): C / "hero_cleric_f/base/Idle/rotations/south-east.png",
           (5, 2): W1 / "overseer/rotations/south-west.png", (4, 3): W1 / "zombie/rotations/south-west.png"})


# Второй набор (mines2: бараки, клеть подъёмника, караулка) — в ту же папку, один набор на главу.
PICK2 = {"bars": "bars_2", "boards": "boards_1", "bunk": "bunk_2", "guard_hut": "guard_hut_2", "lamp_post": "lamp_post_1",
         "lift_cage": "lift_cage_2", "notice_board": "notice_board_2", "tag_box": "tag_box_1", "shaft": "floor_shaft_1"}

# Стены штреков (mines3, ch1_batch3.py --blocks): кубы скалы.
PICK3 = {"rock_block": "rock_block_2", "rock_block_ore": "rock_block_ore_2"}


def main():
    for name, src in PICK.items():
        shutil.copy(T / "variants" / f"{src}.png", T / f"{name}.png")
    for name, src in PICK3.items():
        shutil.copy(A / "chapter1/tiles/mines3/variants" / f"{src}.png", T / f"{name}.png")
    for name, src in PICK2.items():
        shutil.copy(A / "chapter1/tiles/mines2/variants" / f"{src}.png", T / f"{name}.png")
    shutil.copy(A / "anchors/approved/timber_support.png", T / "timber_support.png")
    # Рельсы в генерации идут вдоль оси x; зеркало — вдоль оси y (как плетень fence / fence_b в прологе).
    Image.open(T / "floor_rails.png").transpose(Image.FLIP_LEFT_RIGHT).save(T / "floor_rails_b.png")
    Image.open(T / "bars.png").transpose(Image.FLIP_LEFT_RIGHT).save(T / "bars_b.png")
    sc = SCENE
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
    out = A / "chapter1/previews/mines_scene.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    S.save(out)
    print(out)


if __name__ == "__main__":
    main()
