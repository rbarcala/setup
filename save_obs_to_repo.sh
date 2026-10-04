#!/bin/bash
# Este script guarda tu configuración y recursos actuales de OBS
# hacia la carpeta del repositorio para que setup.sh pueda instalarlos.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/obs-config"
ASSETS_SRC="/home/$USER/MEGA/DOCS/OBS"
SCENES_SRC="$HOME/.config/obs-studio/basic/scenes"

echo "========================================"
echo " Guardando configuraciones de OBS..."
echo "========================================"

# Crear directorios en el repo si no existen
mkdir -p "$CONFIG_DIR/assets"
mkdir -p "$CONFIG_DIR/scenes"

# Sincronizar assets (imágenes, gifs, etc.)
if [ -d "$ASSETS_SRC" ]; then
    echo "[INFO] Sincronizando assets desde $ASSETS_SRC..."
    rsync -av --delete "$ASSETS_SRC/" "$CONFIG_DIR/assets/"
    
    echo "[INFO] Comprimiendo assets en obs-assets.zip (para subir a GitHub Releases)..."
    (cd "$CONFIG_DIR" && zip -r -q ../obs-assets.zip assets/)
    echo "[OK] Archivo obs-assets.zip generado. Tamaño:"
    du -h "$SCRIPT_DIR/obs-assets.zip"
else
    echo "[AVISO] No se encontró el directorio de origen de assets: $ASSETS_SRC"
fi

# Sincronizar escenas (JSONs)
if [ -d "$SCENES_SRC" ]; then
    echo "[INFO] Sincronizando escenas desde $SCENES_SRC..."
    rsync -av --delete "$SCENES_SRC/"*.json "$CONFIG_DIR/scenes/"
else
    echo "[AVISO] No se encontró el directorio de origen de escenas: $SCENES_SRC"
fi

echo "========================================"
echo " ¡Listo! Configuraciones y recursos de OBS respaldados en el repositorio."
echo " Ahora puedes hacer un 'git commit' y 'git push' para guardarlos en la nube."
echo "========================================"
