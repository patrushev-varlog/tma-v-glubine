#!/usr/bin/env python3
"""Сборка звука пролога: качает бесплатные паки (CC0, CC-BY), режет и выравнивает громкость, кладёт OGG
в game/audio/ и пишет таблицу лицензий audio/LICENSES.md (art/prologue/ASSETS.md, раздел 7).

    python3 tools/audio_build.py --cache /tmp/audio-cache            # всё
    python3 tools/audio_build.py --cache /tmp/audio-cache --only sfx  # только короткие звуки

Нужны ffmpeg и numpy. Откуда что взято — таблицы SOURCES, SFX, AMBIENT, MUSIC ниже: поменять звук значит
поменять строку и пересобрать. Колокола синтезируются здесь же (synth_bell), у них нет внешнего источника.
"""
import argparse
import json
import pathlib
import re
import shutil
import subprocess
import sys
import urllib.request
import zipfile

import numpy as np

SR = 44100
GAME = pathlib.Path(__file__).resolve().parent.parent
OUT = GAME / "audio"

# --- Источники ----------------------------------------------------------------------------------------
# id: url — архив или файл, page — страница с лицензией, title, author, license.
K = "https://kenney.nl/media/pages/assets/"
O = "https://opengameart.org/sites/default/files/"
OC = "https://opengameart.org/content/"
SOURCES = {
    "k_rpg": {"url": K + "rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip", "page": "https://kenney.nl/assets/rpg-audio",
              "title": "RPG Audio", "author": "Kenney", "license": "CC0"},
    "k_impact": {"url": K + "impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip",
                 "page": "https://kenney.nl/assets/impact-sounds", "title": "Impact Sounds", "author": "Kenney", "license": "CC0"},
    "k_ui": {"url": K + "ui-audio/490d233f68-1677590494/kenney_ui-audio.zip", "page": "https://kenney.nl/assets/ui-audio",
             "title": "UI Audio", "author": "Kenney", "license": "CC0"},
    "medieval1": {"url": O + "medieval_sfx_textures_1_of_2.7z", "page": OC + "medieval-sound-effects-weapon-textures",
                  "title": "Medieval sound effects - Weapon Textures", "author": "MedicineStorm", "license": "CC0"},
    "medieval2": {"url": O + "medieval_sfx_textures_2_of_2.7z", "page": OC + "medieval-sound-effects-weapon-textures",
                  "title": "Medieval sound effects - Weapon Textures", "author": "MedicineStorm", "license": "CC0"},
    "swishes": {"url": O + "swishes.zip", "page": OC + "swishes-sound-pack", "title": "Swishes Sound Pack",
                "author": "artisticdude", "license": "CC0"},
    "zombies": {"url": O + "zombies.zip", "page": OC + "zombies-sound-pack", "title": "Zombies Sound Pack",
                "author": "artisticdude", "license": "CC0"},
    "voices": {"url": O + "Voice%20Effects%20Zombie-Skeleton-Monster%20Human%20Male.zip",
               "page": OC + "zombie-skeleton-monster-voice-effects", "title": "Zombie / Skeleton / Monster Voice Effects",
               "author": "ArcadeParty", "license": "CC0"},
    "bones": {"url": O + "bones_rattle.zip", "page": OC + "bones-rattle", "title": "Bones rattle",
              "author": "congusbongus", "license": "CC0"},
    "dark": {"url": O + "dark_magic.7z", "page": OC + "3-dark-magic-spells", "title": "3 dark magic spells",
             "author": "qubodup", "license": "CC0"},
    "cure": {"url": O + "curemagic.zip", "page": OC + "cure-magic", "title": "Cure Magic", "author": "Someoneman",
             "license": "CC0"},
    "slime": {"url": O + "water-splash-slime-sfx.zip", "page": OC + "40-cc0-water-splash-slime-sfx",
              "title": "40 CC0 water / splash / slime SFX", "author": "rubberduck", "license": "CC0"},
    "horn": {"url": O + "theircoming3_0.ogg", "page": OC + "their-coming-generic-horn-sound",
             "title": "Their Coming (generic horn sound)", "author": "StumpyStrust", "license": "CC0"},
    "fleshy": {"url": O + "fleshy_fight_sounds.zip", "page": OC + "fleshy-fight-sounds", "title": "Fleshy Fight Sounds",
               "author": "will_leamon", "license": "OGA-BY 3.0"},
    "lrsf_fantasy": {"url": O + "Fantasy%20Sound%20Library.zip", "page": OC + "fantasy-sound-effects-library",
                     "title": "Fantasy Sound Effects Library", "author": "Little Robot Sound Factory (www.littlerobotsoundfactory.com)",
                     "license": "CC-BY 3.0"},
    "lrsf_horror": {"url": O + "Horror%20Sound%20Library.zip", "page": OC + "horror-sound-effects-library",
                    "title": "Horror Sound Effects Library", "author": "Little Robot Sound Factory (www.littlerobotsoundfactory.com)",
                    "license": "CC-BY 3.0"},
    "jc_fx": {"url": O + "fantasy_sfx_pack_vol_1.7z", "page": OC + "jc-sounds-fantasy-sfx-pack-vol-1",
              "title": "Fantasy SFX Pack Vol 1", "author": "JC Sounds", "license": "CC-BY 4.0"},
    "leohpaz_magic": {"url": O + "8_rpg_battle_magic_sfx_free_samples.zip", "page": OC + "8-magic-attacks",
                      "title": "8 Magic Attacks", "author": "leohpaz", "license": "CC-BY 4.0"},
    "leohpaz_heal": {"url": O + "8_rpg_heals_buffs_sfx_samples.zip", "page": OC + "8-heals-and-buffs-sfx",
                     "title": "8 Heals and Buffs SFX", "author": "leohpaz", "license": "CC-BY 4.0"},
    "smite": {"url": O + "Magic%20Smite.wav", "page": OC + "magic-smite", "title": "Magic Smite", "author": "spookymodem",
              "license": "CC-BY 3.0"},
    # Окружение
    "jc_nature": {"url": O + "nature_ambient_pack_vol_1_-_mp3.7z", "page": OC + "jc-sounds-nature-ambient-pack-vol-1",
                  "title": "Nature Ambient Pack Vol 1", "author": "JC Sounds", "license": "CC-BY 4.0"},
    "drips": {"url": O + "atmosbasement.mp3_.flac", "page": OC + "dripping-water-loop", "title": "Dripping water loop",
              "author": "qubodup", "license": "CC0"},
    "crowd": {"url": O + "crowd_shouting_0.ogg", "page": OC + "crowd-shoutingspeaking-ambience",
              "title": "Crowd Shouting/Speaking Ambience", "author": "StarNinjas", "license": "CC0"},
    "dungeon": {"url": O + "dungeon_ambient_1_0.ogg", "page": OC + "loopable-dungeon-ambience",
                "title": "Loopable Dungeon Ambience", "author": "JaggedStone", "license": "CC0"},
    "wind": {"url": O + "wind1.wav", "page": OC + "wind1", "title": "wind1", "author": "Luke.RUSTLTD", "license": "CC0"},
}

# --- Короткие звуки -------------------------------------------------------------------------------------
# id: [вариант, …]; вариант — (источник, файл в архиве[, параметры]). Параметры: seg — номер куска, если в
# файле несколько дублей подряд (режется по тишине), thresh — порог тишины в дБ от пика файла.
def kr(f): return ("k_rpg", "Audio/" + f)
def ki(f): return ("k_impact", "Audio/" + f)
def ku(f): return ("k_ui", "Audio/" + f)
def lf(f): return ("lrsf_fantasy", "Fantasy Sound Library/Wav/" + f)
def lh(f): return ("lrsf_horror", "Horror Sound Library/Wav/" + f)
def jc(f): return ("jc_fx", "Fantasy SFX Pack Vol 1/Single_Fantasy SFX Pack Vol 1_" + f)

UI_DB, HIT_DB, LOUD_DB, SOFT_DB = -6.0, -3.0, -1.0, -10.0
SFX = {
    # Интерфейс
    "ui_click": [ku("click1.ogg"), ku("click2.ogg")],
    "ui_hover": [ku("rollover1.ogg"), ku("rollover2.ogg")],
    "page_turn": [kr("bookFlip1.ogg"), kr("bookFlip2.ogg"), kr("bookFlip3.ogg")],
    "book": [kr("bookOpen.ogg")],
    "journal": [kr("bookPlace1.ogg"), kr("bookPlace2.ogg")],
    "save": [kr("bookClose.ogg")],
    "coin": [kr("handleCoins.ogg"), kr("handleCoins2.ogg")],
    "pickup": [kr("handleSmallLeather.ogg"), kr("handleSmallLeather2.ogg")],
    "cloth": [kr("cloth1.ogg"), kr("cloth2.ogg"), kr("cloth3.ogg")],
    # Оружие
    "swing": [("medieval2", "Dagger Swing.wav", {"seg": 0, "thresh": -25}), ("medieval2", "Dagger Swing.wav", {"seg": 2, "thresh": -25}),
              ("medieval2", "Axe Swing.wav", {"seg": 1, "thresh": -25}), ("medieval2", "Axe Swing.wav", {"seg": 3, "thresh": -25})],
    "miss": [("swishes", "swishes/swish-1.wav"), ("swishes", "swishes/swish-4.wav"), ("swishes", "swishes/swish-7.wav")],
    "throw": [("swishes", "swishes/swish-10.wav"), ("swishes", "swishes/swish-12.wav")],
    "whip": [("swishes", "swishes/swish-13.wav")],
    "hit_blade": [("fleshy", "sword-1a.wav"), ("fleshy", "sword-1b.wav"), lh("Stab_Knife_00.wav"), lh("Stab_Knife_01.wav")],
    "hit_blunt": [("fleshy", "hammer-1a.wav"), ("fleshy", "hammer-1b.wav"), ("fleshy", "punch_1a.wav")],
    "hit_claw": [("fleshy", "piercing-1a.wav"), ("fleshy", "piercing-1b.wav")],
    "hit_bone": [lh("Bonecrack_00.wav"), lh("Bonecrack_01.wav"), lh("Bonecrack_02.wav")],
    "bow_shot": [("medieval1", "English Longbow Shoot.wav", {"seg": 0}), ("medieval1", "Scythian Recurve Shoot.wav", {"seg": 0}),
                 jc("Bow_Arrow_Shoot_01.wav")],
    "crossbow_shot": [("medieval1", "Crossbow Shoot.wav", {"seg": 0}), ("medieval1", "Crossbow Shoot.wav", {"seg": 1})],
    "arrow_hit": [jc("Bow_Arrow_Hit_01.wav"), jc("Bow_Arrow_Hit_02.wav")],
    "body_fall": [ki("impactSoft_heavy_000.ogg"), ki("impactSoft_heavy_001.ogg"), ki("impactSoft_heavy_002.ogg")],
    "bones_collapse": [("bones", "0.ogg"), ("bones", "3.ogg"), ("bones", "6.ogg")],
    "undead_groan": [("zombies", "zombies/zombie-1.wav"), ("zombies", "zombies/zombie-5.wav"), ("zombies", "zombies/zombie-9.wav"),
                     ("zombies", "zombies/zombie-14.wav"), ("zombies", "zombies/zombie-20.wav")],
    "undead_death": [("voices", "Voice Effects Zombie-Skeleton-Monster Human Male/zombieDeath1.wav"),
                     ("voices", "Voice Effects Zombie-Skeleton-Monster Human Male/zombieDeath2.wav"),
                     ("voices", "Voice Effects Zombie-Skeleton-Monster Human Male/zombieDeath3.wav")],
    "shout": [("voices", "Voice Effects Zombie-Skeleton-Monster Human Male/humanYell1.wav"),
              ("voices", "Voice Effects Zombie-Skeleton-Monster Human Male/humanYell3.wav")],
    "dash": [lf("Footsteps/Footstep_Dirt_00.wav"), lf("Footsteps/Footstep_Dirt_03.wav")],
    "trap": [lf("Trap_00.wav"), lf("Trap_01.wav")],
    "spawn": [("horn", "")],
    "victory": [lf("Jingle_Win_00.wav")],
    "defeat": [lf("Jingle_Lose_00.wav")],
    # Магия
    "cast_holy": [("leohpaz_heal", "30_Revive_03.wav")],
    "hit_holy": [("smite", "")],
    "heal": [("leohpaz_heal", "02_Heal_02.wav"), ("cure", "Cure1.wav"), ("cure", "Cure3.wav")],
    "ward": [("leohpaz_heal", "17_Def_buff_01.wav"), jc("Magic Shield_Activation_01.wav")],
    "cast_fire": [jc("Fireball Launch_01.wav"), jc("Fireball Launch_02.wav")],
    "hit_fire": [jc("Fireball Impact_01.wav"), jc("Fireball Impact_02.wav")],
    "explosion": [("leohpaz_magic", "04_Fire_explosion_04_medium.wav")],
    "cast_arcane": [("leohpaz_magic", "45_Charge_05.wav")],
    "hit_arcane": [jc("Ice Shard  Projectile_Impact_01.wav"), jc("Ice Shard  Projectile_Impact_02.wav")],
    "thunder": [("leohpaz_magic", "18_Thunder_02.wav")],
    "goo": [("slime", "slime_01.ogg"), ("slime", "slime_05.ogg")],
    "thorns": [("leohpaz_magic", "30_Earth_02.wav")],
    "cast_dark": [("dark", "dark_magic/fout-01.flac"), ("dark", "dark_magic/fout-03.flac")],
    "hit_dark": [("leohpaz_magic", "46_Poison_01.wav"), ("leohpaz_heal", "21_Debuff_01.wav")],
    # Шаги на карте
    "step_grass": [ki("footstep_grass_000.ogg"), ki("footstep_grass_001.ogg"), ki("footstep_grass_002.ogg"),
                   ki("footstep_grass_003.ogg")],
    "step_mud": [lf("Footsteps/Footstep_Dirt_01.wav"), lf("Footsteps/Footstep_Dirt_02.wav"), lf("Footsteps/Footstep_Dirt_05.wav"),
                 lf("Footsteps/Footstep_Dirt_07.wav")],
    "step_stone": [ki("footstep_concrete_000.ogg"), ki("footstep_concrete_001.ogg"), ki("footstep_concrete_002.ogg")],
    # Сюжет: колокола свои (synth_bell), остальное из паков
    "handbell": [ki("impactBell_heavy_000.ogg"), ki("impactBell_heavy_002.ogg")],
}
# Пик по группам (дБ полной шкалы): интерфейс тише, удары громче.
PEAK = {"ui_click": UI_DB, "ui_hover": UI_DB, "page_turn": UI_DB, "book": UI_DB, "journal": UI_DB, "save": UI_DB,
        "coin": UI_DB, "pickup": UI_DB, "cloth": UI_DB, "dash": SOFT_DB, "step_grass": UI_DB, "step_mud": UI_DB,
        "step_stone": UI_DB, "spawn": -8.0, "explosion": LOUD_DB, "thunder": LOUD_DB, "victory": -4.0, "defeat": -4.0}
MAX_LEN = {"spawn": 4.0, "undead_groan": 2.5, "shout": 1.5, "cast_holy": 2.0, "heal": 2.0, "ward": 2.0, "thunder": 3.0,
           "explosion": 3.0, "cast_dark": 2.5, "hit_dark": 2.0, "thorns": 2.5}
BELLS = {
    # Колокол часовни: далёкий (сцена 1, за лесом) и близкий, частый набат (сцена 2).
    "bell_far": {"f0": 196.0, "strikes": [0.0], "dur": 7.0, "distance": 0.85},
    "bell_chapel": {"f0": 233.1, "strikes": [0.0, 0.55, 1.05, 1.7, 2.2], "dur": 6.5, "distance": 0.15},
}

# --- Шумы окружения (петли) --------------------------------------------------------------------------------
# id: слои [(источник, файл, громкость дБ, {low — срез верхов Гц, start, len})], len — длина петли.
JN = "Nature Ambient Pack Vol 1 - mp3/"
AMBIENT = {
    "rain": {"len": 60, "layers": [("jc_nature", JN + "Weather/AMB_Nature Pack Vol 1_Weather_Light Rain.mp3", 0, {"low": 6000}),
                                    ("drips", "", -6, {})]},
    "raid_night": {"len": 60, "layers": [("jc_nature", JN + "Fire & Elemental/AMB_Nature Pack Vol 1_ Fire & Elemental_Large Bonfire.mp3", 0, {}),
                                          ("crowd", "", -14, {"low": 1500}),
                                          ("jc_nature", JN + "Forest Enviroments/AMB_Nature Pack Vol 1_Forest Enviroments_Forest Night.mp3", -8, {})]},
    "ashes_wind": {"len": 60, "layers": [("wind", "", 0, {"low": 5000}),
                                          ("jc_nature", JN + "Fire & Elemental/AMB_Nature Pack Vol 1_ Fire & Elemental_Dying Embers.mp3", -8, {})]},
    "temple": {"len": 60, "layers": [("dungeon", "", 0, {})]},
    "stream": {"len": 60, "layers": [("jc_nature", JN + "Water Enviroments/AMB_Nature Pack Vol 1_Water Enviroments_Mountain Stream.mp3", 0, {}),
                                      ("jc_nature", JN + "Weather/AMB_Nature Pack Vol 1_Weather_Summer Evening.mp3", -10, {})]},
    "camp": {"len": 60, "layers": [("jc_nature", JN + "Fire & Elemental/AMB_Nature Pack Vol 1_ Fire & Elemental_Campfire Crackling.mp3", 0, {}),
                                    ("jc_nature", JN + "Forest Enviroments/AMB_Nature Pack Vol 1_Forest Enviroments_Forest Night.mp3", -8, {})]},
}
AMBIENT_LUFS = -26.0

# --- Музыка ----------------------------------------------------------------------------------------------
MUSIC_SOURCES = {
    "lament": {"url": O + "Lament_for_a_Warriors_Soul_REUPLOAD.mp3", "page": OC + "fantasy-lament-for-a-warriors-soul",
               "title": "Fantasy: Lament for a Warrior's Soul", "author": "RandomMind", "license": "CC0"},
    "fight": {"url": O + "zander_noriega-fight_them_until_we_cant.zip", "page": OC + "fight-them-until-we-cant",
              "title": "Fight Them Until We Can't", "author": "Zander Noriega", "license": "CC-BY 3.0"},
    "dark_descent": {"url": O + "Dark%20Descent_0.mp3", "page": OC + "dark-descent", "title": "Dark Descent",
                     "author": "Matthew Pablo (www.matthewpablo.com)", "license": "CC-BY 3.0"},
}
SOURCES.update(MUSIC_SOURCES)
MUSIC = {
    "home": ("lament", ""),
    "battle": ("fight", "Zander Noriega - Fight Them Until We Cant.mp3"),
    "dread": ("dark_descent", ""),
}
MUSIC_LUFS = -18.0


# --- Работа с файлами -------------------------------------------------------------------------------------

def fetch(src_id: str, cache: pathlib.Path) -> pathlib.Path:
    """Скачивает и распаковывает источник; возвращает папку (архив) или файл."""
    src = SOURCES[src_id]
    url = src["url"]
    name = urllib.request.unquote(url.rsplit("/", 1)[1])
    path = cache / src_id / name
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        print("  качаю", url, file=sys.stderr)
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=300) as r, open(path, "wb") as f:
            shutil.copyfileobj(r, f)
    if name.endswith((".zip", ".7z")):
        out = cache / src_id / "x"
        if not out.exists():
            if name.endswith(".zip"):
                zipfile.ZipFile(path).extractall(out)
            else:
                import py7zr
                py7zr.SevenZipFile(path).extractall(out)
        return out
    return path


def find(src_id: str, inner: str, cache: pathlib.Path) -> pathlib.Path:
    base = fetch(src_id, cache)
    if inner == "":
        return base
    hits = [p for p in base.rglob(pathlib.Path(inner).name) if str(p).endswith(inner) and "__MACOSX" not in str(p)]
    if not hits:
        raise FileNotFoundError(f"{src_id}: {inner}")
    return hits[0]


def load(path: pathlib.Path, channels: int) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", str(channels), "-ar", str(SR), "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, channels).copy()


def save_ogg(a: np.ndarray, path: pathlib.Path, quality: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    a = np.clip(a, -1.0, 1.0).astype(np.float32)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ac", str(a.shape[1]), "-ar", str(SR), "-i", "-",
                    "-c:a", "libvorbis", "-q:a", str(quality), str(path)], input=a.tobytes(), check=True)


def segments(a: np.ndarray, thresh_db=-40.0, gap=0.12, min_len=0.08) -> list:
    """Куски звука, разделённые тишиной (для файлов с несколькими дублями)."""
    env = np.abs(a).max(axis=1)
    win = int(SR * 0.01)
    env = np.convolve(env, np.ones(win) / win, mode="same")
    loud = env > (10 ** (thresh_db / 20)) * env.max()
    out, start, quiet = [], None, 0
    for i in range(0, len(loud), win):
        if loud[i]:
            if start is None:
                start = i
            quiet = 0
        elif start is not None:
            quiet += win
            if quiet > gap * SR:
                end = i - quiet + win
                if end - start > min_len * SR:
                    out.append((start, end))
                start, quiet = None, 0
    if start is not None:
        out.append((start, len(loud)))
    return out


def trim(a: np.ndarray, thresh_db=-50.0) -> np.ndarray:
    env = np.abs(a).max(axis=1)
    idx = np.where(env > (10 ** (thresh_db / 20)) * max(env.max(), 1e-9))[0]
    if len(idx) == 0:
        return a
    s = max(idx[0] - int(0.005 * SR), 0)
    e = min(idx[-1] + int(0.05 * SR), len(a))
    return a[s:e]


def fade(a: np.ndarray, fin=0.003, fout=0.03) -> np.ndarray:
    a = a.copy()
    n_in, n_out = min(int(fin * SR), len(a)), min(int(fout * SR), len(a))
    a[:n_in] *= np.linspace(0, 1, n_in)[:, None]
    a[len(a) - n_out:] *= np.linspace(1, 0, n_out)[:, None]
    return a


def peak(a: np.ndarray, db: float) -> np.ndarray:
    m = np.abs(a).max()
    return a * (10 ** (db / 20) / m) if m > 0 else a


def rms_db(a: np.ndarray) -> float:
    return 20 * np.log10(max(float(np.sqrt(np.mean(a ** 2))), 1e-9))


def lowpass(a: np.ndarray, hz: float) -> np.ndarray:
    spec = np.fft.rfft(a, axis=0)
    f = np.fft.rfftfreq(len(a), 1 / SR)
    spec *= (1 / np.sqrt(1 + (f / hz) ** 4))[:, None]
    return np.fft.irfft(spec, n=len(a), axis=0).astype(np.float32)


def loop(a: np.ndarray, length: float, xfade=3.0) -> np.ndarray:
    """Петля length секунд: конец плавно переходит в начало, шва не слышно."""
    n, x = int(length * SR), int(xfade * SR)
    while len(a) < n + x:
        a = np.concatenate([a, a[::-1]])  # короткий шум растягиваем отражением
    body, tail = a[:n].copy(), a[n:n + x]
    t = np.linspace(0, 1, x)[:, None]
    body[:x] = body[:x] * np.sqrt(t) + tail * np.sqrt(1 - t)
    return body


def lufs_like(a: np.ndarray, target: float) -> np.ndarray:
    """Громкость по RMS (приближение LUFS, для шумов и музыки достаточно)."""
    return a * 10 ** ((target - rms_db(a)) / 20)


def synth_bell(f0: float, strikes: list, dur: float, distance: float) -> np.ndarray:
    """Колокол из негармонических обертонов (hum, prime, tierce, quint, nominal…), затухание по частоте.
    distance 0–1: дальше — тише, глуше и с длинным отзвуком."""
    partials = [(0.5, 0.9, 4.5), (1.0, 1.0, 3.0), (1.19, 0.7, 2.2), (1.5, 0.45, 1.8), (2.0, 0.8, 1.5), (2.5, 0.3, 1.0),
                (2.67, 0.25, 0.9), (3.01, 0.2, 0.7), (4.16, 0.12, 0.5), (5.43, 0.08, 0.35)]
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    rng = np.random.default_rng(7)
    for s in strikes:
        idx = int(s * SR)
        tt = t[: n - idx]
        tone = np.zeros(len(tt))
        for ratio, amp, decay in partials:
            beat = 1 + 0.002 * rng.standard_normal()
            tone += amp * np.sin(2 * np.pi * f0 * ratio * beat * tt + rng.uniform(0, 6.28)) * np.exp(-tt / decay)
        clang = rng.standard_normal(len(tt)) * np.exp(-tt / 0.012) * 0.6  # удар языка
        out[idx:] += (tone + clang) * (0.85 + 0.3 * rng.random())
    a = out[:, None].astype(np.float32)
    a = lowpass(a, 6000 - 4500 * distance)
    # отзвук: несколько затухающих отражений
    rev = np.zeros_like(a)
    for k, d in enumerate([0.031, 0.047, 0.071, 0.113, 0.17, 0.25]):
        sh = int(d * SR * (1 + distance))
        rev[sh:] += a[:-sh] * (0.55 * (0.7 ** k)) * (0.5 + distance)
    a = a + rev
    a = np.repeat(a, 2, axis=1)
    return fade(peak(a, -3.0 - 8.0 * distance), 0.001, 0.5)


# --- Сборка -------------------------------------------------------------------------------------------------

def build_sfx(cache, used):
    for sid, variants in SFX.items():
        for old in (OUT / "sfx").glob(f"{sid}*.ogg"):
            if old.stem == sid or old.stem.rsplit("_", 1)[0] == sid and old.stem.rsplit("_", 1)[1].isdigit():
                old.unlink()
        many = len(variants) > 1
        for i, v in enumerate(variants, 1):
            src, inner = v[0], v[1]
            opt = v[2] if len(v) > 2 else {}
            a = load(find(src, inner, cache), 1)
            if "seg" in opt:
                segs = segments(a, opt.get("thresh", -40.0))
                s, e = segs[min(opt["seg"], len(segs) - 1)]
                a = a[max(s - int(0.02 * SR), 0):e + int(0.15 * SR)]
            a = trim(a)
            if sid in MAX_LEN and len(a) > MAX_LEN[sid] * SR:
                a = fade(a[: int(MAX_LEN[sid] * SR)], fout=0.25)
            a = fade(peak(a, PEAK.get(sid, HIT_DB)))
            name = f"{sid}_{i}" if many else sid
            save_ogg(a, OUT / "sfx" / f"{name}.ogg", 4)
            used.append({"file": f"sfx/{name}.ogg", "src": src, "inner": inner})
        print("sfx", sid, len(variants), file=sys.stderr)
    for sid, b in BELLS.items():
        save_ogg(synth_bell(**b), OUT / "sfx" / f"{sid}.ogg", 4)
        used.append({"file": f"sfx/{sid}.ogg", "src": "", "inner": ""})


def build_ambient(cache, used):
    for aid, spec in AMBIENT.items():
        mix = None
        for src, inner, gain, opt in spec["layers"]:
            a = load(find(src, inner, cache), 2)
            a = a[int(opt.get("start", 0) * SR):]
            if "low" in opt:
                a = lowpass(a, opt["low"])
            a = loop(a, spec["len"])
            a = lufs_like(a, AMBIENT_LUFS) * 10 ** (gain / 20)
            mix = a if mix is None else mix + a
            used.append({"file": f"ambient/{aid}.ogg", "src": src, "inner": inner})
        mix = lufs_like(mix, AMBIENT_LUFS)
        mix = np.tanh(mix / 0.5) * 0.5  # мягко срезать щелчки костра, а не приглушать весь шум
        save_ogg(mix, OUT / "ambient" / f"{aid}.ogg", 3)
        print("ambient", aid, file=sys.stderr)


def build_music(cache, used):
    for mid, (src, inner) in MUSIC.items():
        a = trim(load(find(src, inner, cache), 2), -60)
        a = lufs_like(a, MUSIC_LUFS)
        if np.abs(a).max() > 0.98:
            a = peak(a, -0.5)
        save_ogg(fade(a, 0.005, 0.05), OUT / "music" / f"{mid}.ogg", 5)
        used.append({"file": f"music/{mid}.ogg", "src": src, "inner": inner})
        print("music", mid, file=sys.stderr)


def write_licenses(used):
    """audio/sources.json — какой файл из чего собран (по нему пишется таблица лицензий)."""
    by_file = {}
    for u in used:
        by_file.setdefault(u["file"], [])
        if u["src"] and u["src"] not in by_file[u["file"]]:
            by_file[u["file"]].append(u["src"])
    data = {"sources": {k: SOURCES[k] for k in sorted({s for v in by_file.values() for s in v})}, "files": by_file}
    old = OUT / "sources.json"
    if old.exists():
        prev = json.loads(old.read_text())
        prev["files"].update(data["files"])
        prev["sources"].update(data["sources"])
        data = prev
    old.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n")
    write_tables(data)


LIC_MARK = "<!-- таблица ниже собирается tools/audio_build.py -->"
CREDITS_MARK = "<!-- звук: собирается tools/audio_build.py -->"
DATE = "2026-10-13"


def _src_cell(sid: str) -> str:
    s = SOURCES[sid]
    return f"[{s['title']}]({s['page']}), {s['author']}"


def write_tables(data):
    """Таблица файлов в audio/LICENSES.md и список авторов в CREDITS.md."""
    rows = []
    for f in sorted(data["files"]):
        srcs = data["files"][f]
        if not srcs:
            rows.append(f"| `{f}` | синтез в tools/audio_build.py (наш) | наш, без ограничений | — | {DATE} |")
            continue
        lic = ", ".join(sorted({SOURCES[x]["license"] for x in srcs}))
        rows.append(f"| `{f}` | {'; '.join(_src_cell(x) for x in srcs)} | {lic} | {', '.join(SOURCES[x]['page'] for x in srcs)} | {DATE} |")
    lic_path = OUT / "LICENSES.md"
    head = lic_path.read_text().split(LIC_MARK)[0].rstrip() + "\n\n" + LIC_MARK + "\n\n"
    table = "| Файл | Название и автор | Лицензия | Источник | Дата |\n|---|---|---|---|---|\n" + "\n".join(rows) + "\n"
    lic_path.write_text(head + table)
    by_page = {}  # один пак в двух архивах — одна строка
    for sid, src in data["sources"].items():
        by_page.setdefault(src["page"], (src, []))[1].append(sid)
    lines = ["| Что | Автор | Лицензия | Источник |", "|---|---|---|---|"]
    for page, (s, sids) in sorted(by_page.items(), key=lambda kv: (kv[1][0]["license"] == "CC0", kv[1][0]["author"].lower())):
        files = sorted({re.sub(r"(_\d+)?\.ogg$", "", f) for f, v in data["files"].items() if set(sids) & set(v)})
        lines.append(f"| {s['title']} ({', '.join('`' + x + '`' for x in files[:6])}{', …' if len(files) > 6 else ''}) "
                     f"| {s['author']} | {s['license']} | {page} |")
    lines.append("| Колокол часовни (`sfx/bell_far`, `sfx/bell_chapel`) | синтез, tools/audio_build.py | наш | — |")
    cr = GAME / "CREDITS.md"
    text = cr.read_text()
    head, _, rest = text.partition(CREDITS_MARK)
    tail = rest.split("\n## ", 1)
    after = ("\n## " + tail[1]) if len(tail) > 1 else ""
    cr.write_text(head + CREDITS_MARK + "\n\n" + "\n".join(lines) + "\n" + after)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default="/tmp/audio-cache")
    ap.add_argument("--only", choices=["sfx", "ambient", "music"])
    args = ap.parse_args()
    cache = pathlib.Path(args.cache)
    used = []
    if args.only in (None, "sfx"):
        build_sfx(cache, used)
    if args.only in (None, "ambient"):
        build_ambient(cache, used)
    if args.only in (None, "music"):
        build_music(cache, used)
    write_licenses(used)


if __name__ == "__main__":
    main()
