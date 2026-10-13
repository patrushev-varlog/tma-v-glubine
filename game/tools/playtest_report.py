#!/usr/bin/env python3
"""Сводка журналов плейтеста (docs/PLAYTEST.md): один файл playtest.jsonl на тестера.

    python3 game/tools/playtest_report.py tester1.jsonl tester2.jsonl ...

Печатает по каждому тестеру: класс и сложность, минуты на каждую сцену, поражения в каждом бою,
дошёл ли до конца демо и где вышел. Внизу — общая таблица боёв и сцен: где застревают.
"""
import json
import sys
from collections import defaultdict

SCENES = ["evening", "raid", "ashes", "temple", "deserter", "column", "interrogation_scene"]


def load(path):
    rows = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
    return rows


def tester(path):
    rows = load(path)
    scene_min = defaultdict(float)
    losses = defaultdict(int)
    wins = {}
    cur, since = None, None
    out = {"name": path, "class": "", "difficulty": "", "demo_end": False, "quit_at": "", "choice": ""}
    for r in rows:
        ev, t = r.get("ev"), r.get("t", 0)
        # Время сцены вместе с её боями; запуск без выхода (вылет) время не засчитывает.
        if ev in ("scene", "load", "quit", "demo_end") and cur is not None and since is not None:
            scene_min[cur] += (t - since) / 60
        if ev == "launch":
            cur, since = None, None
        elif ev == "new_game":
            out["class"], out["difficulty"] = r.get("class", ""), r.get("difficulty", "")
        elif ev == "scene":
            cur, since = r.get("scene"), t
        elif ev == "load":
            cur, since = r.get("scene"), t
        elif ev == "battle_lost":
            losses[r.get("battle")] += 1
        elif ev == "battle_won":
            wins[r.get("battle")] = r.get("rounds")
        elif ev == "demo_end":
            out["demo_end"] = True
            out["choice"] = r.get("choice", "")
            cur = None
        elif ev == "quit":
            out["quit_at"] = r.get("battle") or r.get("scene") or "меню"
            cur = None
    out.update(scene_min=dict(scene_min), losses=dict(losses), wins=wins)
    return out


def main(paths):
    if not paths:
        print(__doc__)
        return 2
    all_t = [tester(p) for p in paths]
    for t in all_t:
        print(f"\n== {t['name']}: {t['class']}, {t['difficulty']}, конец демо: {'да' if t['demo_end'] else 'нет'}"
              f"{', выбор у колонны: ' + t['choice'] if t['choice'] else ''}"
              f"{', вышел: ' + t['quit_at'] if t['quit_at'] and not t['demo_end'] else ''}")
        for s in SCENES:
            if s in t["scene_min"]:
                print(f"   {s:22} {t['scene_min'][s]:5.1f} мин")
        for b, n in sorted(t["losses"].items()):
            print(f"   поражений в {b}: {n}")
    print("\n== Все тестеры")
    print(f"   дошли до конца демо: {sum(t['demo_end'] for t in all_t)} из {len(all_t)}")
    for s in SCENES:
        vals = [t["scene_min"][s] for t in all_t if s in t["scene_min"]]
        if vals:
            print(f"   {s:22} среднее {sum(vals) / len(vals):5.1f} мин, максимум {max(vals):5.1f}")
    battles = sorted({b for t in all_t for b in list(t["losses"]) + list(t["wins"])})
    for b in battles:
        lost = sum(t["losses"].get(b, 0) for t in all_t)
        won = sum(1 for t in all_t if b in t["wins"])
        print(f"   {b:18} побед {won}, поражений {lost}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
