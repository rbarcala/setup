#!/usr/bin/env bash
# ==============================================================================
# Sincronización de Shaders personalizados del repositorio a OBS Studio
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHADERS_SRC="$SCRIPT_DIR/obs-shaders"
OBS_PLUGIN_DIR="$HOME/.config/obs-studio/plugins/obs-shaderfilter"
OBS_EXAMPLES_DIR="$OBS_PLUGIN_DIR/data/examples"

mkdir -p "$OBS_EXAMPLES_DIR"

echo "[*] Transfiriendo shaders desde $SHADERS_SRC a OBS ($OBS_EXAMPLES_DIR)..."

COUNT=0
for shader_file in "$SHADERS_SRC"/*.shader; do
    if [ -f "$shader_file" ]; then
        name=$(basename "$shader_file")
        dest="$OBS_EXAMPLES_DIR/$name"
        if [ -f "$dest" ] && cmp -s "$shader_file" "$dest"; then
            :
        else
            cp "$shader_file" "$dest"
            echo "  [✓] Instalado/Actualizado: $name"
        fi
        COUNT=$((COUNT + 1))
    fi
done

echo "[OK] $COUNT shaders sincronizados con OBS Studio con éxito."

