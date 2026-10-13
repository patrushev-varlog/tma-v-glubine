#!/usr/bin/env python3
"""Копирует готовую графику из art/ (её ведёт тред графики) в проект игры.

    python3 game/tools/import_art.py          # скопировать то, что изменилось
    python3 game/tools/import_art.py --check  # код 1, если копия в game/art устарела

Портреты: art/portraits/<id>/{base_128,base_64,dark_*}.png → game/art/portraits/<id>/.
Первые варианты (<id>_v1) и исходники не копируются. После копирования нужен
`godot --headless --path game --import`, чтобы появились .import рядом с PNG.
"""
import filecmp
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SRC = REPO / "art" / "portraits"
DST = REPO / "game" / "art" / "portraits"
FILES = ("base_128.png", "base_64.png", "dark_1_dusk.png", "dark_2_gloom.png", "dark_3_abyss.png")


def main() -> int:
    check = "--check" in sys.argv
    stale = []
    for d in sorted(p for p in SRC.iterdir() if p.is_dir()):
        if d.name == "source" or d.name.endswith("_v1"):
            continue
        for name in FILES:
            src = d / name
            if not src.exists():
                continue
            dst = DST / d.name / name
            if dst.exists() and filecmp.cmp(src, dst, shallow=False):
                continue
            stale.append(f"{d.name}/{name}")
            if not check:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(src, dst)
    if stale:
        print(("Устарело: " if check else "Скопировано: ") + ", ".join(stale))
    else:
        print("Портреты в game/art совпадают с art/")
    return 1 if check and stale else 0


if __name__ == "__main__":
    sys.exit(main())
