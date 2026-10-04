#!/bin/bash
# Script para subir automáticamente el archivo obs-assets.zip a GitHub Releases

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP_FILE="$SCRIPT_DIR/obs-assets.zip"
TAG="v1.0"

echo "==============================================="
echo "   Subida Automática a GitHub Releases"
echo "==============================================="

# 1. Comprobar si el archivo ZIP existe
if [ ! -f "$ZIP_FILE" ]; then
    echo "[ERROR] No se encontró el archivo $ZIP_FILE."
    echo "Asegurate de correr ./save_obs_to_repo.sh primero."
    exit 1
fi

# 2. Comprobar si gh (GitHub CLI) está instalado, si no, instalarlo
if ! command -v gh &> /dev/null; then
    echo "[INFO] GitHub CLI (gh) no está instalado. Instalándolo ahora..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update > /dev/null
    sudo apt install gh -y
fi

# 3. Comprobar si el usuario está autenticado
if ! gh auth status &> /dev/null; then
    echo "[INFO] Necesitás iniciar sesión en GitHub."
    echo "IMPORTANTE: Las llaves SSH sirven para hacer 'git push' del código, pero para subir"
    echo "archivos pesados a 'Releases' se necesita autenticación de API."
    echo "Se abrirá tu navegador para que autorices la aplicación de GitHub CLI."
    gh auth login -p ssh -w
fi

# 4. Crear o actualizar la Release
echo "[INFO] Subiendo $ZIP_FILE a GitHub..."

# Comprobar si la Release v1.0 ya existe
if gh release view "$TAG" &> /dev/null; then
    echo "[INFO] La Release $TAG ya existe. Sobrescribiendo el archivo zip..."
    gh release upload "$TAG" "$ZIP_FILE" --clobber
else
    echo "[INFO] Creando una nueva Release $TAG..."
    gh release create "$TAG" "$ZIP_FILE" --title "OBS Assets" --notes "Recursos multimedia para OBS (Imágenes, GIFs, Videos)."
fi

echo "==============================================="
echo " ¡Subida completada con éxito!"
echo " Tu instalador ya puede descargar la versión más reciente."
echo "==============================================="
