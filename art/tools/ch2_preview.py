"""Глава 2: отобранные варианты тайлсета затопленных выработок → art/chapter2/tiles/flooded/<имя>.png и пробная
сцена → art/chapter2/previews/flooded_scene.png (как ch1_preview.py). Пол шахты — из главы 1.

    python3 art/tools/ch2_preview.py
"""
import shutil
from PIL import Image
from pathlib import Path

A = Path(__file__).resolve().parents[1]
T = A / "chapter2/tiles/flooded"
M = A / "chapter1/tiles/mines"
C = A / "prologue/characters"
C2 = A / "chapter2/characters"
PICK = {"floor_wade": "floor_deep_2", "floor_deep": "floor_deep_4", "floor_wet": "floor_wet_2", "sluice_gate": "sluice_gate_2",
        "pump_wheel": "pump_wheel_2", "flatboat": "flatboat_2", "smuggler_desk": "smuggler_desk_2", "shrine_altar": "shrine_altar_2",
        "cellar_door": "cellar_door_2", "pipes": "pipes_2", "crates": "crates_2", "brazier": "brazier_2",
        "bedding": "bedding_2", "small_lever": "small_lever_1", "grate": "grate_2", "stairs": "stairs_2",
        "rune_pillar": "rune_pillar_2"}
MIRROR = ["pipes", "crates"]  # <имя>_b — зеркальная копия для рядов
N = 9
SCENE = dict(
    map=["sssswwwdd", "swsswwwdd", "sssswwwww", "pppwwwwww", "pppwwwdww", "sspwwwddw", "ssswwwwww", "swsswwwww", "ssssswwww"],
    key={"s": M / "floor_stone.png", "w": T / "floor_wade.png", "d": T / "floor_deep.png", "p": M / "floor_planks.png",
         "W": T / "floor_wet.png"},
    objs={(7, 0): T / "sluice_gate.png", (0, 0): M / "timber_support.png", (1, 3): T / "smuggler_desk.png",
          (3, 0): T / "pump_wheel.png", (7, 5): T / "flatboat.png", (0, 7): T / "shrine_altar.png", (4, 8): M / "timber_support.png"},
    chars={(2, 5): C / "hero_fighter_m/composited/idle/south-east/00.png",
           (1, 6): C / "hero_cleric_f/base/Idle/rotations/south-east.png",
           (1, 2): C2 / "renna/base/Idle/rotations/south-east.png",
           (5, 3): C2 / "drowned_m/base/Idle/rotations/south-west.png",
           (6, 6): C2 / "drowned_m/base/Idle/rotations/north-west.png"})


def main():
    for name, src in PICK.items():
        shutil.copy(T / "variants" / f"{src}.png", T / f"{name}.png")
    for name in MIRROR:
        Image.open(T / f"{name}.png").transpose(Image.FLIP_LEFT_RIGHT).save(T / f"{name}_b.png")
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
    out = A / "chapter2/previews/flooded_scene.png"
    S.save(out)
    print(out)


if __name__ == "__main__":
    main()
