#!/usr/bin/env bash
# Crea el projecte de Firebase per a Mariapp amb la teua compte de Google personal.
# Ús (des de la carpeta del repo, al Mac):  ./scripts/configura-firebase.sh
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID="${BUNDLE_ID:-es.mariapp.app}"
REGIO="${REGIO:-eur3}"   # Europa

if ! command -v firebase >/dev/null 2>&1; then
  echo "→ Instal·lant firebase-tools (cal Node.js: https://nodejs.org)…"
  npm install -g firebase-tools
fi

echo "→ Inicia sessió amb la compte de Google PERSONAL (s'obrirà el navegador)"
firebase login

SUFIX=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6)
PROJECTE="${PROJECTE:-mariapp-$SUFIX}"

echo "→ Creant el projecte $PROJECTE…"
firebase projects:create "$PROJECTE" --display-name "Mariapp"

echo "→ Registrant l'app d'Apple ($BUNDLE_ID)…"
APP_ID=$(firebase apps:create IOS "Mariapp" --bundle-id "$BUNDLE_ID" --project "$PROJECTE" --json \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["appId"])')

echo "→ Descarregant GoogleService-Info.plist…"
firebase apps:sdkconfig IOS "$APP_ID" --project "$PROJECTE" > Mariapp/Resources/GoogleService-Info.plist

echo "→ Creant la base de dades Firestore ($REGIO)…"
firebase firestore:databases:create "(default)" --location "$REGIO" --project "$PROJECTE" || true

echo "→ Pujant les regles de seguretat…"
firebase deploy --only firestore:rules --project "$PROJECTE"

URL="https://console.firebase.google.com/project/$PROJECTE/authentication/providers"
echo ""
echo "✅ Quasi fet! Falta UN clic:"
echo "   Obri $URL"
echo "   → 'Get started' (si cal) → 'Anonymous' → Enable → Save"
open "$URL" 2>/dev/null || true
echo ""
echo "Després torna a generar el projecte (./scripts/obre-xcode.sh) i compila."
