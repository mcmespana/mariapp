#!/usr/bin/env python3
"""Dibuixa la icona de Mariapp (1024x1024): crema, sol groc i una gota turquesa amb una fulleta."""
from PIL import Image, ImageDraw, ImageFilter
import os, math

S = 4096  # supermostreig
img = Image.new("RGBA", (S, S), (247, 241, 230, 255))
d = ImageDraw.Draw(img)

# Halo suau del sol
halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
hd = ImageDraw.Draw(halo)
cx, cy, r = int(S * 0.64), int(S * 0.36), int(S * 0.20)
hd.ellipse([cx - r * 1.7, cy - r * 1.7, cx + r * 1.7, cy + r * 1.7], fill=(242, 203, 102, 110))
halo_base = Image.new("RGBA", (S, S), (242, 203, 102, 0))
alpha = halo.split()[3].filter(ImageFilter.GaussianBlur(S * 0.04))
halo_base.putalpha(alpha)
img = Image.alpha_composite(img, halo_base)
d = ImageDraw.Draw(img)
# Sol
d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(242, 190, 74))

# Gota (cercle + triangle amb corba)
gx, gy, gr = int(S * 0.44), int(S * 0.60), int(S * 0.215)
pts = []
for i in range(0, 361, 2):
    a = math.radians(i)
    # forma de gota: punta cap amunt
    x = gx + gr * math.sin(a) * (1 - 0.0 * math.cos(a))
    y = gy + gr * math.cos(a)
    pts.append((x, y))
d.ellipse([gx - gr, gy - gr, gx + gr, gy + gr], fill=(58, 166, 160))
D = gr * 2.05
phi = math.acos(gr / D)
tip = (gx, gy - D)
left = (gx - gr * math.sin(phi), gy - gr * math.cos(phi))
right = (gx + gr * math.sin(phi), gy - gr * math.cos(phi))
d.polygon([tip, left, (gx, gy), right], fill=(58, 166, 160))
# brillantor de la gota
d.ellipse([gx - gr * 0.55, gy - gr * 0.35, gx - gr * 0.25, gy + gr * 0.15], fill=(140, 214, 208))

# Fulleta verda
fl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
fd = ImageDraw.Draw(fl)
lx, ly = int(S * 0.74), int(S * 0.74)
fd.ellipse([lx - S * 0.11, ly - S * 0.045, lx + S * 0.11, ly + S * 0.045], fill=(111, 163, 94))
fl = fl.rotate(35, center=(lx, ly), resample=Image.BICUBIC)
img = Image.alpha_composite(img, fl)
d = ImageDraw.Draw(img)
d.line([(lx - S * 0.075, ly + S * 0.052), (lx + S * 0.075, ly - S * 0.052)], fill=(247, 241, 230), width=int(S * 0.008))

# Per a iOS, la icona va de vora a vora (el sistema li posa la màscara).
conjunt = os.path.join(os.path.dirname(__file__), "..", "Mariapp", "Resources", "Assets.xcassets", "AppIcon.appiconset")
base = img.convert("RGB")

# Per a Mac: "squircle" (superel·lipse) de 824 px dins d'un llenç de 1024 px, amb ombra suau.
def squircle(mida, n=5.0, sobre=4):
    gran = mida * sobre
    c = gran / 2
    punts = []
    for i in range(1440):
        t = 2 * math.pi * i / 1440
        x = math.copysign(abs(math.cos(t)) ** (2 / n), math.cos(t))
        y = math.copysign(abs(math.sin(t)) ** (2 / n), math.sin(t))
        punts.append((c + c * x, c + c * y))
    m = Image.new("L", (gran, gran), 0)
    ImageDraw.Draw(m).polygon(punts, fill=255)
    return m.resize((mida, mida), Image.LANCZOS)

LLENC, ICONA = 1024, 824
marge = (LLENC - ICONA) // 2
mascara = squircle(ICONA)
peça = base.resize((ICONA, ICONA), Image.LANCZOS)
llenc = Image.new("RGBA", (LLENC, LLENC), (0, 0, 0, 0))
ombra = Image.new("L", (LLENC, LLENC), 0)
ombra.paste(mascara, (marge, marge + 14))
ombra = ombra.filter(ImageFilter.GaussianBlur(18)).point(lambda v: int(v * 0.35))
negre = Image.new("RGBA", (LLENC, LLENC), (60, 40, 20, 0))
negre.putalpha(ombra)
llenc = Image.alpha_composite(llenc, negre)
llenc.paste(peça, (marge, marge), mascara)
mac = os.path.join(conjunt, "AppIcon-mac.png")
llenc.save(mac)
print("Icona de Mac desada a", os.path.abspath(mac))

out = os.path.join(os.path.dirname(__file__), "..", "Mariapp", "Resources", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")
img.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(out)
print("Icona desada a", os.path.abspath(out))
