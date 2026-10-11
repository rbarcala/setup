#!/usr/bin/env bash
# ==============================================================================
# Sincronización inteligente de Escenas y Assets de OBS
# Descarga solo si no existen o si difieren de la última descarga conocida.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DEST="$HOME/.local/share/obs-assets"
OBS_SCENES_DIR="$HOME/.config/obs-studio/basic/scenes"
STATE_DIR="$HOME/.config/obs-studio/.setup_state"
ASSETS_URL="https://github.com/rbarcala/setup/releases/latest/download/obs-assets.zip"

mkdir -p "$STATE_DIR"
mkdir -p "$ASSETS_DEST"
mkdir -p "$OBS_SCENES_DIR"

# ------------------------------------------------------------------------------
# 1. Comprobación y Descarga Inteligente de Assets
# ------------------------------------------------------------------------------
echo "[*] Verificando recursos multimedia de OBS (Assets)..."

# Obtener ETag o Last-Modified del release remoto de GitHub
REMOTE_INFO=$(curl -sIL "$ASSETS_URL" | grep -iE '^(etag|last-modified|content-length):' | tr -d '\r' | sort || true)
LAST_DOWNLOADED_INFO=""
if [ -f "$STATE_DIR/assets_release.info" ]; then
    LAST_DOWNLOADED_INFO=$(cat "$STATE_DIR/assets_release.info")
fi

ASSETS_COUNT=$(find "$ASSETS_DEST" -type f 2>/dev/null | wc -l)

NEEDS_DOWNLOAD=false
if [ "$ASSETS_COUNT" -eq 0 ]; then
    echo "  [i] No hay assets descargados en $ASSETS_DEST (primera vez)."
    NEEDS_DOWNLOAD=true
elif [ -z "$LAST_DOWNLOADED_INFO" ]; then
    echo "  [i] No se encontró registro previo de descarga de assets."
    NEEDS_DOWNLOAD=true
elif [ "$REMOTE_INFO" != "$LAST_DOWNLOADED_INFO" ]; then
    echo "  [i] Se detectó una versión nueva o diferente en GitHub Releases."
    NEEDS_DOWNLOAD=true
fi

if [ "$NEEDS_DOWNLOAD" = true ]; then
    echo "  [↓] Descargando obs-assets.zip desde GitHub Releases..."
    TMP_ZIP="/tmp/obs-assets-$$.zip"
    TMP_UNPACK="/tmp/obs-assets-unpack-$$"
    rm -f "$TMP_ZIP"
    rm -rf "$TMP_UNPACK"

    # Si ya tenemos un archivo local idéntico (ej. obs-assets.zip en el repo), usarlo
    if [ -f "$SCRIPT_DIR/obs-assets.zip" ] && file "$SCRIPT_DIR/obs-assets.zip" | grep -qi "zip archive"; then
        echo "  [✓] Utilizando obs-assets.zip local del repositorio..."
        cp "$SCRIPT_DIR/obs-assets.zip" "$TMP_ZIP"
    else
        wget -q --show-progress -O "$TMP_ZIP" "$ASSETS_URL" || true
    fi

    if [ -f "$TMP_ZIP" ] && file "$TMP_ZIP" | grep -qi "zip archive"; then
        mkdir -p "$TMP_UNPACK"
        unzip -o -q "$TMP_ZIP" -d "$TMP_UNPACK"
        if [ -d "$TMP_UNPACK/assets" ]; then
            cp -r "$TMP_UNPACK/assets/"* "$ASSETS_DEST/" 2>/dev/null || true
        else
            cp -r "$TMP_UNPACK/"* "$ASSETS_DEST/" 2>/dev/null || true
        fi
        rm -rf "$TMP_ZIP" "$TMP_UNPACK"

        if [ -n "$REMOTE_INFO" ]; then
            echo "$REMOTE_INFO" > "$STATE_DIR/assets_release.info"
        else
            date +%s > "$STATE_DIR/assets_release.info"
        fi
        echo "  [✓] Assets de OBS actualizados e instalados en $ASSETS_DEST"
    else
        echo "  [!] No se pudo descargar u obtener el archivo ZIP válido de assets."
        rm -f "$TMP_ZIP"
    fi
else
    echo "  [✓] Los assets ya están instalados y son idénticos a los del release. Descarga omitida."
fi

# ------------------------------------------------------------------------------
# 2. Transferencia / Despliegue de Escenas del Repo a OBS
# ------------------------------------------------------------------------------
echo "[*] Desplegando escenas desde el repo ($SCRIPT_DIR/obs-config/scenes) a OBS..."
if [ -d "$SCRIPT_DIR/obs-config/scenes" ]; then
    for scene_file in "$SCRIPT_DIR/obs-config/scenes/"*.json; do
        if [ -f "$scene_file" ]; then
            filename=$(basename "$scene_file")
            DEST_SCENE="$OBS_SCENES_DIR/$filename"
            
            # Generar contenido adaptando rutas absolutas al usuario local
            TMP_SCENE="/tmp/$filename.$$"
            sed -e "s|/home/[^/]*/MEGA/DOCS/OBS|$ASSETS_DEST|g" \
                -e "s|/home/[^/]*/\.local/share/obs-assets|$ASSETS_DEST|g" \
                -e "s|/home/[^/]*/\.config|$HOME/.config|g" \
                "$scene_file" > "$TMP_SCENE"

            # Comparar si la escena en OBS ya es idéntica
            if [ -f "$DEST_SCENE" ] && cmp -s "$TMP_SCENE" "$DEST_SCENE"; then
                echo "  [=] Escena '$filename' ya está sincronizada y es idéntica."
                rm -f "$TMP_SCENE"
            else
                cp "$TMP_SCENE" "$DEST_SCENE"
                rm -f "$TMP_SCENE"
                echo "  [✓] Escena '$filename' transferida e instalada en OBS."
            fi
        fi
    done
fi

echo "[✓] Proceso de sincronización de escenas y assets finalizado con éxito."

