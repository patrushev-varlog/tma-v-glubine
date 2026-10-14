"""Глава 4: отобранные варианты тайлсета кузниц плоти → art/chapter4/tiles/forge/<имя>.png и пробная сцена
→ art/chapter4/previews/forge_scene.png (как ch3_preview.py).

    python3 art/tools/ch4_preview.py
"""
import shutil
from PIL import Image
from pathlib import Path

A = Path(__file__).resolve().parents[1]
T = A / "chapter4/tiles/forge"
C = A / "prologue/characters"
C4 = A / "chapter4/characters"
"""floor_works_5, floor_grate_5 — floor_works_1, floor_grate_1 приглушённые (цвет 0.35, яркость 0.72, теплее);
wall_block_b5, wall_pipes_b5 — кубы *_b2 так же (яркость 0.85); floor_molten_5 — floor_molten_2, холодный камень в цвет пола."""
PICK = {"floor_works": "floor_works_5", "floor_molten": "floor_molten_5", "floor_grate": "floor_grate_5",
        "vat": "vat_2", "anatomy_table": "anatomy_table_2", "cage": "cage_2", "ladle": "ladle_1",
        "conveyor": "conveyor_2", "names_wall": "names_wall_1", "smithy": "smithy_2", "gong": "gong_1",
        "brazier": "brazier_1", "stairs_up": "stairs_up_2", "clerk_desk": "clerk_desk_2",
        "report_shelf": "report_shelf_2", "window_works": "window_works_1", "safe": "safe_2",
        "locked_drawer": "locked_drawer_1", "armory_door": "armory_door_2", "weapon_rack": "weapon_rack_1",
        "store_book": "store_book_2", "door_bright": "door_bright_1", "master_table": "master_table_2",
        "cupola_door": "cupola_door_2", "slag_heap": "slag_heap_2", "furnace": "furnace_1",
        "wall_block": "wall_block_b5", "wall_pipes": "wall_pipes_b5"}
N = 9
SCENE = dict(
    map=["wwwwwwwww", "wwgwwwgww", "wwwwwwwww", "mmmmwwmmm", "wwwwwwwww", "wwwgwwwgw", "wwwwwwwww", "wwwwwwwww", "wwwwwwwww"],
    key={"w": T / "floor_works.png", "g": T / "floor_grate.png", "m": T / "floor_molten.png"},
    objs={(2, 0): T / "wall_block.png", (3, 0): T / "wall_pipes.png", (5, 0): T / "wall_block.png",
          (6, 0): T / "wall_pipes.png", (0, 0): T / "names_wall.png", (8, 0): T / "furnace.png",
          (0, 2): T / "vat.png", (0, 5): T / "cage.png", (2, 2): T / "brazier.png", (4, 1): T / "ladle.png",
          (1, 6): T / "anatomy_table.png", (6, 6): T / "conveyor.png", (8, 4): T / "slag_heap.png",
          (0, 8): T / "armory_door.png", (8, 2): T / "gong.png", (4, 7): T / "master_table.png"},
    chars={(3, 5): C / "hero_fighter_m/composited/idle/south-east/00.png",
           (2, 4): C / "hero_cleric_f/base/Idle/rotations/south-east.png",
           (5, 2): C4 / "dead_soldier/base/Idle/rotations/south-west.png",
           (6, 3): C4 / "vat_overseer/base/Idle/rotations/south-west.png",
           (7, 5): C4 / "gessar/base/Idle/rotations/south-west.png",
           (6, 5): C4 / "stitched/base/Idle/rotations/south-west.png",
           (5, 7): C4 / "foundry_dead/base/Idle/rotations/south-west.png",
           (7, 7): C4 / "executioner/base/Idle/rotations/south-west.png"})


def main():
    for name, src in PICK.items():
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
    out = A / "chapter4/previews/forge_scene.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    S.save(out)
    print(out)


if __name__ == "__main__":
    main()
