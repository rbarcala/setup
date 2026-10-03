#!/usr/bin/env bash
# ==============================================================================
# Setup Script para nuevas instalaciones de Ubuntu
# Ramiro Barcala Roca <rbarcala@fi.uba.ar>
# ==============================================================================

set -eo pipefail

# Colores para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Comprobar que no se ejecute el script completo directamente con sudo (necesitamos $USER y variables de entorno de escritorio)
if [ "$EUID" -eq 0 ]; then
    log_error "No ejecutes este script como root o con sudo directamente."
    log_info "Ejecútalo como tu usuario habitual: ./setup.sh (el script te pedirá sudo cuando sea necesario)."
    exit 1
fi

# Pedir sudo de antemano y mantenerlo activo
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

log_info "Iniciando instalación y configuración del sistema..."

# ------------------------------------------------------------------------------
# Dependencias base
# ------------------------------------------------------------------------------
log_info "Instalando paquetes base (curl, wget, gpg, software-properties-common, make, build-essential)..."
sudo apt update
sudo apt install -y curl wget gpg apt-transport-https software-properties-common ca-certificates make build-essential

# ------------------------------------------------------------------------------
# 1. Git (Configuración de usuario)
# ------------------------------------------------------------------------------
log_info "Configurando Git..."
sudo apt install -y git
git config --global user.name "Ramiro Barcala Roca"
git config --global user.email "rbarcala@fi.uba.ar"
git config --global init.defaultBranch main
log_success "Git configurado con: $(git config --global user.name) <$(git config --global user.email)>"

# ------------------------------------------------------------------------------
# 2. Xournal++ (con soporte para extensiones / plugins Lua y LaTeX)
# ------------------------------------------------------------------------------
log_info "Instalando Xournal++ nativo y dependencias para plugins/extensiones..."
sudo apt install -y xournalpp lua5.4 liblua5.4-0 lua-lgi dvipng texlive-latex-base
mkdir -p "$HOME/.config/xournalpp/plugins"
log_success "Xournal++ instalado nativamente. Carpeta de plugins lista en ~/.config/xournalpp/plugins"

# ------------------------------------------------------------------------------
# 3. Spotify
# ------------------------------------------------------------------------------
log_info "Instalando Spotify..."
if command -v snap >/dev/null 2>&1; then
    sudo snap install spotify || true
else
    sudo mkdir -p /etc/apt/keyrings
    curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify.gpg
    echo "deb [signed-by=/etc/apt/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt update
    sudo apt install -y spotify-client
fi
log_success "Spotify instalado con éxito."

# ------------------------------------------------------------------------------
# 4. Discord con Vencord
# ------------------------------------------------------------------------------
log_info "Instalando Discord (.deb oficial) y Vencord..."
DISCORD_DEB="/tmp/discord.deb"
wget -O "$DISCORD_DEB" "https://discord.com/api/download?platform=linux&format=deb"
sudo apt install -y "$DISCORD_DEB"
rm -f "$DISCORD_DEB"

VENCORD_BIN="/tmp/VencordInstallerCli-linux"
wget -O "$VENCORD_BIN" "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli-linux"
chmod +x "$VENCORD_BIN"

log_info "Inyectando Vencord en Discord..."
# Intentar parchear a nivel de usuario, o con sudo si el destino requiere permisos
"$VENCORD_BIN" -install -branch stable || sudo "$VENCORD_BIN" -install -branch stable || true
rm -f "$VENCORD_BIN"
log_success "Discord con Vencord instalado."

# ------------------------------------------------------------------------------
# 5. OBS Studio (PPA oficial de obsproject, versión más reciente)
# ------------------------------------------------------------------------------
log_info "Añadiendo PPA oficial de OBS Studio (obsproject/obs-studio)..."
sudo add-apt-repository -y ppa:obsproject/obs-studio
sudo apt update
sudo apt install -y obs-studio
log_success "OBS Studio instalado desde PPA obsproject."

# ------------------------------------------------------------------------------
# 6. Grub Customizer
# ------------------------------------------------------------------------------
log_info "Instalando Grub Customizer..."
sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
sudo apt update
sudo apt install -y grub-customizer || {
    log_warn "No se pudo instalar desde el PPA directamente, intentando desde repositorio universe..."
    sudo apt install -y grub-customizer || true
}
log_success "Grub Customizer instalado."

# ------------------------------------------------------------------------------
# 7. MEGA (megasync)
# ------------------------------------------------------------------------------
log_info "Configurando repositorio e instalando MEGA (megasync)..."
sudo mkdir -p /etc/apt/keyrings
wget -qO - https://mega.nz/keys/meganz-archive-keyring.gpg | sudo tee /etc/apt/keyrings/meganz-archive-keyring.gpg >/dev/null

UBUNTU_CODENAME="$(lsb_release -cs 2>/dev/null || echo 'noble')"
UBUNTU_RELEASE="$(lsb_release -rs 2>/dev/null || echo '24.04')"

# Crear archivo de fuentes para APT
cat <<EOF | sudo tee /etc/apt/sources.list.d/megaio.sources >/dev/null
Types: deb
URIs: https://mega.nz/linux/repo/xUbuntu_${UBUNTU_RELEASE}/
Suites: ./
Signed-By: /etc/apt/keyrings/meganz-archive-keyring.gpg
EOF

sudo apt update || true
if ! sudo apt install -y megasync; then
    log_warn "Repositorio específico no encontrado para xUbuntu_${UBUNTU_RELEASE}, intentando fallback xUbuntu_24.04..."
    cat <<EOF | sudo tee /etc/apt/sources.list.d/megaio.sources >/dev/null
Types: deb
URIs: https://mega.nz/linux/repo/xUbuntu_24.04/
Suites: ./
Signed-By: /etc/apt/keyrings/meganz-archive-keyring.gpg
EOF
    sudo apt update
    sudo apt install -y megasync
fi
sudo apt install -y nautilus-megasync 2>/dev/null || true
log_success "MEGA instalado."

# ------------------------------------------------------------------------------
# 8. Visual Studio Code
# ------------------------------------------------------------------------------
log_info "Configurando repositorio e instalando Visual Studio Code..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
sudo apt update
sudo apt install -y code
log_success "Visual Studio Code instalado."

# ------------------------------------------------------------------------------
# 9. Clipboard Indicator (Extensión GNOME) + Reemplazo de hotkey Super+V
# ------------------------------------------------------------------------------
log_info "Configurando Clipboard Indicator y hotkey Super+V..."
sudo apt install -y gnome-shell-extension-prefs git dconf-cli libglib2.0-bin

EXT_DIR="$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com"
mkdir -p "$(dirname "$EXT_DIR")"

if [ -d "$EXT_DIR" ]; then
    log_info "Actualizando Clipboard Indicator existente..."
    git -C "$EXT_DIR" pull || true
else
    log_info "Descargando Clipboard Indicator desde GitHub..."
    git clone https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator.git "$EXT_DIR"
fi

# Compilar esquemas en la extensión
glib-compile-schemas "$EXT_DIR/schemas"

# Copiar esquema al directorio glib local para que gsettings lo reconozca globalmente
mkdir -p "$HOME/.local/share/glib-2.0/schemas"
cp "$EXT_DIR/schemas/org.gnome.shell.extensions.clipboard-indicator.gschema.xml" "$HOME/.local/share/glib-2.0/schemas/"
glib-compile-schemas "$HOME/.local/share/glib-2.0/schemas"

# Habilitar extensión
gnome-extensions enable clipboard-indicator@tudmotu.com 2>/dev/null || true

# Reemplazar Super+V:
# 1. Desasignar Super+V del mensaje/calendario del sistema (toggle-message-tray)
log_info "Desactivando hotkey por defecto del sistema (Super+V / toggle-message-tray)..."
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]" 2>/dev/null || true
dconf write /org/gnome/shell/keybindings/toggle-message-tray "@as []" 2>/dev/null || true

# 2. Asignar Super+V al menú de Clipboard Indicator
log_info "Asignando Super+V a Clipboard Indicator..."
gsettings --schemadir "$EXT_DIR/schemas" set org.gnome.shell.extensions.clipboard-indicator toggle-menu "['<Super>v']" 2>/dev/null || true
gsettings --schemadir "$EXT_DIR/schemas" set org.gnome.shell.extensions.clipboard-indicator enable-keybindings true 2>/dev/null || true
dconf write /org/gnome/shell/extensions/clipboard-indicator/toggle-menu "['<Super>v']" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/clipboard-indicator/enable-keybindings true 2>/dev/null || true

log_success "Clipboard Indicator configurado con hotkey Super+V."

# ------------------------------------------------------------------------------
# 10. YoutubeController viewer
# ------------------------------------------------------------------------------
log_info "Instalando dependencias de Youtube Playlist/Viewer Controller..."
sudo apt install -y python3-flask yt-dlp python3-requests python3-qrcode gir1.2-gtk-3.0 gir1.2-webkit2-4.1 ffmpeg xdotool wmctrl python3-venv

CONTROLLER_TEMP_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar si el repo ya está en la misma carpeta o adyacente, de lo contrario clonarlo temporalmente
if [ -d "$SCRIPT_DIR/YoutubePlaylist-ViewerController" ]; then
    CONTROLLER_SRC="$SCRIPT_DIR/YoutubePlaylist-ViewerController"
    DELETE_AFTER_INSTALL=false
elif [ -d "$SCRIPT_DIR/../YoutubePlaylist-ViewerController" ]; then
    CONTROLLER_SRC="$SCRIPT_DIR/../YoutubePlaylist-ViewerController"
    DELETE_AFTER_INSTALL=false
else
    CONTROLLER_TEMP_DIR="$(mktemp -d /tmp/youtube-stream-controller-XXXXXX)"
    log_info "Descargando Youtube Playlist Controller a $CONTROLLER_TEMP_DIR..."
    git clone https://github.com/rbarcala/YoutubePlaylist-ViewerController.git "$CONTROLLER_TEMP_DIR"
    CONTROLLER_SRC="$CONTROLLER_TEMP_DIR"
    DELETE_AFTER_INSTALL=true
fi

log_info "Ejecutando make install en $CONTROLLER_SRC..."
(
    cd "$CONTROLLER_SRC"
    make install
    # Si existe target de deb y herramientas, instalar deb del sistema para garantizar persistencia global
    if [ -f "release/youtube-stream-controller_1.0.0_all.deb" ]; then
        sudo apt install -y ./release/youtube-stream-controller_1.0.0_all.deb || true
    fi
)

# Si se descargó en temporal, borrar el repositorio descargado
if [ "$DELETE_AFTER_INSTALL" = true ] && [ -n "$CONTROLLER_TEMP_DIR" ] && [ -d "$CONTROLLER_TEMP_DIR" ]; then
    log_info "Eliminando repositorio temporal descargado ($CONTROLLER_TEMP_DIR)..."
    rm -rf "$CONTROLLER_TEMP_DIR"
fi

log_success "Youtube Playlist / Viewer Controller instalado."

# ------------------------------------------------------------------------------
# Finalización
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}  ¡Instalación y configuración completada con éxito!${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "Nota: Para algunas extensiones de GNOME Shell (como Clipboard Indicator),"
echo -e "puede ser necesario cerrar sesión y volver a entrar o reiniciar GNOME Shell."
