#!/usr/bin/env python3
"""Портреты 128×128 и 64×64 из генераций универсальной модели, слои Тьмы к портретам героя.

Развитие prototypes/stack-slice/tools/make_portrait.py: те же шаги (PROMPTS.md, раздел 8), но
настройки каждого портрета лежат в art/portraits/portraits.json, и добавлена черновая чистка:
  кадр → уменьшение → подъём тёмных тонов → Resurrect 64 (ближайший цвет в Lab)
  → редкие цвета сливаются с ближайшими частыми → одиночные пиксели заменяются соседями
  → ровный фон генерации (STYLE_PORTRAIT) заменяется самым тёмным цветом палитры.
Кожа раскладывается на рампу из четырёх цветов палитры (ключи шейдера skin_swap.gdshader).
Слои Сумрак/Мрак/Бездна рисуются по координатам глаз, виска, скулы и шеи из настроек.

    python3 art/tools/portrait.py                 все портреты из portraits.json
    python3 art/tools/portrait.py hero_wizard_m   один портрет

Результат: art/portraits/<id>/ — base_128.png, base_64.png, слои dark_*.png (только у героя),
preview.png (увеличенный лист для просмотра). Нужны Pillow и numpy.
Это черновик под Aseprite: глаза, губы, контур и мелкие детали дочищаются руками.
"""
import colorsys
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance

ART = Path(__file__).resolve().parent.parent
PALETTE = ART / "palette" / "resurrect-64.png"
CONFIG = ART / "portraits" / "portraits.json"

# Общие настройки; любую можно переопределить в portraits.json для отдельного портрета.
DEFAULTS = {
    "gamma": 0.75,         # подъём тёмных тонов: генерация темнее, чем читается в 128 px
    "saturation": 1.25,
    "chroma": 1.3,         # вес цветности при выборе ближайшего цвета палитры (Lab)
    "max_colors": 28,      # сколько цветов палитры остаётся в портрете после слияния редких
    "background": "#2e222f",  # самый тёмный цвет палитры: им заменяется фон генерации
    "bg_tolerance": 14,    # насколько цвет может отличаться от фона в углах (Lab); 0 — фон не трогать
    "skin_ramp": ["#fca790", "#e6904e", "#cd683d", "#9e4539"],  # Тень; совпадает с SKIN[0] в dark_portrait.gd
    "skin_splits": [0.85, 0.55, 0.2],
}

DUSK, GLOOM, VEIN, ABYSS_IRIS, ABYSS_GLINT, ABYSS_HOT = "#7a3045", "#6b3e75", "#45293f", "#165a4c", "#91db69", "#cddf6c"


def hexrgb(h: str) -> tuple[int, int, int]:
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def lab(rgb: np.ndarray) -> np.ndarray:
    c = rgb / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def nearest(colors_lab: np.ndarray, pal_lab: np.ndarray, chroma: float) -> np.ndarray:
    d = (colors_lab[..., None, 0] - pal_lab[:, 0]) ** 2 + chroma * (
        (colors_lab[..., None, 1] - pal_lab[:, 1]) ** 2 + (colors_lab[..., None, 2] - pal_lab[:, 2]) ** 2)
    return d.argmin(-1)


def prepare(src: Path, crop: list[int], size: int, cfg: dict) -> np.ndarray:
    small = Image.open(src).convert("RGB").crop(tuple(crop)).resize((size, size), Image.LANCZOS)
    a = np.asarray(small).astype(float) / 255
    small = ImageEnhance.Color(Image.fromarray((255 * a ** cfg["gamma"]).astype(np.uint8))).enhance(cfg["saturation"])
    return np.asarray(small).astype(float)


def quantize(rgb: np.ndarray, pal: np.ndarray, cfg: dict) -> np.ndarray:
    """Индексы палитры; редкие цвета сливаются с ближайшими из max_colors самых частых."""
    pal_lab = lab(pal)
    idx = nearest(lab(rgb), pal_lab, cfg["chroma"])
    used, counts = np.unique(idx, return_counts=True)
    if len(used) > cfg["max_colors"]:
        keep = used[np.argsort(-counts)[:cfg["max_colors"]]]
        remap = {u: (u if u in keep else keep[nearest(pal_lab[u][None], pal_lab[keep], cfg["chroma"])[0]]) for u in used}
        idx = np.vectorize(remap.get)(idx)
    return idx


def despeckle(idx: np.ndarray, passes: int = 2) -> np.ndarray:
    """Пиксель, не похожий ни на одного из 8 соседей, получает самый частый цвет соседей."""
    h, w = idx.shape
    for _ in range(passes):
        p = np.pad(idx, 1, mode="edge")
        out = idx.copy()
        for y in range(h):
            for x in range(w):
                nb = np.delete(p[y:y + 3, x:x + 3].ravel(), 4)
                if not (nb == idx[y, x]).any():
                    vals, cnt = np.unique(nb, return_counts=True)
                    if cnt.max() >= 3:
                        out[y, x] = vals[cnt.argmax()]
        idx = out
    return idx


def background_mask(rgb: np.ndarray, tol: float) -> np.ndarray:
    """Фон: пиксели, близкие по цвету (Lab) к верхним углам кадра и связанные с краем (кроме
    нижнего: там плечи). Надёжно работает на ровном цветном фоне (STYLE_PORTRAIT); на тёмном
    фоне волосы и плащ сливаются с ним, тогда bg_tolerance = 0 и фон чистится в Aseprite."""
    h, w = rgb.shape[:2]
    if tol <= 0:
        return np.zeros((h, w), bool)
    k = max(4, h // 16)
    L = lab(rgb)
    ref = np.concatenate([L[:k, :k].reshape(-1, 3), L[:k, -k:].reshape(-1, 3)]).mean(0)
    candidate = np.sqrt(((L - ref) ** 2).sum(-1)) < tol
    seen = np.zeros_like(candidate)
    stack = [(0, x) for x in range(w)] + [(y, 0) for y in range(h)] + [(y, w - 1) for y in range(h)]
    while stack:
        y, x = stack.pop()
        if 0 <= y < h and 0 <= x < w and candidate[y, x] and not seen[y, x]:
            seen[y, x] = True
            stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    return seen


def apply_skin(img: np.ndarray, rgb: np.ndarray, box: list[int], cfg: dict) -> None:
    """Кожа — тёплый тон достаточной яркости внутри рамки лица — на рампу из четырёх цветов."""
    a = rgb / 255
    s = a.shape[0]
    hsv = np.array([[colorsys.rgb_to_hsv(*a[y, x]) for x in range(s)] for y in range(s)])
    inside = np.zeros((s, s), bool)
    x0, y0, x1, y1 = box
    inside[y0:y1, x0:x1] = True
    skin = inside & ((hsv[..., 0] < 0.12) | (hsv[..., 0] > 0.95)) & (hsv[..., 1] > 0.18) & (hsv[..., 2] > 0.42)
    if not skin.any():
        return
    light = a.mean(-1)
    th = np.quantile(light[skin], cfg["skin_splits"])
    tone = np.select([light >= th[0], light >= th[1], light >= th[2]], [0, 1, 2], 3)
    for k, h in enumerate(cfg["skin_ramp"]):
        img[skin & (tone == k)] = hexrgb(h)


def render(src: Path, crop: list[int], size: int, face_box: list[int] | None, pal: np.ndarray, cfg: dict) -> Image.Image:
    rgb = prepare(src, crop, size, cfg)
    idx = despeckle(quantize(rgb, pal, cfg))
    img = pal[idx].astype(np.uint8)
    img[background_mask(rgb, cfg["bg_tolerance"])] = hexrgb(cfg["background"])
    if face_box:
        apply_skin(img, rgb, face_box, cfg)
    return Image.fromarray(img).convert("RGBA")


def layers(f: dict, s: int) -> list[Image.Image]:
    """Сумрак, Мрак, Бездна — накопительные слои поверх базового портрета 128."""
    out = []
    for _ in range(3):
        out.append(Image.new("RGBA", (s, s), (0, 0, 0, 0)))
    dusk, gloom, abyss = (ImageDraw.Draw(im) for im in out)
    for key in ("eye_near", "eye_far"):
        x0, x1, y = f[key]
        dusk.line([x0, y + 2, x1, y + 2], fill=DUSK)
    x0, x1, y = f["eye_near"]
    dusk.line([x0 + 1, y + 3, x1 - 1, y + 3], fill="#694f62")
    x, y = f["temple"]
    gloom.line([x, y, x + 1, y + 3, x, y + 6, x + 2, y + 8], fill=GLOOM)
    gloom.point([x + 2, y + 3], fill=GLOOM)
    for x, y in (f["iris_near"], f["iris_far"]):
        gloom.rectangle([x - 1, y, x, y], fill="#323353")
    x, y = f["temple"]
    abyss.line([x - 1, y - 4, x + 1, y, x, y + 4], fill=VEIN)
    x, y = f["cheek"]
    abyss.line([x, y, x + 2, y + 3, x + 1, y + 6], fill=VEIN)
    abyss.point([x + 3, y + 3], fill=GLOOM)
    x, y = f["neck"]
    abyss.line([x, y, x + 1, y + 4, x - 1, y + 8], fill=VEIN)
    for x, y in (f["iris_near"], f["iris_far"]):
        abyss.rectangle([x - 1, y, x, y], fill=ABYSS_IRIS)
        abyss.point([x, y], fill=ABYSS_GLINT)
    abyss.point([f["iris_near"][0] - 1, f["iris_near"][1]], fill=ABYSS_HOT)
    return out


def build(pid: str, entry: dict, pal: np.ndarray) -> None:
    cfg = {**DEFAULTS, **entry.get("settings", {})}
    src = ART / "portraits" / entry["source"]
    out = ART / "portraits" / pid
    out.mkdir(parents=True, exist_ok=True)
    base = render(src, entry["crop"], 128, entry.get("face_box"), pal, cfg)
    base.save(out / "base_128.png")
    face64 = [v // 2 for v in entry["face_box"]] if entry.get("face_box") and "crop_64" not in entry else entry.get("face_box_64")
    small = render(src, entry.get("crop_64", entry["crop"]), 64, face64, pal, cfg)
    small.save(out / "base_64.png")

    frames = [base]
    if entry.get("features"):
        dark = layers(entry["features"], 128)
        for name, im in zip(("dark_1_dusk", "dark_2_gloom", "dark_3_abyss"), dark):
            im.save(out / f"{name}.png")
        acc = base.copy()
        for im in dark:
            acc = Image.alpha_composite(acc, im)
            frames.append(acc.copy())
    sheet = Image.new("RGBA", (128 * 3 * len(frames) + 64 * 3, 128 * 3), hexrgb(cfg["background"]) + (255,))
    for i, fr in enumerate(frames):
        sheet.paste(fr.resize((384, 384), Image.NEAREST), (i * 384, 0))
    sheet.paste(small.resize((192, 192), Image.NEAREST), (len(frames) * 384, 0))
    sheet.save(out / "preview.png")
    colors = len(np.unique(np.asarray(base)[..., :3].reshape(-1, 3), axis=0))
    print(f"{pid}: {colors} цветов, файлы в {out.relative_to(ART.parent)}")


def main() -> None:
    pal = np.asarray(Image.open(PALETTE).convert("RGB")).reshape(-1, 3).astype(float)
    entries = {k: v for k, v in json.loads(CONFIG.read_text()).items() if not k.startswith("_")}
    wanted = sys.argv[1:] or [k for k, v in entries.items() if (ART / "portraits" / v["source"]).exists()]
    for pid in wanted:
        build(pid, entries[pid], pal)


if __name__ == "__main__":
    main()
