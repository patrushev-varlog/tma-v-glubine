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
"""wall_block_b5 — куб wall_runes_b2 в палитре floor_hall_5 (по яркости, ×0.92); wall_runes_b5 — он же с полосой
вырезанных рун (рисованы); floor_chasm_5 — floor_chasm_4, контраст 0.35, яркость 0.55; rune_column_5 — rune_column_1 (цвет 0.6, яркость 0.68).
floor_slab_5 — floor_slab_3 приглушённый (0.35, 0.8); bones_5 — три скелета из bones_4 (один отражён)."""
EXTRA = {"floor_chasm": "floor_chasm_5", "wall_block": "wall_block_b5", "wall_runes": "wall_runes_b5",
         "rune_column": "rune_column_5", "stone_niche": "stone_niche_2", "rune_brazier": "rune_brazier_1",
         "rubble": "rubble_2", "anvil": "anvil_1", "steel_chest": "steel_chest_2", "coal_heap": "coal_heap_2",
         "brew_door": "brew_door_2", "scribe_desk": "scribe_desk_2", "child_tablets": "child_tablets_4",
         "floor_slab": "floor_slab_5", "bones": "bones_5", "warhammer": "warhammer_1"}
N = 9
SCENE = dict(
    map=["hhhhhhhhh", "hhrhhhhrh", "hhhhhhhhh", "hhhhrhhhh", "hhhhhhhhh", "hrhhhhhrh", "hhhhhhhcc", "hhhhhrhcc", "hhhhhhhcc"],
    key={"h": T / "floor_hall.png", "r": T / "floor_rune.png", "c": T / "floor_chasm.png"},
    objs={(0, 0): T / "rune_arch.png", (4, 0): T / "riddle_door.png", (0, 4): T / "tablet_shelf.png",
          (0, 6): T / "tablet_shelf.png", (8, 0): T / "great_forge.png",
          (2, 0): T / "wall_block.png", (3, 0): T / "wall_runes.png", (6, 0): T / "wall_block.png",
          (7, 0): T / "wall_runes.png", (0, 2): T / "stone_niche.png", (0, 8): T / "brew_door.png",
          (6, 1): T / "anvil.png", (8, 2): T / "coal_heap.png", (8, 3): T / "steel_chest.png",
          (3, 3): T / "rune_column.png", (3, 7): T / "rune_column.png", (2, 2): T / "rune_brazier.png",
          (1, 3): T / "scribe_desk.png", (0, 5): T / "child_tablets.png", (4, 4): T / "floor_slab.png",
          (5, 7): T / "rubble.png", (6, 8): T / "bones.png", (4, 2): T / "warhammer.png"},
    chars={(3, 5): C / "hero_fighter_m/composited/idle/south-east/00.png",
           (2, 6): C / "hero_cleric_f/base/Idle/rotations/south-east.png",
           (5, 2): C3 / "stone_guardian/base/Idle/rotations/south-west.png",
           (6, 4): C3 / "dwarf_dead/base/Idle/rotations/south-west.png",
           (7, 2): C1 / "smith/base/Idle/rotations/north-west.png",
           (5, 5): C3 / "torvin/base/Idle/rotations/south-west.png"})


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
