#!/usr/bin/env python3
"""Сводная таблица вин-рейтов сюжетных боёв: все классы и обе ветки, с тёмными дарами и без.

Гоняет tools/simulate.gd параллельно (по процессу Godot на бой и класс) и пишет CSV.
    python3 tools/balance_matrix.py --runs 60 --out /tmp/matrix.csv [--battles chapter4_1,chapter5_2] [--gear kit] [--hunt]
Godot берётся из $GODOT или `godot` в PATH. Ориентир «Испытания»: 30–50% без тёмных даров, 50–70% с ними.
"""
import argparse
import csv
import os
import subprocess
from concurrent.futures import ThreadPoolExecutor

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLASSES = ["fighter", "rogue", "cleric", "wizard"]
ARCHS = {"fighter": ["guardian", "berserker"], "rogue": ["assassin", "trickster"],
         "cleric": ["life", "light"], "wizard": ["evoker", "binder"]}

# Бой → варианты (подпись, отряд, флаги). Главы 4–5 без ключа party: отряд из сюжета, Велиор может не прийти.
VARIANTS = {
    "prologue_2": [("", "full", "")],
    "prologue_3": [("", "full", "")],
    "prologue_4_camp": [("", "full", "")],
    "prologue_4_gate": [("", "full", "")],
    "chapter1_1": [("", "full", "")],
    "chapter1_2_riot": [("", "full", "")],
    "chapter1_2_patrol": [("", "full", "")],
    "chapter1_3": [("", "full", ""), ("бунт", "full", "ch1_choice=riot")],
    "ch1_hunt_foreman": [("", "full", "")],
    "chapter2_1": [("", "full", "")],
    "chapter2_2_smugglers": [("", "full", "")],
    "chapter2_2_flooded": [("", "full", "")],
    "chapter2_3": [("", "full", "")],
    "ch2_hunt_priest": [("", "full", "")],
    "chapter3_1": [("", "full", "")],
    "chapter3_2": [("", "full", "")],
    "chapter3_3": [("", "full", "")],
    "chapter4_1": [("", "full", ""), ("", "no_velior", "")],
    "chapter4_2": [("", "full", ""), ("", "no_velior", "")],
    "chapter4_3": [("", "full", ""), ("", "no_velior", "")],
    "chapter4_3_refuse": [("", "full", ""), ("", "no_velior", "")],
    "chapter5_1_garrison": [("", "full", ""), ("", "no_velior", "")],
    "chapter5_2": [("", "full", ""), ("", "no_velior", "")],
    "chapter5_2_raised": [("", "full", ""), ("", "no_velior", "")],
    "chapter5_final_peace": [("", "full", ""), ("", "no_velior", "")],
    "chapter5_final_master": [("", "full", ""), ("", "no_velior", ""),
                              ("без Ирены", "full", "ending=tyrant"), ("без Ирены", "no_velior", "ending=tyrant")],
}


def run(job, args):
    battle, cls, label, party, flags = job
    godot = os.environ.get("GODOT", "godot")
    cmd = [godot, "--headless", "--path", GAME, "-s", "tools/simulate.gd", "--", f"battle={battle}", f"class={cls}",
           "arch=all", f"party={party}", "dark=both", f"runs={args.runs}", f"gear={args.gear}", "diff=trial"]
    if flags:
        cmd.append(f"flags={flags}")
    if args.hunt:
        cmd.append("hunt=1")
    if args.boost:
        cmd.append(f"boost={args.boost}")
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=7200).stdout
    rows = [l.split(" | ") for l in out.splitlines() if l.startswith(battle + " | ")]
    archs = ARCHS[cls] if len(rows) > 2 else [""]
    res = []
    for i, r in enumerate(rows):
        res.append({"battle": battle, "variant": label, "party": party, "class": cls,
                    "arch": archs[i // 2] if archs != [""] else "", "dark": r[5] == "да",
                    "win": int(r[6].rstrip("%")), "rounds": float(r[7]), "down": float(r[8]),
                    "hero_down": int(r[9].split("%")[0])})
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=60)
    ap.add_argument("--battles", default=",".join(VARIANTS))
    ap.add_argument("--gear", default="kit")
    ap.add_argument("--hunt", action="store_true")
    ap.add_argument("--boost", default="")
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 2)
    ap.add_argument("--out", default="-")
    args = ap.parse_args()
    jobs = [(b, c, *v) for b in args.battles.split(",") for v in VARIANTS[b] for c in CLASSES]
    rows = []
    with ThreadPoolExecutor(args.jobs) as ex:
        for res in ex.map(lambda j: run(j, args), jobs):
            rows += res
    f = open(args.out, "w", newline="") if args.out != "-" else None
    w = csv.DictWriter(f or os.sys.stdout, fieldnames=list(rows[0]))
    w.writeheader()
    w.writerows(rows)


if __name__ == "__main__":
    main()
