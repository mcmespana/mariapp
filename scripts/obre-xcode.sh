#!/usr/bin/env bash
# Genera el projecte d'Xcode i l'obri. Executa-ho des de la carpeta del repo:  ./scripts/obre-xcode.sh
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodegen >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Cal Homebrew: https://brew.sh (copia la línia d'instal·lació al Terminal)"; exit 1
  fi
  echo "Instal·lant XcodeGen…"; brew install xcodegen
fi
xcodegen generate
open Mariapp.xcodeproj
