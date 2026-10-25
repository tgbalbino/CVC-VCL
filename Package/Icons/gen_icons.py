import sys, os
from PIL import Image, ImageDraw

OUT = sys.argv[1]
S = 16  # supersample
N = 24

INK = (52, 73, 107)
FIELD = (255, 255, 255)
BLUE = (31, 111, 235)
BLUE_D = (20, 80, 180)
GREEN = (39, 174, 96)
RED = (214, 69, 65)
ORANGE = (240, 150, 30)
GRAY = (200, 207, 218)
GRAY_D = (120, 132, 150)
SKIN = (96, 125, 160)


def new():
    im = Image.new('RGBA', (N * S, N * S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def r(d, box, fill=None, outline=None, w=1, rad=0):
    b = [v * S for v in box]
    if rad:
        d.rounded_rectangle(b, radius=rad * S, fill=fill, outline=outline, width=int(w * S))
    else:
        d.rectangle(b, fill=fill, outline=outline, width=int(w * S))


def line(d, pts, fill, w=1):
    d.line([(x * S, y * S) for x, y in pts], fill=fill, width=int(w * S), joint='curve')


def ell(d, box, fill=None, outline=None, w=1):
    d.ellipse([v * S for v in box], fill=fill, outline=outline, width=int(w * S))


def field(d, x0=1, y0=9, x1=23, y1=21, cursor=True, text=True):
    r(d, (x0, y0, x1, y1), fill=FIELD, outline=INK, w=1, rad=1.5)
    if cursor:
        line(d, [(x0 + 3.5, y0 + 3), (x0 + 3.5, y1 - 3)], INK, 1)
    if text:
        line(d, [(x0 + 6, y0 + 6), (x0 + 11, y0 + 6)], GRAY_D, 1)


def db_badge(d, ox=14, oy=1):
    # cylinder 9x9 at top-right
    x0, y0, x1, y1 = ox, oy, ox + 9, oy + 9
    r(d, (x0, y0 + 1.5, x1, y1 - 1.5), fill=BLUE)
    ell(d, (x0, y1 - 3.5, x1, y1), fill=BLUE_D)
    ell(d, (x0, y0, x1, y0 + 3.5), fill=(120, 175, 255), outline=BLUE_D, w=0.6)
    line(d, [(x0, y0 + 4.5), (x0 + 4.5, y0 + 6.2), (x1, y0 + 4.5)], (255, 255, 255), 0.5)


def arrow_btn(d, x0=16, y0=10, x1=22, y1=20):
    r(d, (x0, y0, x1, y1), fill=GRAY, outline=INK, w=1, rad=1)
    cx = (x0 + x1) / 2
    d.polygon([((cx - 2) * S, 13.8 * S), ((cx + 2) * S, 13.8 * S), (cx * S, 16.6 * S)], fill=INK)


def calendar(d, x0, y0, x1, y1, detail=True):
    r(d, (x0, y0, x1, y1), fill=FIELD, outline=INK, w=1, rad=1.2)
    r(d, (x0, y0, x1, y0 + (y1 - y0) * 0.32), fill=RED, outline=INK, w=1, rad=1.2)
    if detail:
        gx = x0 + 2
        gy = y0 + (y1 - y0) * 0.45
        step = (x1 - x0 - 3) / 3
        for i in range(3):
            for j in range(2):
                r(d, (gx + i * step, gy + j * 3, gx + i * step + 1.4, gy + j * 3 + 1.4), fill=GRAY_D)


def check(d, cx, cy, rad=5):
    ell(d, (cx - rad, cy - rad, cx + rad, cy + rad), fill=GREEN, outline=(20, 120, 60), w=0.6)
    line(d, [(cx - 2.6, cy), (cx - 0.7, cy + 2.2), (cx + 2.8, cy - 2.2)], (255, 255, 255), 1.4)


def magnifier(d, cx, cy):
    ell(d, (cx - 4, cy - 4, cx + 3, cy + 3), fill=(255, 245, 220), outline=ORANGE, w=1.4)
    line(d, [(cx + 2, cy + 2), (cx + 5.5, cy + 5.5)], ORANGE, 2)


def person(d, cx, cy, sc=1.0):
    ell(d, (cx - 2.2 * sc, cy - 4 * sc, cx + 2.2 * sc, cy + 0.4 * sc), fill=SKIN)
    d.pieslice([(cx - 4 * sc) * S, (cy + 0.8 * sc) * S, (cx + 4 * sc) * S, (cy + 8 * sc) * S],
               180, 360, fill=SKIN)


def to_bmp(im, path):
    rgba = im.convert('RGBa').resize((N, N), Image.LANCZOS).convert('RGBA')
    out = Image.new('RGB', (N, N), (255, 0, 255))
    px, op = rgba.load(), out.load()
    for y in range(N):
        for x in range(N):
            rr, g, b, a = px[x, y]
            if a >= 110:
                op[x, y] = (rr, g, b)
    # Delphi usa o pixel inferior esquerdo como cor transparente
    assert op[0, N - 1] == (255, 0, 255)
    out.save(path, 'BMP')
    return out


icons = {}


def icon(name):
    def deco(fn):
        icons[name] = fn
        return fn
    return deco


@icon('TCVCDBEDIT')
def _(d):
    field(d); db_badge(d)


@icon('TCVCDATEEDIT')
def _(d):
    field(d, x1=23); calendar(d, 13.5, 11, 21.5, 19.5, detail=True)
    line(d, [(4.5, 12), (4.5, 18)], INK, 1)


@icon('TCVCVALIDATEEDIT')
def _(d):
    field(d); check(d, 17.5, 5.5, 5.2)


@icon('TDBLOOKUPEDIT')
def _(d):
    field(d, x1=23); db_badge(d, ox=1, oy=1); magnifier(d, 17, 15)


@icon('TDBVALUECOMBOBOX')
def _(d):
    field(d, x1=16.5, cursor=False); arrow_btn(d, 16, 9, 23, 21)
    # corrige borda: botao encostado ao campo
    db_badge(d)


@icon('TCPFCNPJDBEDIT')
def _(d):
    r(d, (1, 7, 23, 21), fill=FIELD, outline=INK, w=1, rad=1.8)
    r(d, (1, 7, 23, 10), fill=BLUE, outline=INK, w=1, rad=1.8)
    person(d, 7.2, 14.8, 0.8)
    line(d, [(12.5, 13.5), (20.5, 13.5)], GRAY_D, 1)
    line(d, [(12.5, 16.5), (20.5, 16.5)], GRAY_D, 1)
    line(d, [(12.5, 19), (17.5, 19)], GRAY_D, 1)
    db_badge(d, ox=14, oy=0)


@icon('TCUSTOMBTN')
def _(d):
    r(d, (1.5, 5, 22.5, 19.5), fill=(70, 135, 235), outline=BLUE_D, w=1.2, rad=3)
    r(d, (3, 6.5, 21, 11), fill=(120, 170, 250), rad=2)
    line(d, [(6, 15), (18, 15)], (255, 255, 255), 1.4)


@icon('TDATEBOX')
def _(d):
    calendar(d, 2.5, 3, 21.5, 21.5, detail=False)
    gx, gy = 5.5, 11
    for i in range(4):
        for j in range(3):
            c = ORANGE if (i == 2 and j == 1) else GRAY_D
            r(d, (gx + i * 4, gy + j * 3.2, gx + i * 4 + 2, gy + j * 3.2 + 2), fill=c)


@icon('TDBPERSONCOMBOBOX')
def _(d):
    field(d, x1=16.5, cursor=False, text=False); arrow_btn(d, 16, 9, 23, 21)
    ell(d, (4, 11.2, 7.6, 14.8), fill=SKIN)
    d.pieslice([2.6 * S, 14.6 * S, 9 * S, 21.4 * S], 180, 360, fill=SKIN)
    line(d, [(10, 15), (14, 15)], GRAY_D, 1)
    db_badge(d)


os.makedirs(OUT, exist_ok=True)
sheet = Image.new('RGB', (len(icons) * 24 * 6 + 10, 24 * 6 + 10), (240, 240, 240))
for i, (name, fn) in enumerate(icons.items()):
    im, d = new()
    fn(d)
    bmp = to_bmp(im, os.path.join(OUT, name + '.bmp'))
    prev = Image.new('RGB', (N, N), (240, 240, 240))
    prev.paste(bmp, mask=bmp.convert('RGB').point(lambda v: 255).split()[0].point(lambda v: 255))
    # preview com transparencia aplicada
    pv = Image.new('RGB', (N, N), (240, 240, 240))
    s, p = bmp.load(), pv.load()
    for y in range(N):
        for x in range(N):
            if s[x, y] != (255, 0, 255):
                p[x, y] = s[x, y]
    sheet.paste(pv.resize((N * 6, N * 6), Image.NEAREST), (5 + i * N * 6, 5))
sheet.save(os.path.join(OUT, '_preview.png'))
print(sorted(icons))
