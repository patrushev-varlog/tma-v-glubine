"""Стирает тень-подставку под ногами персонажа (серый эллипс, который PixelLab иногда рисует).

Тень — связная область цвета, близкого к SHADOW, которая касается нижнего края фигуры; её контур
(тёмные пиксели, граничащие только с тенью и пустотой) стирается вместе с ней.

    python3 art/tools/drop_shadow.py --check out.png кадры...   # показать маску красным
    python3 art/tools/drop_shadow.py кадры...                   # стереть на месте
"""
import sys
import numpy as np
from PIL import Image

SHADOW = np.array([120, 119, 115])
TOL = 22


def dilate(m):
    d = m.copy()
    d[1:] |= m[:-1]; d[:-1] |= m[1:]; d[:, 1:] |= m[:, :-1]; d[:, :-1] |= m[:, 1:]
    return d


def components(m):
    """Связные области маски (4-связность)."""
    seen = np.zeros_like(m)
    for y, x in zip(*np.nonzero(m)):
        if seen[y, x]:
            continue
        comp, stack = [], [(y, x)]
        seen[y, x] = True
        while stack:
            cy, cx = stack.pop()
            comp.append((cy, cx))
            for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                if 0 <= ny < m.shape[0] and 0 <= nx < m.shape[1] and m[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        yield comp


def mask(a):
    op = a[..., 3] > 0
    rgb = a[..., :3].astype(int)
    grey = op & (np.abs(rgb - SHADOW).max(-1) <= TOL) & (np.ptp(rgb, -1) <= 12)
    ys = np.nonzero(op.any(1))[0]
    if not len(ys):
        return grey & False
    bottom = ys.max()
    keep = np.zeros_like(grey)
    for comp in components(grey):  # только области у нижнего края фигуры
        if max(y for y, _ in comp) >= bottom - 2:
            for y, x in comp:
                keep[y, x] = True
    # контур тени: тёмные пиксели рядом с тенью, не граничащие с другими цветами фигуры
    dark = op & (rgb.sum(-1) < 90)
    body = op & ~keep & ~dark
    near_shadow = dilate(keep)
    near_body = dilate(body)
    return keep | (dark & near_shadow & ~near_body)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[0] == "--check":
        out, files = args[1], args[2:]
        S = 5
        ims = []
        for f in files:
            a = np.array(Image.open(f).convert("RGBA"))
            m = mask(a)
            b = a.copy(); b[m] = [255, 0, 0, 255]
            ims.append(Image.fromarray(b))
        W = max(i.width for i in ims) * S; H = max(i.height for i in ims) * S
        sheet = Image.new("RGBA", (W * len(ims), H), (60, 90, 60, 255))
        for k, i in enumerate(ims):
            sheet.alpha_composite(i.resize((i.width * S, i.height * S), Image.NEAREST), (k * W, 0))
        sheet.save(out)
    else:
        n = 0
        for f in args:
            a = np.array(Image.open(f).convert("RGBA"))
            m = mask(a)
            if m.any():
                a[m] = 0
                Image.fromarray(a).save(f)
                n += 1
        print("исправлено кадров:", n, "из", len(args))
