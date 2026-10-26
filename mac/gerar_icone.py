#!/usr/bin/env python3
"""Gera o .icns do AMiGO Corretor no padrão visual do macOS.

Apps nativos do Big Sur em diante não preenchem o canvas inteiro: o grafismo
ocupa ~82% e o restante é margem transparente. Sem isso o ícone fica maior que
os vizinhos no Dock e destoa.
"""
import os
import subprocess
from PIL import Image, ImageFilter

ORIGEM = "/Users/andrecamargo/amigo-corretor/icon-512.png"
SAIDA = "/private/tmp/claude-501/-Users-andrecamargo/78858404-5057-4e28-b4b8-7d35c4354d00/scratchpad/amigo.iconset"
ICNS = "/private/tmp/claude-501/-Users-andrecamargo/78858404-5057-4e28-b4b8-7d35c4354d00/scratchpad/amigo.icns"

LADO = 1024
ESCALA = 0.82          # proporção do grafismo dentro do canvas (padrão macOS)

os.makedirs(SAIDA, exist_ok=True)

base = Image.open(ORIGEM).convert("RGBA")
alvo = int(LADO * ESCALA)
base = base.resize((alvo, alvo), Image.LANCZOS)

canvas = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))

# Sombra suave, como a que o macOS aplica nos ícones do Dock
sombra = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
recorte = Image.new("RGBA", base.size, (0, 0, 0, 90))
recorte.putalpha(base.getchannel("A").point(lambda v: int(v * 0.35)))
pos = ((LADO - alvo) // 2, (LADO - alvo) // 2 + int(LADO * 0.015))
sombra.paste(recorte, pos, recorte)
sombra = sombra.filter(ImageFilter.GaussianBlur(LADO * 0.012))
canvas = Image.alpha_composite(canvas, sombra)

centro = ((LADO - alvo) // 2, (LADO - alvo) // 2)
canvas.paste(base, centro, base)

# Tamanhos exigidos pelo iconutil
for px in (16, 32, 64, 128, 256, 512, 1024):
    img = canvas.resize((px, px), Image.LANCZOS)
    if px <= 512:
        img.save(f"{SAIDA}/icon_{px}x{px}.png")
    if px >= 32:
        menor = px // 2
        img.save(f"{SAIDA}/icon_{menor}x{menor}@2x.png")

subprocess.run(["iconutil", "-c", "icns", SAIDA, "-o", ICNS], check=True)
print("icns gerado:", ICNS, os.path.getsize(ICNS), "bytes")
