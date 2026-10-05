#!/bin/bash
# Este script guarda tu configuración y recursos actuales de OBS
# hacia la carpeta del repositorio para que setup.sh pueda instalarlos.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/obs-config"
ASSETS_SRC="$HOME/.local/share/obs-assets"
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

# Optimizar y sincronizar escenas (JSONs)
if [ -d "$SCENES_SRC" ]; then
    echo "[INFO] Aplicando optimizaciones de rendimiento a las escenas..."
    # Script de Python embebido para forzar la suspensión de media inactiva
    python3 -c "
import json
import glob

changed_any = False
for file_path in glob.glob('$SCENES_SRC/*.json'):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        file_changed = False
        if 'sources' in data:
            for source in data['sources']:
                # Videos (mp4, webm, etc)
                if source.get('id') == 'ffmpeg_source':
                    settings = source.setdefault('settings', {})
                    if not settings.get('close_when_inactive'):
                        settings['close_when_inactive'] = True
                        file_changed = True
                    if not settings.get('restart_on_activate'):
                        settings['restart_on_activate'] = True
                        file_changed = True
                
                # Gifs e Imágenes
                elif source.get('id') == 'image_source':
                    settings = source.setdefault('settings', {})
                    if not settings.get('unload'):
                        settings['unload'] = True
                        file_changed = True

        if file_changed:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=4)
            print(f'  -> Optimizado: {file_path.split(\"/\")[-1]}')
            changed_any = True
    except Exception as e:
        print(f'  -> Error procesando {file_path}: {e}')

if not changed_any:
    print('  -> Todas las fuentes ya estaban optimizadas.')
"

    echo "[INFO] Sincronizando escenas desde $SCENES_SRC..."
    rsync -av --delete "$SCENES_SRC/"*.json "$CONFIG_DIR/scenes/"
else
    echo "[AVISO] No se encontró el directorio de origen de escenas: $SCENES_SRC"
fi

echo "========================================"
echo " ¡Listo! Configuraciones y recursos de OBS respaldados en el repositorio."
echo " Ahora puedes hacer un 'git commit' y 'git push' para guardarlos en la nube."
echo "========================================"
