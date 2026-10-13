"""Перевод спрайтов и тайлов PixelLab в Resurrect 64 (как у якорей, art/anchors/README.md).

Один набор файлов (например, 8 направлений персонажа или все тайлы локации) переводится
одной таблицей: каждый цвет заменяется ближайшим цветом палитры в Lab (вес светлоты
L_WEIGHT; по желанию тени сначала растягиваются на тёмную часть палитры, STRETCH). Так один цвет во всех файлах набора
переходит в один и тот же цвет палитры. Полупрозрачность снимается (порог 50%).

    python3 art/tools/to_palette.py OUT_DIR file1.png file2.png ...
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from portrait import hexrgb, lab  # noqa: E402

PAL_FILE = Path(__file__).resolve().parents[1] / "palette" / "resurrect-64.hex"
L_WEIGHT = 0.5  # у якорей был 3; на героях 3 уводит синий в лиловый
STRETCH = False  # растяжка теней светлит контур; у якорей была включена


def palette() -> np.ndarray:
    return np.array([hexrgb("#" + h.lstrip("#")) for h in PAL_FILE.read_text().split()], dtype=np.float64)


def convert(files, out_dir=None, suffix=""):
    pal = palette()
    pal_lab = lab(pal)
    imgs = [np.array(Image.open(f).convert("RGBA")) for f in files]
    opaque = [im[..., 3] >= 128 for im in imgs]
    cols = np.unique(np.concatenate([im[m][:, :3] for im, m in zip(imgs, opaque)]), axis=0)
    cl = lab(cols.astype(np.float64))
    # растяжка теней: самый тёмный цвет набора → самый тёмный цвет палитры, светлые не трогаем
    lo, hi, plo = cl[:, 0].min(), cl[:, 0].max(), pal_lab[:, 0].min()
    if STRETCH and lo < plo and hi > plo:
        cl[:, 0] = plo + (cl[:, 0] - lo) * (hi - plo) / (hi - lo)
    d = L_WEIGHT * (cl[:, None, 0] - pal_lab[:, 0]) ** 2 + (cl[:, None, 1] - pal_lab[:, 1]) ** 2 + (cl[:, None, 2] - pal_lab[:, 2]) ** 2
    idx = d.argmin(1)
    table = {tuple(c): pal[i].astype(np.uint8) for c, i in zip(cols, idx)}
    outs = []
    for f, im, m in zip(files, imgs, opaque):
        res = np.zeros_like(im)
        ys, xs = np.nonzero(m)
        for y, x in zip(ys, xs):
            res[y, x, :3] = table[tuple(im[y, x, :3])]
            res[y, x, 3] = 255
        f = Path(f)
        out = (Path(out_dir) / f.name) if out_dir else f.with_name(f.stem + suffix + f.suffix)
        out.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(res).save(out)
        outs.append(out)
    return outs, len(cols), len(set(idx))


if __name__ == "__main__":
    outs, a, b = convert(sys.argv[2:], sys.argv[1])
    print(f"{len(outs)} файлов, цветов {a} → {b}")
