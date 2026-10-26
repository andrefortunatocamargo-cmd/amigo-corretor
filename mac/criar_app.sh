#!/bin/bash
# Recria o "AMiGO Corretor.app" na Área de Trabalho.
# Use se o app for apagado ou se o ícone/atalho precisar ser refeito.
set -e

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP="$HOME/Desktop/AMiGO Corretor.app"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1. Ícone no padrão macOS (grafismo a 82% do canvas + sombra)
python3 - "$REPO/icon-512.png" "$TMP" <<'PY'
import sys, os, subprocess
from PIL import Image, ImageFilter
origem, tmp = sys.argv[1], sys.argv[2]
iconset = os.path.join(tmp, "amigo.iconset"); os.makedirs(iconset, exist_ok=True)
LADO, ESCALA = 1024, 0.82
base = Image.open(origem).convert("RGBA")
alvo = int(LADO * ESCALA)
base = base.resize((alvo, alvo), Image.LANCZOS)
canvas = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
sombra = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
rec = Image.new("RGBA", base.size, (0, 0, 0, 90))
rec.putalpha(base.getchannel("A").point(lambda v: int(v * 0.35)))
sombra.paste(rec, ((LADO-alvo)//2, (LADO-alvo)//2 + int(LADO*0.015)), rec)
sombra = sombra.filter(ImageFilter.GaussianBlur(LADO*0.012))
canvas = Image.alpha_composite(canvas, sombra)
canvas.paste(base, ((LADO-alvo)//2, (LADO-alvo)//2), base)
for px in (16, 32, 64, 128, 256, 512, 1024):
    img = canvas.resize((px, px), Image.LANCZOS)
    if px <= 512: img.save(f"{iconset}/icon_{px}x{px}.png")
    if px >= 32:  img.save(f"{iconset}/icon_{px//2}x{px//2}@2x.png")
subprocess.run(["iconutil", "-c", "icns", iconset, "-o", os.path.join(tmp, "amigo.icns")], check=True)
PY

# 2. Bundle
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$REPO/mac/launcher.sh" "$APP/Contents/MacOS/AMiGOCorretor"
chmod +x "$APP/Contents/MacOS/AMiGOCorretor"
cp "$TMP/amigo.icns" "$APP/Contents/Resources/amigo.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>              <string>AMiGO Corretor</string>
  <key>CFBundleDisplayName</key>       <string>AMiGO Corretor</string>
  <key>CFBundleIdentifier</key>        <string>br.com.essense.amigocorretor</string>
  <key>CFBundleVersion</key>           <string>3.0</string>
  <key>CFBundleShortVersionString</key><string>3.0</string>
  <key>CFBundleExecutable</key>        <string>AMiGOCorretor</string>
  <key>CFBundleIconFile</key>          <string>amigo</string>
  <key>CFBundlePackageType</key>       <string>APPL</string>
  <key>LSMinimumSystemVersion</key>    <string>11.0</string>
  <key>NSHighResolutionCapable</key>   <true/>
  <key>LSApplicationCategoryType</key> <string>public.app-category.business</string>
  <key>NSHumanReadableCopyright</key>  <string>Essense Negócios Imobiliários</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" 2>/dev/null || true
echo "Pronto: $APP"
