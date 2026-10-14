#!/usr/bin/env python3
"""Переносит готовую графику из art/ (её ведёт тред графики) в проект игры.

    python3 game/tools/import_art.py          # пересобрать то, что изменилось
    python3 game/tools/import_art.py --check  # код 1, если копия в game/art устарела

Что куда:
- портреты: art/portraits/<id>/{base_128,base_64,dark_*}.png → game/art/portraits/<id>/;
- персонажи на поле боя: кадры анимаций из art/prologue/characters и art/wave1/characters →
  лист game/art/units/<id>.png (строка на анимацию и направление: ЮВ, затем СВ) и описание в units.json;
  статичные (Олдрик, соседка, супруги, связанные) — game/art/units/static/<id>/<направление>.png;
- тайлы и объекты карт: art/prologue/tiles/<набор>/<имя>.png → game/art/tiles/<набор>/; объекты обрезаны
  по рисунку, в tiles.json их точка опоры; полы 64×64 копируются как есть;
- пол локаций: верхний ромб тайлов 64×32 → game/art/locations/tiles/<тип>.png (LocationArt);
- эффекты: art/prologue/fx/<id>/frames → полоса кадров game/art/fx/<id>.png и fx.json;
- иконки умений и состояний, интерфейс, фон меню: art/prologue/icons → game/art/icons, game/art/ui.

Первые варианты (<id>_v1) и исходники не копируются. После сборки нужен
`godot --headless --path game --import`, чтобы появились .import рядом с PNG.
"""
import io
import json
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
ART = REPO / "art"
OUT = REPO / "game" / "art"
PRO = ART / "prologue" / "characters"
W1 = ART / "wave1" / "characters"
DIRS = ("south-east", "north-east")

PORTRAIT_FILES = ("base_128.png", "base_64.png", "dark_1_dusk.png", "dark_2_gloom.png", "dark_3_abyss.png")

# Ноги персонажа во всех выгрузках PixelLab стоят на 23 px ниже центра холста (64, 80, 96, 112 и 128 px).
FOOT_BELOW_CENTER = 23
# Крупные персонажи на холсте 96×96 (страж шлюза главы 2, Торвин главы 3): ноги ниже центра на столько.
FOOT_BIG = {"sluice_guardian": 37, "torvin": 37}

# Анимация в игре → папка с кадрами относительно корня персонажа. "{d}" — направление.
_HERO = {a: f"composited/{a}/{{d}}" for a in ("idle", "walk", "hit", "down", "attack")}
_PIXELLAB = {
	"idle": "pixellab/Idle/animations/breathing_idle/{d}", "walk": "pixellab/Idle/animations/walking/{d}",
	"hit": "pixellab/Idle/animations/taking_a_punch/{d}", "down": "pixellab/Idle/animations/falling_backward/{d}",
}
_WAVE1 = {a: f"composited/{a}/{{d}}" for a in ("idle", "walk", "hit")}


def _w1(**extra: str) -> dict:
	out = dict(_WAVE1)
	for anim, folder in extra.items():
		out[anim] = f"composited/{folder}/{{d}}"
	return out


# id спрайта в игре → (папка персонажа, анимации). Герой — hero_<класс>_<f|m>, как у портретов;
# прихожане — вид врага raised (чётные — прихожанка).
UNITS = {
	"hero_fighter_m": (PRO / "hero_fighter_m", _HERO),
	"hero_fighter_f": (PRO / "hero_fighter_f", _HERO),
	"hero_rogue_m": (PRO / "hero_rogue_m", _HERO),
	"hero_rogue_f": (PRO / "hero_rogue_f", _HERO),
	"hero_cleric_m": (PRO / "hero_cleric_m", {**_HERO, "cast": "composited/cast/{d}"}),
	"hero_cleric_f": (PRO / "hero_cleric_f", {**_HERO, "cast": "composited/cast/{d}"}),
	"hero_wizard_f": (PRO / "hero_wizard_f", {**{a: _HERO[a] for a in ("idle", "walk", "hit", "down")},
		"cast": "composited/cast/{d}", "attack": "composited/thrust/{d}"}),
	"hero_wizard_m": (W1 / "hero_wizard_evoker", _w1(down="down", cast="cast")),
	"irena": (W1 / "irena", _w1(down="down", cast="cast_left", attack="slash")),
	"garret": (W1 / "garret", {a: f"unarmed/composited2/{a}/{{d}}" for a in ("idle", "walk", "hit", "down", "attack")}),
	"velior": (W1 / "velior", _w1(down="down", attack="stab", cast="throw")),
	"overseer": (W1 / "overseer", _w1(down="death", attack="slash")),
	"brandt": (W1 / "overseer_chief", _w1(down="death", attack="slash")),
	"zombie": (W1 / "zombie", _w1(down="death", attack="claw")),
	"skeleton": (W1 / "skeleton", _w1(down="death", attack="slash")),
	"skeleton_archer": (W1 / "skeleton_archer", _w1(down="death", attack="bow")),
	"crossbowman": (PRO / "crossbowman", {**_PIXELLAB, "attack": "anims/shoot/{d}"}),
	"raised": (PRO / "parishioner_m", {**_PIXELLAB, "attack": "anims/attack/{d}"}),
	"raised_f": (PRO / "parishioner_f", {**_PIXELLAB, "attack": "anims/attack/{d}"}),
	# Глава 1: бойцы шахты (art/tools/ch1_batch4.py); узники чередуются, как прихожане.
	"holt": (ART / "chapter1" / "characters" / "holt", {**_PIXELLAB, "attack": "anims/attack/{d}"}),
	"foreman_dead": (ART / "chapter1" / "characters" / "foreman_dead", {**_PIXELLAB, "attack": "anims/attack/{d}"}),
	"prisoner": (ART / "chapter1" / "characters" / "prisoner_m", {**_PIXELLAB, "attack": "anims/attack/{d}"}),
	"prisoner_f": (ART / "chapter1" / "characters" / "prisoner_f", {**_PIXELLAB, "attack": "anims/attack/{d}"}),
}
# Глава 2: бойцы затопленных выработок (art/tools/ch2_batch3.py); утопленники чередуются (drowned_f).
for _uid, _folder in {"drowned": "drowned_m", "drowned_f": "drowned_f", "smuggler": "smuggler", "renna": "renna",
		"shrine_priest": "shrine_priest", "sluice_guardian": "sluice_guardian"}.items():
	UNITS[_uid] = (ART / "chapter2" / "characters" / _folder, {**_PIXELLAB, "attack": "anims/attack/{d}"})
# Глава 3: бойцы дварфийских залов (art/tools/ch3_batch3.py); архивариус — мёртвый дварф.
for _uid, _folder in {"stone_guardian": "stone_guardian", "dwarf_archivist": "dwarf_dead", "torvin": "torvin"}.items():
	UNITS[_uid] = (ART / "chapter3" / "characters" / _folder, {**_PIXELLAB, "attack": "anims/attack/{d}"})
# Глава 4: бойцы кузниц плоти (art/tools/ch4_batch3.py).
CH4_UNITS = ("dead_soldier", "vat_overseer", "gessar", "stitched", "foundry_dead", "executioner")
for _uid in CH4_UNITS:
	UNITS[_uid] = (ART / "chapter4" / "characters" / _uid, {**_PIXELLAB, "attack": "anims/attack/{d}"})
# Глава 5: стража совета, Эдрик и тени Спящего (art/tools/ch5_batch3.py).
CH5_UNITS = ("council_guard", "edric", "sleeper_shade")
for _uid in CH5_UNITS:
	UNITS[_uid] = (ART / "chapter5" / "characters" / _uid, {**_PIXELLAB, "attack": "anims/attack/{d}"})
# Костяной лучник литейной — тот же скелет-лучник, только крепче.
UNITS["bone_archer"] = UNITS["skeleton_archer"]
# Статичные персонажи (только стойка, 8 направлений) и позы «связан» — по картинке на направление:
# game/art/units/static/<id>/<направление>.png, холст 64×64, ноги на 23 px ниже центра.
STATICS = {
	"oldrik": PRO / "oldrik/base/Idle/rotations", "neighbor_woman": PRO / "neighbor_woman/base/Idle/rotations",
	"spouse_f": PRO / "spouse_f/base/Idle/rotations", "spouse_m": PRO / "spouse_m/base/Idle/rotations",
	"brandt_tied": PRO / "brandt_tied", "garret_tied": PRO / "garret_tied",
}
# Глава 1: люди шахты на картах (art/chapter1/characters, без анимаций).
CH1 = ART / "chapter1" / "characters"
for _sid in ("holt", "mab", "boy", "prisoner_m", "prisoner_f", "white_woman", "sutler", "smith", "foreman_dead"):
	STATICS[_sid] = CH1 / _sid / "base" / "Idle" / "rotations"
# Глава 2: люди затопленных выработок на картах (art/chapter2/characters).
CH2 = ART / "chapter2" / "characters"
for _sid in sorted(p.name for p in CH2.iterdir() if (p / "base" / "Idle" / "rotations").is_dir()) if CH2.is_dir() else ():
	STATICS[_sid] = CH2 / _sid / "base" / "Idle" / "rotations"
# Глава 3: стражи, мёртвые дварфы и Торвин на картах (art/chapter3/characters).
CH3 = ART / "chapter3" / "characters"
for _sid in ("stone_guardian", "dwarf_dead", "torvin"):
	STATICS[_sid] = CH3 / _sid / "base" / "Idle" / "rotations"
# Глава 4: солдаты из чанов, надсмотрщики, Гессар и его «изделия» на картах (art/chapter4/characters).
CH4 = ART / "chapter4" / "characters"
for _sid in CH4_UNITS:
	STATICS[_sid] = CH4 / _sid / "base" / "Idle" / "rotations"
# Глава 5: стража совета на постах и Эдрик на картах дна (art/chapter5/characters).
CH5 = ART / "chapter5" / "characters"
for _sid in CH5_UNITS:
	STATICS[_sid] = CH5 / _sid / "base" / "Idle" / "rotations"
ANIM_ORDER = ("idle", "walk", "attack", "cast", "hit", "down")
FPS = {"idle": 5, "walk": 12, "attack": 12, "cast": 12, "hit": 12, "down": 12}

# Наборы тайлов, которые нужны боям и локациям пролога.
# Набор тайлов → папка в art/. Пролог — art/prologue/tiles/<набор>, глава 1 — шахты.
TILE_SETS = {ts: ART / "prologue" / "tiles" / ts for ts in ("village_night", "village_morning", "temple", "ford", "gate")}
TILE_SETS["mines"] = ART / "chapter1" / "tiles" / "mines"
TILE_SETS["flooded"] = ART / "chapter2" / "tiles" / "flooded"
TILE_SETS["dwarf"] = ART / "chapter3" / "tiles" / "dwarf"
TILE_SETS["forge"] = ART / "chapter4" / "tiles" / "forge"
TILE_SETS["deep"] = ART / "chapter5" / "tiles" / "deep"
FLOOR_PREFIXES = ("floor_", "water_", "bank_", "edge")
# Верх ромба у пола 64×64: ромб 64×32 начинается с 22-й строки.
FLOOR_TOP = 22
# Пол локаций (LocationArt.GROUND) → тайл. Локации пролога — двор Эшмура ночью и пепелище утром,
# у них общие типы пола, поэтому берутся утренние тайлы (ночь затемняет освещение сцены).
LOCATION_FLOORS = {
	"grass": "village_morning/floor_grass", "grass_scorch": "village_morning/floor_ash",
	"mud": "village_morning/floor_ruts", "road": "village_morning/floor_path",
	"yard": "village_morning/floor_garden", "ash": "village_morning/floor_ash",
	# Шахты главы 1.
	"mine_stone": "mines/floor_stone", "mine_gravel": "mines/floor_gravel", "mine_ore": "mines/floor_ore",
	"mine_planks": "mines/floor_planks", "mine_rails": "mines/floor_rails", "mine_rails_b": "mines/floor_rails_b",
	# Затопленные выработки главы 2.
	"flood_wade": "flooded/floor_wade", "flood_deep": "flooded/floor_deep", "flood_wet": "flooded/floor_wet",
	# Дварфийские залы главы 3.
	"dwarf_hall": "dwarf/floor_hall", "dwarf_rune": "dwarf/floor_rune", "dwarf_chasm": "dwarf/floor_chasm",
	# Кузницы плоти главы 4.
	"forge_works": "forge/floor_works", "forge_grate": "forge/floor_grate", "forge_molten": "forge/floor_molten",
	# Дно главы 5: спуск и зал печати.
	"deep_descent": "deep/floor_descent", "deep_rock": "deep/floor_rock", "deep_seal": "deep/floor_seal",
	"deep_groove": "deep/floor_groove", "deep_core": "deep/floor_core",
}

ABILITY_ICONS = ("disengage", "dodge", "end_turn", "fire_bolt", "hallowed_ground", "healing_word", "magic_missile",
	"move_attack", "sacred_flame", "second_wind", "shield_of_faith", "shove", "taunt", "thunderwave", "trip")
# Значок → состояние в statuses.json.
STATUS_ICONS = {"st_ac_bonus": "shielded", "st_dodging": "dodging", "st_hidden": "hidden", "st_prone": "prone",
	"st_taunted": "taunted"}
UI_FILES = ("ui_button_disabled", "ui_button_hover", "ui_button_normal", "ui_button_pressed", "ui_dialog", "ui_hpbar",
	"ui_nameplate", "ui_panel", "ui_portrait_frame", "ui_portrait_frame_active", "ui_portrait_frame_ornate", "ui_slot",
	"menu_bg", "cursor_attack", "cursor_pointer", "cursor_spell")


class Writer:
	"""Пишет файл, только если содержимое изменилось; в режиме --check только запоминает устаревшее."""

	def __init__(self, check: bool) -> None:
		self.check = check
		self.stale: list[str] = []

	def put(self, dst: Path, data: bytes) -> None:
		if dst.exists() and dst.read_bytes() == data:
			return
		self.stale.append(str(dst.relative_to(OUT)))
		if not self.check:
			dst.parent.mkdir(parents=True, exist_ok=True)
			dst.write_bytes(data)

	def image(self, dst: Path, im: Image.Image) -> None:
		buf = io.BytesIO()
		im.save(buf, "PNG", optimize=True)
		self.put(dst, buf.getvalue())

	def json(self, dst: Path, obj: dict) -> None:
		self.put(dst, (json.dumps(obj, ensure_ascii=False, indent="\t", sort_keys=True) + "\n").encode())

	def copy(self, src: Path, dst: Path) -> None:
		self.put(dst, src.read_bytes())


def portraits(w: Writer) -> None:
	src_root = ART / "portraits"
	for d in sorted(p for p in src_root.iterdir() if p.is_dir()):
		if d.name == "source" or d.name.endswith("_v1"):
			continue
		for name in PORTRAIT_FILES:
			if (d / name).exists():
				w.copy(d / name, OUT / "portraits" / d.name / name)


def _frames(folder: Path) -> list[Image.Image]:
	files = sorted(f for f in folder.glob("*.png"))
	return [Image.open(f).convert("RGBA") for f in files]


def units(w: Writer) -> None:
	"""Лист кадров на персонажа. Кадры совмещены по центру холста (у PixelLab ноги всегда на одном месте
	относительно центра), обрезаны общей рамкой; foot — точка между ног в листе."""
	manifest = {}
	for uid, (root, anims) in UNITS.items():
		rows = []  # (anim, dir, frames)
		for anim in ANIM_ORDER:
			if anim not in anims:
				continue
			for d in DIRS:
				frames = _frames(root / anims[anim].format(d=d))
				if not frames:
					raise SystemExit(f"{uid}: нет кадров {anim} {d} в {root / anims[anim].format(d=d)}")
				rows.append((anim, d, frames))
		# Общая рамка в координатах «от центра холста».
		left = top = 10 ** 6
		right = bottom = -10 ** 6
		for _, _, frames in rows:
			for f in frames:
				bb = f.getchannel("A").getbbox()
				if bb is None:
					continue
				cx, cy = f.width // 2, f.height // 2
				left, top = min(left, bb[0] - cx), min(top, bb[1] - cy)
				right, bottom = max(right, bb[2] - cx), max(bottom, bb[3] - cy)
		cw, ch = right - left, bottom - top
		count = max(len(fr) for _, _, fr in rows)
		sheet = Image.new("RGBA", (cw * count, ch * len(rows)), (0, 0, 0, 0))
		info = {}
		for r, (anim, d, frames) in enumerate(rows):
			for i, f in enumerate(frames):
				cx, cy = f.width // 2, f.height // 2
				sheet.alpha_composite(f, (i * cw + (-cx - left), r * ch + (-cy - top)))
			if d == DIRS[0]:
				info[anim] = {"row": r, "frames": len(frames), "fps": FPS[anim]}
		manifest[uid] = {"size": [cw, ch], "foot": [-left, FOOT_BIG.get(uid, FOOT_BELOW_CENTER) - top], "anims": info}
		w.image(OUT / "units" / f"{uid}.png", sheet)
	w.json(OUT / "units" / "units.json", manifest)
	for sid, folder in STATICS.items():
		for f in sorted(folder.glob("*.png")):
			w.copy(f, OUT / "units" / "static" / sid / f.name)


def tiles(w: Writer) -> None:
	"""Полы — как есть (64×64, верх ромба с FLOOR_TOP); объекты обрезаны по рисунку, в tiles.json —
	[ox, h]: где центр клетки по x от левого края и высота до нижней точки рисунка."""
	manifest = {}
	for ts, folder in TILE_SETS.items():
		for f in sorted(folder.glob("*.png")):
			name = f.stem
			im = Image.open(f).convert("RGBA")
			if name.startswith(FLOOR_PREFIXES):
				w.image(OUT / "tiles" / ts / f.name, im)
				continue
			bb = im.getchannel("A").getbbox()
			crop = im.crop(bb)
			manifest[f"{ts}/{name}"] = [im.width // 2 - bb[0], crop.height]
			w.image(OUT / "tiles" / ts / f.name, crop)
	w.json(OUT / "tiles" / "tiles.json", manifest)
	for kind, src in LOCATION_FLOORS.items():
		ts, name = src.split("/")
		im = Image.open(TILE_SETS[ts] / f"{name}.png").convert("RGBA")
		# Верх ромба — по рисунку: у полов шахт он на строку-две ниже FLOOR_TOP.
		y0 = max(FLOOR_TOP, im.getchannel("A").getbbox()[1]) if ts in ("mines", "flooded", "deep") else FLOOR_TOP
		top = im.crop((0, y0, 64, y0 + 32))
		# Только ромб: всё, что вне него, прозрачно, чтобы соседние клетки не перекрывались.
		out = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
		for y in range(32):
			for x in range(64):
				if abs(x - 31.5) / 32.0 + abs(y - 15.5) / 16.0 <= 1.0:
					out.putpixel((x, y), top.getpixel((x, y))[:3] + (255,))
		w.image(OUT / "locations" / "tiles" / f"{kind}.png", out)


def fx(w: Writer) -> None:
	manifest = {}
	for d in sorted((ART / "prologue" / "fx").iterdir()):
		frames = _frames(d / "frames")
		if not frames:
			continue
		fw, fh = frames[0].size
		strip = Image.new("RGBA", (fw * len(frames), fh), (0, 0, 0, 0))
		for i, f in enumerate(frames):
			strip.alpha_composite(f, (i * fw, 0))
		manifest[d.name] = {"size": [fw, fh], "frames": len(frames)}
		w.image(OUT / "fx" / f"{d.name}.png", strip)
	w.json(OUT / "fx" / "fx.json", manifest)


def icons(w: Writer) -> None:
	src = ART / "prologue" / "icons"
	for aid in ABILITY_ICONS:
		w.copy(src / f"{aid}.png", OUT / "icons" / "abilities" / f"{aid}.png")
	for icon, sid in STATUS_ICONS.items():
		w.copy(src / f"{icon}.png", OUT / "icons" / "status" / f"{sid}.png")
	for name in UI_FILES:
		w.copy(src / f"{name}.png", OUT / "ui" / f"{name}.png")


def main() -> int:
	w = Writer("--check" in sys.argv)
	for step in (portraits, units, tiles, fx, icons):
		step(w)
	if w.stale:
		print(("Устарело: " if w.check else "Обновлено: ") + ", ".join(w.stale))
	else:
		print("Графика в game/art совпадает с art/")
	return 1 if w.check and w.stale else 0


if __name__ == "__main__":
	sys.exit(main())
