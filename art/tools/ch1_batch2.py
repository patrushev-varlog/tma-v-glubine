"""Глава 1, партия 2: персонажи — основы в стиле Гаррета, 8 направлений, стойка (по 10 генераций).

Анимации (стойка, ходьба, удар, урон, гибель) — следующей партией, после того как основы приняты.
Узники и Хольт дерутся (бои 1–3), штейгер — страж охоты; Лиара, Мэб, маркитант, кузнец и мальчик
Олдрика стоят на картах и в лагере.

    python3 art/tools/ch1_batch2.py [имя ...]
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p

OUT = p.ROOT / "art" / "chapter1" / "characters"
EMPTY = "both hands empty, no weapon in hands, "
NO_SHADOW = "no ground shadow, no base under the feet, "

CHARS = {
 "prisoner_m": "an emaciated male mine prisoner, ragged grey sackcloth tunic, bare feet, iron shackle on one ankle with a broken chain, shaved head, gaunt hollow face, rock dust on skin, holding a broken pickaxe handle as a club, ",
 "prisoner_f": "an emaciated female mine prisoner, ragged grey sackcloth dress, bare feet, iron shackle on one ankle, cropped hair under a dirty kerchief, gaunt face, rock dust on skin, holding a short iron bar as a club, ",
 "holt": "a veteran human mine sergeant in his fifties, black padded jacket with a dull-red iron crown-in-circle badge, steel half-helmet, grey moustache, heavy build, longsword held low in the right hand, ",
 "foreman_dead": "an undead mine foreman skeleton in a rotten leather miner's jacket and a dented copper helmet, empty dark eye sockets with two small yellow glints, a brass lantern glowing warm yellow hanging on his belt, holding a pickaxe in both hands, ",
 "white_woman": "a pale ghostly young woman in a long plain white dress, long dark hair loose, barefoot, standing still with arms at her sides, faint cold glow, sad calm face, " + EMPTY,
 "mab": "an old gaunt female mine prisoner, barrack elder, ragged grey sackcloth, cropped grey hair, missing teeth, hard defiant face, arms crossed, " + EMPTY,
 "sutler": "a thin shifty camp sutler, patched long coat with many pockets, a pack of goods on his back, narrow face, darting eyes, stubble, " + EMPTY,
 "smith": "a broad village blacksmith in his forties, leather apron over a linen shirt, rolled sleeves, short dark beard, soot on the face, " + EMPTY,
 "boy": "a thin village boy of about twelve, ragged linen shirt and trousers, bare feet, rock dust on skin, tousled hair, serious face, " + EMPTY,
}


def char(name, desc):
    cid, j = p.create_character(name, desc + NO_SHADOW + p.STYLE_CHAR)
    p.character_zip(cid, OUT / name / "base")
    (OUT / name / "id.txt").write_text(cid + "\n")
    return name, cid, (j.get("usage") or {}).get("generations")


if __name__ == "__main__":
    names = sys.argv[1:] or list(CHARS)
    with cf.ThreadPoolExecutor(4) as ex:
        for f in cf.as_completed([ex.submit(char, n, CHARS[n]) for n in names]):
            try:
                print("ok", f.result(), flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
