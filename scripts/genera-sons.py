#!/usr/bin/env python3
"""Genera els sonets de Mariapp (WAV 16 bits, 44.1 kHz). Ús: python3 scripts/genera-sons.py"""
import numpy as np, wave, os

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "Mariapp", "Resources", "Sons")

def t(d): return np.linspace(0, d, int(SR * d), endpoint=False)

def env(x, atac=0.005, decai=6.0):
    n = len(x); tt = np.arange(n) / SR
    a = np.minimum(1, tt / atac)
    return x * a * np.exp(-decai * tt)

def nota(f, d, decai=5.0, harm=((1, 1.0), (2, 0.35), (3, 0.12))):
    tt = t(d)
    s = sum(amp * np.sin(2 * np.pi * f * h * tt) for h, amp in harm)
    return env(s, decai=decai)

def desa(nom, s, vol=0.6):
    s = s / (np.max(np.abs(s)) + 1e-9) * vol
    pcm = (s * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, nom + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())

def seq(*parts):
    return np.concatenate(parts)

def silenci(d): return np.zeros(int(SR * d))

os.makedirs(OUT, exist_ok=True)

# 💧 gota: "bloop" amb el to pujant
d = 0.28; tt = t(d)
freq = 500 + 1100 * (tt / d) ** 0.6
fase = 2 * np.pi * np.cumsum(freq) / SR
desa("gota", env(np.sin(fase), atac=0.002, decai=14), 0.55)

# 🔔 campaneta: dues notes de campana
camp = ((1, 1.0), (2.76, 0.4), (5.4, 0.2), (8.9, 0.08))
desa("campaneta", seq(nota(1318.5, 0.35, 5, camp), nota(987.8, 1.1, 3.5, camp)), 0.5)

# ☕️ café: marimba suau, dues notes
mar = ((1, 1.0), (4, 0.25), (10, 0.05))
desa("cafe", seq(nota(523.3, 0.16, 12, mar), nota(784.0, 0.6, 7, mar)), 0.55)

# 😤 queixa: trombó trist "uah uah uah uaaah"
def tromb(f, d, vib=False):
    tt = t(d)
    ff = f * (1 + (0.025 * np.sin(2 * np.pi * 6 * tt) if vib else 0))
    fase = 2 * np.pi * np.cumsum(ff) / SR
    s = sum(np.sin(h * fase) / h for h in range(1, 8))
    a = np.minimum(1, tt / 0.04) * np.minimum(1, (d - tt) / 0.08)
    return s * a
desa("queixa", seq(tromb(311.1, 0.38), silenci(0.05), tromb(293.7, 0.38), silenci(0.05),
                   tromb(277.2, 0.38), silenci(0.05), tromb(261.6, 1.1, vib=True)), 0.45)

# 🚨 sirena de dibuixos animats (metges)
d = 2.6; tt = t(d)
ff = 850 + 280 * np.sign(np.sin(2 * np.pi * 2.2 * tt)) + 30 * np.sin(2 * np.pi * 30 * tt)
fase = 2 * np.pi * np.cumsum(ff) / SR
s = np.sin(fase) + 0.3 * np.sin(2 * fase)
s *= np.minimum(1, tt / 0.03) * np.minimum(1, (d - tt) / 0.1)
desa("sirena", s, 0.5)

# 🎉 festa: arpegi que puja amb brillantor
arp = [523.3, 659.3, 784.0, 1046.5]
parts = [nota(f, 0.11, 9) for f in arp[:-1]] + [nota(1046.5, 0.7, 4) + 0.5 * np.concatenate([np.zeros(0), nota(1568.0, 0.7, 5)])]
desa("festa", seq(*parts), 0.5)
print("Sons generats a", os.path.abspath(OUT))
