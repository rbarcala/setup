#!/usr/bin/env bash
# ==============================================================================
# Setup Script para nuevas instalaciones de Ubuntu
# Ramiro Barcala Roca <rbarcala@fi.uba.ar>
# ==============================================================================

# Obtener directorio donde reside este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/setup.log"

# Iniciar archivo de log y redirigir toda la salida (terminal + archivo de log)
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colores para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[AVISO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Comprobar que no se ejecute el script completo directamente con sudo
if [ "$EUID" -eq 0 ]; then
    log_error "No ejecutes este script como root o con sudo directamente."
    log_info "Ejecútalo como tu usuario habitual: ./setup.sh (el script te pedirá sudo cuando sea necesario)."
    exit 1
fi

# Pedir sudo de antemano y mantenerlo activo
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

log_info "Iniciando instalación y configuración del sistema..."
log_info "Registrando logs en: $LOG_FILE"

# ------------------------------------------------------------------------------
# Dependencias base
# ------------------------------------------------------------------------------
log_info "Instalando paquetes base (curl, wget, gpg, software-properties-common, make, build-essential, unzip, file)..."
sudo apt update
sudo apt install -y curl wget gpg apt-transport-https software-properties-common ca-certificates make build-essential lsb-release unzip file

# ------------------------------------------------------------------------------
# Snap (necesario para Spotify fallback, Slack)
# ------------------------------------------------------------------------------
if ! command -v snap >/dev/null 2>&1; then
    log_info "Instalando snapd..."

    # Linux Mint bloquea snap con nosnap.pref; lo deshabilitamos si existe
    if [ -f /etc/apt/preferences.d/nosnap.pref ]; then
        log_warn "Detectado bloqueo de snap (Linux Mint). Deshabilitando nosnap.pref..."
        sudo mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.pref.backup
        sudo apt update
    fi

    sudo apt install -y snapd
    sudo systemctl enable --now snapd.socket
    sudo snap wait system seed.loaded 2>/dev/null || sleep 5
    log_success "snapd instalado y habilitado."
else
    log_success "snapd ya está disponible."
fi

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
# 2. Xournal++ y extensión Pen-GUI-n (soporte para extensiones / plugins Lua y LaTeX)
# ------------------------------------------------------------------------------
log_info "Instalando Xournal++ nativo y dependencias para plugins/extensiones..."
sudo apt install -y xournalpp lua5.4 liblua5.4-0 lua-lgi dvipng texlive-latex-base || log_warn "Hubo un aviso al instalar dependencias de Xournal++"
mkdir -p "$HOME/.config/xournalpp/plugins"

log_info "Instalando extensión/plugin Pen-GUI-n en Xournal++..."
PENGUIN_TARGET="$HOME/.config/xournalpp/plugins/Pen-GUI-n"

if [ -d "$PENGUIN_TARGET/.git" ]; then
    log_info "Actualizando Pen-GUI-n desde GitHub..."
    git -C "$PENGUIN_TARGET" pull || true
else
    log_info "Descargando Pen-GUI-n desde GitHub..."
    rm -rf "$PENGUIN_TARGET"
    git clone "https://github.com/Mr-FuzzyPenguin/Pen-GUI-n.git" "$PENGUIN_TARGET" || log_warn "No se pudo clonar Pen-GUI-n"
fi
log_success "Xournal++ y extensión Pen-GUI-n configurados."

log_info "Instalando tema Dracula para Xournal++..."
DRACULA_TEMP_DIR="$(mktemp -d /tmp/dracula-xournalpp-XXXXXX)"
if git clone --depth 1 https://github.com/dracula/xournalpp.git "$DRACULA_TEMP_DIR" 2>/dev/null; then
    cp "$DRACULA_TEMP_DIR/palette.gpl" "$HOME/.config/xournalpp/palette.gpl" 2>/dev/null || true
    TOOLBAR_INI="$HOME/.config/xournalpp/toolbar.ini"
    touch "$TOOLBAR_INI"
    if ! grep -q '^\[Dracula\]' "$TOOLBAR_INI" 2>/dev/null; then
        echo "" >> "$TOOLBAR_INI"
        cat "$DRACULA_TEMP_DIR/dracula-toolbar.ini" >> "$TOOLBAR_INI" 2>/dev/null || true
    fi
    log_success "Tema Dracula instalado."
else
    log_warn "No se pudo descargar el tema Dracula para Xournal++."
fi
rm -rf "$DRACULA_TEMP_DIR"

# ------------------------------------------------------------------------------
# 3. Spotify
# ------------------------------------------------------------------------------
if command -v spotify >/dev/null 2>&1 || dpkg -l | grep -q spotify-client; then
    log_success "Spotify ya está instalado, saltando."
else
    log_info "Instalando Spotify (vía APT)..."
    sudo mkdir -p /etc/apt/keyrings
    
    # Descargar llave oficial de Spotify vía HTTPS con fallback a keyserver
    if ! curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc 2>/dev/null | gpg --dearmor --yes -o /etc/apt/keyrings/spotify-latest.gpg 2>/dev/null; then
        curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg 2>/dev/null | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-latest.gpg 2>/dev/null || \
        (gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 5384CE82BA52C83A 2>/dev/null && gpg --export 5384CE82BA52C83A | sudo tee /etc/apt/keyrings/spotify-latest.gpg > /dev/null) || true
    fi
    
    echo "deb [signed-by=/etc/apt/keyrings/spotify-latest.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
    
    sudo apt update || true
    if sudo apt install -y spotify-client; then
        log_success "Spotify instalado con éxito."
    else
        log_warn "No se pudo instalar Spotify vía APT, intentando vía Snap..."
        sudo snap install spotify || log_error "No se pudo instalar Spotify."
    fi
fi

# ------------------------------------------------------------------------------
# 4. Discord con Vencord
# ------------------------------------------------------------------------------
if dpkg -s discord &>/dev/null; then
    log_success "Discord ya está instalado."
else
    log_info "Instalando Discord (.deb oficial)..."
    DISCORD_DEB="/tmp/discord.deb"
    if wget -O "$DISCORD_DEB" "https://discord.com/api/download?platform=linux&format=deb"; then
        sudo apt install -y "$DISCORD_DEB" || sudo apt --fix-broken install -y
        rm -f "$DISCORD_DEB"
        log_success "Discord instalado."
    else
        log_warn "No se pudo descargar Discord."
    fi
fi

log_info "Verificando/Inyectando Vencord en Discord..."
VENCORD_BIN="/tmp/VencordInstallerCli-linux"
if wget -qO "$VENCORD_BIN" "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli-linux"; then
    chmod +x "$VENCORD_BIN"
    "$VENCORD_BIN" -install -branch stable >/dev/null 2>&1 || sudo "$VENCORD_BIN" -install -branch stable >/dev/null 2>&1 || true
    rm -f "$VENCORD_BIN"
    log_success "Vencord inyectado/actualizado."
else
    log_warn "No se pudo descargar el instalador de Vencord."
fi

# ------------------------------------------------------------------------------
# 5. OBS Studio (PPA oficial de obsproject)
# ------------------------------------------------------------------------------
if dpkg -s obs-studio &>/dev/null; then
    log_success "OBS Studio ya está instalado, saltando."
else
    log_info "Añadiendo PPA oficial de OBS Studio (obsproject/obs-studio)..."
    sudo add-apt-repository -y ppa:obsproject/obs-studio 2>/dev/null || log_warn "PPA de OBS no disponible directamente."
    sudo apt update || true
    sudo apt install -y obs-studio || log_error "No se pudo instalar obs-studio."
    log_success "OBS Studio instalado."
fi

log_info "Instalando plugin obs-shaderfilter para OBS Studio..."
OBS_PLUGIN_DIR="$HOME/.config/obs-studio/plugins/obs-shaderfilter"
if [ -d "$OBS_PLUGIN_DIR" ]; then
    log_success "Plugin obs-shaderfilter ya está instalado, saltando."
else
    SHADERFILTER_URL=$(curl -s https://api.github.com/repos/exeldro/obs-shaderfilter/releases/latest 2>/dev/null | grep browser_download_url | grep -i ubuntu | cut -d '"' -f 4 | head -n 1 || true)
    if [ -n "$SHADERFILTER_URL" ]; then
        log_info "Descargando obs-shaderfilter desde: $SHADERFILTER_URL"
        if wget -qO /tmp/obs-shaderfilter.tar.gz "$SHADERFILTER_URL"; then
            mkdir -p "$HOME/.config/obs-studio/plugins"
            tar -xzf /tmp/obs-shaderfilter.tar.gz -C "$HOME/.config/obs-studio/plugins/" || true
            rm -f /tmp/obs-shaderfilter.tar.gz
            log_success "Plugin obs-shaderfilter instalado correctamente."
        fi
    else
        log_warn "No se pudo obtener la URL de obs-shaderfilter desde GitHub API. Instalación saltada."
    fi
fi

# Copiar shaders personalizados si existen en el repositorio
if [ -d "$SCRIPT_DIR/obs-shaders" ]; then
    log_info "Copiando shaders personalizados a OBS..."
    mkdir -p "$OBS_PLUGIN_DIR/data/examples"
    cp "$SCRIPT_DIR/obs-shaders/"*.shader "$OBS_PLUGIN_DIR/data/examples/" 2>/dev/null || true
    log_success "Shaders personalizados instalados."
fi

# Instalar configuraciones y escenas de OBS guardadas en el repo
if [ -d "$SCRIPT_DIR/obs-config" ]; then
    log_info "Instalando configuraciones, escenas y recursos (assets) de OBS..."
    
    ASSETS_DEST="$HOME/.local/share/obs-assets"
    mkdir -p "$ASSETS_DEST"
    
    log_info "Descargando recursos multimedia (Assets) desde GitHub Releases..."
    ASSETS_URL="https://github.com/rbarcala/setup/releases/latest/download/obs-assets.zip"
    rm -f /tmp/obs-assets.zip
    wget -q --show-progress -O /tmp/obs-assets.zip "$ASSETS_URL" || true
    
    if [ -f "/tmp/obs-assets.zip" ] && file "/tmp/obs-assets.zip" | grep -qi "zip archive"; then
        unzip -o -q /tmp/obs-assets.zip -d /tmp/obs_unzip_temp
        cp -r /tmp/obs_unzip_temp/assets/* "$ASSETS_DEST/" 2>/dev/null || true
        rm -rf /tmp/obs-assets.zip /tmp/obs_unzip_temp
        log_success "Assets descargados e instalados."
    else
        log_warn "obs-assets.zip no disponible en Releases aún."
        rm -f /tmp/obs-assets.zip
    fi

    mkdir -p "$HOME/.config/obs-studio/basic/scenes"
    if [ -d "$SCRIPT_DIR/obs-config/scenes" ]; then
        for scene_file in "$SCRIPT_DIR/obs-config/scenes/"*.json; do
            if [ -f "$scene_file" ]; then
                filename=$(basename "$scene_file")
                DEST_SCENE="$HOME/.config/obs-studio/basic/scenes/$filename"
                cp "$scene_file" "$DEST_SCENE"
                sed -i "s|/home/[^/]*/MEGA/DOCS/OBS|$ASSETS_DEST|g" "$DEST_SCENE"
                sed -i "s|/home/[^/]*/\.config|$HOME/.config|g" "$DEST_SCENE"
            fi
        done
        log_success "Escenas de OBS y rutas instaladas."
    fi
fi

# ------------------------------------------------------------------------------
# Parche de OBS para Wayland nativo (Solución a lag y XWayland)
# ------------------------------------------------------------------------------
log_info "Configurando OBS para usar el motor nativo de Wayland (-platform wayland)..."
mkdir -p ~/.local/share/applications
cp /usr/share/applications/*obs*.desktop ~/.local/share/applications/ 2>/dev/null || true

if ls ~/.local/share/applications/*obs*.desktop 1> /dev/null 2>&1; then
    sed -i 's|^Exec=obs|Exec=obs -platform wayland|g' ~/.local/share/applications/*obs*.desktop
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    log_success "OBS configurado para arrancar en Wayland nativo."
else
    log_warn "No se encontró un acceso directo de OBS (.desktop) para parchear a Wayland."
fi

# ------------------------------------------------------------------------------
# 6. Grub Customizer
# ------------------------------------------------------------------------------
if command -v grub-customizer >/dev/null 2>&1; then
    log_success "Grub Customizer ya está instalado, saltando."
else
    log_info "Instalando Grub Customizer..."
    sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer 2>/dev/null || true
    sudo apt update || true
    if ! sudo apt install -y grub-customizer 2>/dev/null; then
        log_warn "No disponible desde PPA, buscando en repositorio universe..."
        sudo apt install -y grub-customizer 2>/dev/null || log_warn "Grub Customizer no está disponible en esta versión de Ubuntu."
    fi
    if command -v grub-customizer >/dev/null 2>&1; then
        log_success "Grub Customizer instalado."
    fi
fi

# ------------------------------------------------------------------------------
# 7. MEGA (megasync)
# ------------------------------------------------------------------------------
if command -v megasync >/dev/null 2>&1; then
    log_success "MEGA ya está instalado, saltando."
else
    log_info "Configurando repositorio e instalando MEGA (megasync)..."
    sudo mkdir -p /etc/apt/keyrings
    
    # Descargar llave de firma oficial de MEGA
    curl -fsSL https://mega.nz/keys/MEGA_signing.key 2>/dev/null | gpg --dearmor --yes 2>/dev/null | sudo tee /etc/apt/keyrings/meganz-archive-keyring.gpg >/dev/null || true

    UBUNTU_RELEASE="$(lsb_release -rs 2>/dev/null || echo '24.04')"

    cat <<EOF | sudo tee /etc/apt/sources.list.d/megaio.sources >/dev/null
Types: deb
URIs: https://mega.nz/linux/repo/xUbuntu_${UBUNTU_RELEASE}/
Suites: ./
Signed-By: /etc/apt/keyrings/meganz-archive-keyring.gpg
EOF

    sudo apt update || true
    if ! sudo apt install -y megasync 2>/dev/null; then
        log_warn "Repositorio específico no encontrado para xUbuntu_${UBUNTU_RELEASE}, intentando fallback xUbuntu_24.04..."
        cat <<EOF | sudo tee /etc/apt/sources.list.d/megaio.sources >/dev/null
Types: deb
URIs: https://mega.nz/linux/repo/xUbuntu_24.04/
Suites: ./
Signed-By: /etc/apt/keyrings/meganz-archive-keyring.gpg
EOF
        sudo apt update || true
        sudo apt install -y megasync 2>/dev/null || log_warn "No se pudo instalar megasync en esta versión de Ubuntu."
    fi
    
    if command -v megasync >/dev/null 2>&1; then
        log_success "MEGA instalado."
    fi
fi

log_info "Instalando extensión nautilus-megasync si está disponible..."
sudo apt install -y nautilus-megasync 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. Visual Studio Code
# ------------------------------------------------------------------------------
if command -v code >/dev/null 2>&1; then
    log_success "Visual Studio Code ya está instalado, saltando."
else
    log_info "Configurando repositorio e instalando Visual Studio Code..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null | gpg --dearmor --yes 2>/dev/null | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null || true
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo apt update || true
    sudo apt install -y code || log_error "No se pudo instalar Visual Studio Code."
    if command -v code >/dev/null 2>&1; then
        log_success "Visual Studio Code instalado."
    fi
fi

# ------------------------------------------------------------------------------
# 9. Clipboard Indicator (Extensión GNOME) + Reemplazo de hotkey Super+V
# ------------------------------------------------------------------------------
log_info "Configurando Clipboard Indicator y hotkey Super+V..."
sudo apt install -y gnome-shell-extension-prefs git dconf-cli libglib2.0-bin || log_warn "Aviso al instalar herramientas de gnome-shell."

EXT_DIR="$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com"
mkdir -p "$(dirname "$EXT_DIR")"

if [ -d "$EXT_DIR" ]; then
    log_info "Actualizando Clipboard Indicator existente..."
    git -C "$EXT_DIR" pull || true
else
    log_info "Descargando Clipboard Indicator desde GitHub..."
    git clone https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator.git "$EXT_DIR" || log_warn "No se pudo descargar Clipboard Indicator."
fi

if [ -d "$EXT_DIR/schemas" ]; then
    # Compilar esquemas en la extensión
    glib-compile-schemas "$EXT_DIR/schemas" 2>/dev/null || true

    # Copiar esquema al directorio glib local para que gsettings lo reconozca globalmente
    mkdir -p "$HOME/.local/share/glib-2.0/schemas"
    cp "$EXT_DIR/schemas/org.gnome.shell.extensions.clipboard-indicator.gschema.xml" "$HOME/.local/share/glib-2.0/schemas/" 2>/dev/null || true
    glib-compile-schemas "$HOME/.local/share/glib-2.0/schemas" 2>/dev/null || true
fi

# Habilitar extensión
gnome-extensions enable clipboard-indicator@tudmotu.com 2>/dev/null || true

# Reemplazar Super+V:
# 1. Desasignar Super+V del mensaje/calendario del sistema (toggle-message-tray)
log_info "Desactivando hotkey por defecto del sistema (Super+V / toggle-message-tray)..."
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]" 2>/dev/null || true
dconf write /org/gnome/shell/keybindings/toggle-message-tray "@as []" 2>/dev/null || true

# 2. Asignar Super+V al menú de Clipboard Indicator
log_info "Asignando Super+V a Clipboard Indicator..."
if [ -d "$EXT_DIR/schemas" ]; then
    gsettings --schemadir "$EXT_DIR/schemas" set org.gnome.shell.extensions.clipboard-indicator toggle-menu "['<Super>v']" 2>/dev/null || true
    gsettings --schemadir "$EXT_DIR/schemas" set org.gnome.shell.extensions.clipboard-indicator enable-keybindings true 2>/dev/null || true
fi
dconf write /org/gnome/shell/extensions/clipboard-indicator/toggle-menu "['<Super>v']" 2>/dev/null || true
dconf write /org/gnome/shell/extensions/clipboard-indicator/enable-keybindings true 2>/dev/null || true

log_success "Clipboard Indicator configurado con hotkey Super+V."

# ------------------------------------------------------------------------------
# 10. YoutubeController viewer
# ------------------------------------------------------------------------------
if command -v youtube-stream-controller >/dev/null 2>&1 || dpkg -s youtube-stream-controller &>/dev/null; then
    log_success "Youtube Playlist / Viewer Controller ya está instalado, saltando."
else
    log_info "Instalando dependencias de Youtube Playlist/Viewer Controller..."
    sudo apt install -y python3-flask yt-dlp python3-requests python3-qrcode gir1.2-gtk-3.0 gir1.2-webkit2-4.1 ffmpeg xdotool wmctrl python3-venv python3-pyqt5 python3-pyqt5.qtwebengine || log_warn "Aviso instalando dependencias de Youtube Controller."

    # Si el repo ya existe adyacente, usarlo; de lo contrario alojarlo permanentemente en ~/.local/share/
    CONTROLLER_INSTALL_DIR="$HOME/.local/share/youtube-stream-controller"
    if [ -d "$SCRIPT_DIR/YoutubePlaylist-ViewerController" ]; then
        CONTROLLER_SRC="$SCRIPT_DIR/YoutubePlaylist-ViewerController"
    elif [ -d "$SCRIPT_DIR/../YoutubePlaylist-ViewerController" ]; then
        CONTROLLER_SRC="$SCRIPT_DIR/../YoutubePlaylist-ViewerController"
    elif [ -d "$CONTROLLER_INSTALL_DIR" ]; then
        CONTROLLER_SRC="$CONTROLLER_INSTALL_DIR"
        log_info "Actualizando Youtube Playlist Controller en $CONTROLLER_SRC..."
        git -C "$CONTROLLER_SRC" pull || true
    else
        CONTROLLER_SRC="$CONTROLLER_INSTALL_DIR"
        log_info "Clonando Youtube Playlist Controller en $CONTROLLER_SRC..."
        mkdir -p "$(dirname "$CONTROLLER_SRC")"
        git clone https://github.com/rbarcala/YoutubePlaylist-ViewerController.git "$CONTROLLER_SRC" || log_warn "No se pudo clonar el repositorio de Youtube Playlist Controller."
    fi

    if [ -n "$CONTROLLER_SRC" ] && [ -d "$CONTROLLER_SRC" ]; then
        log_info "Ejecutando make install en $CONTROLLER_SRC..."
        (
            cd "$CONTROLLER_SRC" || exit 1
            make install
        )

        if command -v youtube-stream-controller >/dev/null 2>&1 || [ -f "$HOME/.local/bin/youtube-stream-controller" ]; then
            log_success "YouTube Stream Controller instalado exitosamente (make install)."
        else
            log_warn "No se pudo verificar la presencia del ejecutable de YouTube Stream Controller."
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 11. Slack
# ------------------------------------------------------------------------------
if snap list slack &>/dev/null; then
    log_success "Slack ya está instalado, saltando."
else
    log_info "Instalando Slack..."
    sudo snap install --classic slack 2>/dev/null || sudo snap install slack 2>/dev/null || log_warn "No se pudo instalar Slack vía Snap."
    if snap list slack &>/dev/null; then
        log_success "Slack instalado."
    fi
fi

# ------------------------------------------------------------------------------
# 12. Fuentes adicionales (Microsoft Core Fonts: Impact, Arial, etc.)
# ------------------------------------------------------------------------------
if fc-list 2>/dev/null | grep -qi "Impact"; then
    log_success "La fuente Impact (Microsoft Fonts) ya está instalada, saltando."
else
    log_info "Instalando fuentes de Microsoft (incluyendo Impact)..."
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
    sudo apt install -y ttf-mscorefonts-installer || log_warn "Aviso instalando fuentes de Microsoft."
fi

if fc-list 2>/dev/null | grep -qi "TrashHand"; then
    log_success "La fuente TrashHand ya está instalada, saltando."
else
    log_info "Instalando fuente TrashHand..."
    TRASHHAND_TMP="/tmp/trashhand.zip"
    if curl -sL "https://dl.dafont.com/dl/?f=trashhand" -o "$TRASHHAND_TMP"; then
        mkdir -p "$HOME/.local/share/fonts"
        unzip -o "$TRASHHAND_TMP" -d "$HOME/.local/share/fonts/" > /dev/null 2>&1 || log_warn "No se pudo descomprimir TrashHand."
        rm -f "$TRASHHAND_TMP"
        log_success "Fuente TrashHand instalada."
    else
        log_warn "No se pudo descargar la fuente TrashHand."
    fi
fi

log_info "Actualizando caché de fuentes locales..."
fc-cache -f -v "$HOME/.local/share/fonts" > /dev/null 2>&1 || true
log_success "Caché de fuentes actualizado."

# ------------------------------------------------------------------------------
# 13. Firefox (userChrome.css)
# ------------------------------------------------------------------------------
log_info "Configurando interfaz de Firefox (userChrome.css)..."
killall firefox 2>/dev/null || true

PROFILES=$(find ~/snap/firefox/common/.mozilla/firefox ~/.mozilla/firefox ~/.var/app/org.mozilla.firefox/.mozilla/firefox -maxdepth 2 -name "prefs.js" 2>/dev/null | xargs -r -n1 dirname || true)

if [ -z "$PROFILES" ]; then
    log_warn "No se encontraron perfiles existentes de Firefox (aún no se abrió el navegador por primera vez)."
    log_info "Abre Firefox una vez y vuelve a correr el script para aplicar el auto-ocultado de barra."
else
    for PROFILE in $PROFILES; do
      mkdir -p "$PROFILE/chrome"
      
      USER_JS="$PROFILE/user.js"
      if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$USER_JS" 2>/dev/null; then
          echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$USER_JS"
      fi

      cat << 'INEOF' > "$PROFILE/chrome/userChrome.css"
:root {
  --autohide-toolbox-delay: 1500ms; /* 1.5 segundos antes de replegarse */
  --autohide-trigger-height: 8px;
}

/* 1. ESTADO BASE: Oculto arriba con margen sensible */
#navigator-toolbox {
  position: fixed !important;
  display: block !important;
  width: 100% !important;
  z-index: 1000 !important;
  background-color: #2b2a33 !important;
  transform-origin: top !important;
  transform: translate3d(0, calc(-100% + var(--autohide-trigger-height)), 0) !important;
  will-change: transform !important;
  transition: transform 0.12s cubic-bezier(0, 0, 0.2, 1) !important;
  transition-delay: var(--autohide-toolbox-delay) !important;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.45) !important;
}

/* Fondos sólidos */
#nav-bar,
#TabsToolbar,
#PersonalToolbar,
#navigator-toolbox > * {
  background-color: #2b2a33 !important;
  background-image: none !important;
}

/* Ocultar barra de direcciones y elementos flotantes mientras la barra está recogida */
#navigator-toolbox:not(:hover):not(:focus-within) :is(#urlbar, #urlbar-container, #urlbar-background, .urlbarView, #searchbar, #navigator-toolbox > *) {
  opacity: 0 !important;
  visibility: hidden !important;
  pointer-events: none !important;
  transition: opacity 0.1s ease, visibility 0.1s !important;
}

/* 2. REGLAS DE APERTURA: Despliegue inmediato al pasar el ratón o enfocar */
#navigator-toolbox:hover,
#navigator-toolbox:active,
#navigator-toolbox:has(:active),
#navigator-toolbox:focus-within,
#navigator-toolbox[customizing],
#navigator-toolbox:has([open="true"]),
#navigator-toolbox:has([movingtab]),
#navigator-toolbox:has([dragover]),
#navigator-toolbox[dragover],
:root:has([movingtab]) #navigator-toolbox,
:root:has([dragover]) #navigator-toolbox,
:root[dragover] #navigator-toolbox {
  transform: translate3d(0, 0, 0) !important;
  transition-delay: 0s !important;
}

#navigator-toolbox:is(:hover, :active, :focus-within, [customizing]) :is(#urlbar, #urlbar-container, #urlbar-background, .urlbarView, #searchbar, #navigator-toolbox > *) {
  opacity: 1 !important;
  visibility: visible !important;
  pointer-events: auto !important;
}
INEOF
    done
    log_success "Configuración de Firefox (auto-ocultar barra) aplicada."
fi

# ------------------------------------------------------------------------------
# Finalización
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}  ¡Instalación y configuración completada con éxito!${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "Todos los detalles y eventos fueron guardados en: $LOG_FILE"
echo -e "Nota: Para algunas extensiones de GNOME Shell (como Clipboard Indicator),"
echo -e "puede ser necesario cerrar sesión y volver a entrar o reiniciar GNOME Shell."
