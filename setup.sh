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

# Obtener directorio donde reside este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
sudo apt install -y curl wget gpg apt-transport-https software-properties-common ca-certificates make build-essential lsb-release

# ------------------------------------------------------------------------------
# Snap (necesario para Spotify, Slack)
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
    # Esperar a que el socket de snap esté listo
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
sudo apt install -y xournalpp lua5.4 liblua5.4-0 lua-lgi dvipng texlive-latex-base
mkdir -p "$HOME/.config/xournalpp/plugins"

log_info "Instalando extensión/plugin Pen-GUI-n en Xournal++..."
PENGUIN_TARGET="$HOME/.config/xournalpp/plugins/Pen-GUI-n"
mkdir -p "$PENGUIN_TARGET"

if [ -d "$SCRIPT_DIR/Pen-GUI-n" ]; then
    log_info "Copiando Pen-GUI-n desde el directorio local del repositorio..."
    cp -r "$SCRIPT_DIR/Pen-GUI-n/"* "$PENGUIN_TARGET/"
else
    if [ -d "$PENGUIN_TARGET/.git" ]; then
        log_info "Actualizando Pen-GUI-n desde GitHub..."
        git -C "$PENGUIN_TARGET" pull || true
    else
        log_info "Descargando Pen-GUI-n desde GitHub..."
        git clone "https://github.com/Mr-FuzzyPenguin/Pen-GUI-n.git" "$PENGUIN_TARGET" || true
    fi
fi
log_success "Xournal++ y extensión Pen-GUI-n instalados en ~/.config/xournalpp/plugins/Pen-GUI-n"

log_info "Instalando tema Dracula para Xournal++..."
DRACULA_TEMP_DIR="$(mktemp -d /tmp/dracula-xournalpp-XXXXXX)"
git clone --depth 1 https://github.com/dracula/xournalpp.git "$DRACULA_TEMP_DIR"

# Copiar paleta de colores
cp "$DRACULA_TEMP_DIR/palette.gpl" "$HOME/.config/xournalpp/palette.gpl"

# Agregar toolbar Dracula a toolbar.ini (solo si no existe ya)
TOOLBAR_INI="$HOME/.config/xournalpp/toolbar.ini"
touch "$TOOLBAR_INI"
if ! grep -q '^\[Dracula\]' "$TOOLBAR_INI"; then
    echo "" >> "$TOOLBAR_INI"
    cat "$DRACULA_TEMP_DIR/dracula-toolbar.ini" >> "$TOOLBAR_INI"
fi

rm -rf "$DRACULA_TEMP_DIR"
log_success "Tema Dracula instalado. Para activarlo manualmente en Xournal++:"
log_info "  1. View → Toolbars → seleccionar 'Dracula'"
log_info "  2. Journal → Configure Page Template → Background Color: #282a36"

# ------------------------------------------------------------------------------
# 3. Spotify
# ------------------------------------------------------------------------------
if command -v spotify >/dev/null 2>&1 || dpkg -l | grep -q spotify-client; then
    log_success "Spotify ya está instalado, saltando."
else
    log_info "Instalando Spotify (vía APT, evitando Snap)..."
    sudo mkdir -p /etc/apt/keyrings
    
    # 1. Descargamos la llave exacta que está pidiendo Ubuntu desde el servidor oficial
    gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 5384CE82BA52C83A 2>/dev/null
    gpg --export 5384CE82BA52C83A | sudo tee /etc/apt/keyrings/spotify-latest.gpg > /dev/null
    
    # 2. Le decimos al repositorio de Spotify que confíe en esa llave
    echo "deb [signed-by=/etc/apt/keyrings/spotify-latest.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
    
    # 3. Instalamos
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install spotify-client -y
    
    log_success "Spotify instalado con éxito."
fi

# ------------------------------------------------------------------------------
# 4. Discord con Vencord
# ------------------------------------------------------------------------------
if dpkg -s discord &>/dev/null; then
    log_success "Discord ya está instalado."
else
    log_info "Instalando Discord (.deb oficial)..."
    DISCORD_DEB="/tmp/discord.deb"
    wget -O "$DISCORD_DEB" "https://discord.com/api/download?platform=linux&format=deb"
    sudo apt install -y "$DISCORD_DEB"
    rm -f "$DISCORD_DEB"
    log_success "Discord instalado."
fi

log_info "Verificando/Inyectando Vencord en Discord..."
VENCORD_BIN="/tmp/VencordInstallerCli-linux"
wget -qO "$VENCORD_BIN" "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli-linux"
chmod +x "$VENCORD_BIN"
"$VENCORD_BIN" -install -branch stable >/dev/null 2>&1 || sudo "$VENCORD_BIN" -install -branch stable >/dev/null 2>&1 || true
rm -f "$VENCORD_BIN"
log_success "Vencord inyectado/actualizado."

# ------------------------------------------------------------------------------
# 5. OBS Studio (PPA oficial de obsproject, versión más reciente)
# ------------------------------------------------------------------------------
if dpkg -s obs-studio &>/dev/null; then
    log_success "OBS Studio ya está instalado, saltando."
else
    log_info "Añadiendo PPA oficial de OBS Studio (obsproject/obs-studio)..."
    sudo add-apt-repository -y ppa:obsproject/obs-studio
    sudo apt update
    sudo apt install -y obs-studio
    log_success "OBS Studio instalado desde PPA obsproject."
fi

log_info "Instalando plugin obs-shaderfilter para OBS Studio..."
OBS_PLUGIN_DIR="$HOME/.config/obs-studio/plugins/obs-shaderfilter"
if [ -d "$OBS_PLUGIN_DIR" ]; then
    log_success "Plugin obs-shaderfilter ya está instalado, saltando."
else
    # Obtener el último release de Ubuntu desde GitHub API
    SHADERFILTER_URL=$(curl -s https://api.github.com/repos/exeldro/obs-shaderfilter/releases/latest | grep browser_download_url | grep -i ubuntu | cut -d '"' -f 4 | head -n 1)
    if [ -n "$SHADERFILTER_URL" ]; then
        log_info "Descargando obs-shaderfilter desde: $SHADERFILTER_URL"
        wget -qO /tmp/obs-shaderfilter.tar.gz "$SHADERFILTER_URL"
        mkdir -p "$HOME/.config/obs-studio/plugins"
        tar -xzf /tmp/obs-shaderfilter.tar.gz -C "$HOME/.config/obs-studio/plugins/"
        rm /tmp/obs-shaderfilter.tar.gz
        log_success "Plugin obs-shaderfilter instalado correctamente."
    else
        log_warn "No se pudo encontrar el paquete para Ubuntu de obs-shaderfilter. Instalación saltada."
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
    
    # 1. Copiar assets a un lugar estándar del sistema para que no dependa de MEGA/DOCS
    ASSETS_DEST="$HOME/.local/share/obs-assets"
    mkdir -p "$ASSETS_DEST"
    
    # Descargar desde GitHub Releases en lugar de copiar localmente
    log_info "Descargando recursos multimedia (Assets) desde GitHub Releases..."
    ASSETS_URL="https://github.com/rbarcala/setup/releases/latest/download/obs-assets.zip"
    rm -f /tmp/obs-assets.zip
    wget -q --show-progress -O /tmp/obs-assets.zip "$ASSETS_URL" || true
    
    # Validar que el archivo descargado sea realmente un ZIP (para evitar errores si GitHub devuelve un 404 html)
    if [ -f "/tmp/obs-assets.zip" ] && file "/tmp/obs-assets.zip" | grep -qi "zip archive"; then
        unzip -o -q /tmp/obs-assets.zip -d /tmp/obs_unzip_temp
        cp -r /tmp/obs_unzip_temp/assets/* "$ASSETS_DEST/" 2>/dev/null || true
        rm -rf /tmp/obs-assets.zip /tmp/obs_unzip_temp
        log_success "Assets descargados e instalados."
    else
        log_warn "No se pudo descargar obs-assets.zip correctamente. ¿Ya lo subiste a GitHub Releases?"
        rm -f /tmp/obs-assets.zip
    fi

    # 2. Copiar escenas y reemplazar las rutas absolutas antiguas por las nuevas
    mkdir -p "$HOME/.config/obs-studio/basic/scenes"
    if [ -d "$SCRIPT_DIR/obs-config/scenes" ]; then
        for scene_file in "$SCRIPT_DIR/obs-config/scenes/"*.json; do
            if [ -f "$scene_file" ]; then
                filename=$(basename "$scene_file")
                DEST_SCENE="$HOME/.config/obs-studio/basic/scenes/$filename"
                cp "$scene_file" "$DEST_SCENE"
                
                # Reemplazar la ruta vieja de los assets (/home/rbarcala/MEGA/DOCS/OBS) por la nueva universal
                sed -i "s|/home/[^/]*/MEGA/DOCS/OBS|$ASSETS_DEST|g" "$DEST_SCENE"
                
                # Reemplazar la ruta vieja del usuario a shaders por la actual ($HOME)
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
    
    # Mostrar advertencia informativa del analizador de OBS
    echo ""
    echo "========================================================================="
    echo " IMPORTANTE: OBS Y WAYLAND (Solución de Lag en NVIDIA)"
    echo "========================================================================="
    echo "El analizador oficial de OBS recomendó evitar que OBS se ejecute bajo XWayland"
    echo "porque produce un desajuste severo en la entrega de fotogramas (frame pacing)"
    echo "y bloquea la captura de PipeWire."
    echo ""
    echo "Si tenés problemas de UI o los paneles se desacomodan:"
    echo "  1. Cerrá OBS por completo: killall -9 obs 2>/dev/null"
    echo "  2. Abrilo desde el menú de aplicaciones (ahora usa -platform wayland)."
    echo "  3. En el menú superior de OBS: Docks > Reset UI (Restablecer interfaz)."
    echo "========================================================================="
    echo ""
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
    sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
    sudo apt update
    sudo apt install -y grub-customizer || {
        log_warn "No se pudo instalar desde el PPA directamente, intentando desde repositorio universe..."
        sudo apt install -y grub-customizer || true
    }
    log_success "Grub Customizer instalado."
fi

# ------------------------------------------------------------------------------
# 7. MEGA (megasync)
# ------------------------------------------------------------------------------
if command -v megasync >/dev/null 2>&1; then
    log_success "MEGA ya está instalado, saltando."
else
    log_info "Configurando repositorio e instalando MEGA (megasync)..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO - https://mega.nz/keys/meganz-archive-keyring.gpg | sudo tee /etc/apt/keyrings/meganz-archive-keyring.gpg >/dev/null

    UBUNTU_RELEASE="$(lsb_release -rs 2>/dev/null || echo '24.04')"

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
    log_success "MEGA instalado."
fi

log_info "Instalando extensión nautilus-megasync..."
sudo apt install -y nautilus-megasync 2>/dev/null || true
log_success "Extensión nautilus-megasync asegurada."

# ------------------------------------------------------------------------------
# 8. Visual Studio Code
# ------------------------------------------------------------------------------
if command -v code >/dev/null 2>&1; then
    log_success "Visual Studio Code ya está instalado, saltando."
else
    log_info "Configurando repositorio e instalando Visual Studio Code..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo apt update
    sudo apt install -y code
    log_success "Visual Studio Code instalado."
fi

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
if command -v youtube-stream-controller >/dev/null 2>&1 || dpkg -s youtube-stream-controller &>/dev/null; then
    log_success "Youtube Playlist / Viewer Controller ya está instalado, saltando."
else
    log_info "Instalando dependencias de Youtube Playlist/Viewer Controller..."
    sudo apt install -y python3-flask yt-dlp python3-requests python3-qrcode gir1.2-gtk-3.0 gir1.2-webkit2-4.1 ffmpeg xdotool wmctrl python3-venv

    CONTROLLER_TEMP_DIR=""

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
fi

# ------------------------------------------------------------------------------
# 11. Slack
# ------------------------------------------------------------------------------
if snap list slack &>/dev/null; then
    log_success "Slack ya está instalado, saltando."
else
    log_info "Instalando Slack..."
    sudo snap install slack || true
    log_success "Slack instalado."
fi

# ------------------------------------------------------------------------------
# 12. Fuentes adicionales (Microsoft Core Fonts: Impact, Arial, etc.)
# ------------------------------------------------------------------------------
if fc-list | grep -qi "Impact"; then
    log_success "La fuente Impact (Microsoft Fonts) ya está instalada, saltando."
else
    log_info "Instalando fuentes de Microsoft (incluyendo Impact)..."
    # Aceptar automáticamente el EULA de Microsoft
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
    sudo apt install -y ttf-mscorefonts-installer
fi

if fc-list | grep -qi "TrashHand"; then
    log_success "La fuente TrashHand ya está instalada, saltando."
else
    log_info "Instalando fuente TrashHand..."
    TRASHHAND_TMP="/tmp/trashhand.zip"
    curl -sL "https://dl.dafont.com/dl/?f=trashhand" -o "$TRASHHAND_TMP"
    mkdir -p "$HOME/.local/share/fonts"
    unzip -o "$TRASHHAND_TMP" -d "$HOME/.local/share/fonts/" > /dev/null
    rm -f "$TRASHHAND_TMP"
fi

log_info "Actualizando caché de fuentes locales..."
fc-cache -f -v "$HOME/.local/share/fonts" > /dev/null
log_success "Caché de fuentes actualizado."

log_info "Configurando interfaz de Firefox (userChrome.css)..."
killall firefox 2>/dev/null || true

# Localizar perfiles de Firefox (Snap, Nativo, Flatpak)
PROFILES=$(find ~/snap/firefox/common/.mozilla/firefox ~/.mozilla/firefox ~/.var/app/org.mozilla.firefox/.mozilla/firefox -maxdepth 2 -name "prefs.js" 2>/dev/null | xargs -r -n1 dirname)

for PROFILE in $PROFILES; do
  mkdir -p "$PROFILE/chrome"
  
  # Habilitar el uso de userChrome.css (requerido en versiones modernas de Firefox)
  USER_JS="$PROFILE/user.js"
  if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$USER_JS" 2>/dev/null; then
      echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$USER_JS"
  fi

  cat << 'EOF' > "$PROFILE/chrome/userChrome.css"
/* Configuración de variables */
:root {
  --autohide-toolbox-delay: 500ms; /* Tiempo de gracia antes de ocultarse */
}

/* La barra se fija arriba sin desplazar el contenido */
#navigator-toolbox {
  position: fixed !important;
  display: block !important;
  width: 100% !important;
  z-index: 1000 !important;
  background-color: #2b2a33 !important;
  transition: transform 0.15s ease-out, opacity 0.15s ease-out !important;
  transition-delay: var(--autohide-toolbox-delay) !important;
  transform-origin: top !important;
}

/* Elementos internos sólidos */
#nav-bar,
#TabsToolbar,
#PersonalToolbar,
#navigator-toolbox > * {
  background-color: #2b2a33 !important;
  background-image: none !important;
}

/* Estado oculto: deja una franja visible en el borde superior para captura segura */
#navigator-toolbox:not(:hover):not(:focus-within):not([customizing]) {
  transform: translateY(calc(-100% + 3px)) !important;
  opacity: 0.01 !important;
}

/* REGLAS DE APERTURA:
   1. Al pasar el mouse por el borde (:hover)
   2. Al enfocar con teclado (Ctrl+L, Ctrl+T)
   3. MIENTRAS ARRASTRAS UNA PESTAÑA (evita que se cierre en mitad del movimiento)
   4. Al abrir un menú contextual o desplegable
*/
#navigator-toolbox:hover,
#navigator-toolbox:focus-within,
#navigator-toolbox[customizing],
#navigator-toolbox:has([open="true"]),
#navigator-toolbox:has([movingtab]),
:root:has([movingtab]) #navigator-toolbox,
:root[dragover] #navigator-toolbox {
  transform: translateY(0) !important;
  opacity: 1 !important;
  transition-delay: 0s !important;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.7) !important;
}
EOF
done
log_success "Configuración de Firefox (auto-ocultar barra) aplicada."

# ------------------------------------------------------------------------------
# Finalización
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}  ¡Instalación y configuración completada con éxito!${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "Nota: Para algunas extensiones de GNOME Shell (como Clipboard Indicator),"
echo -e "puede ser necesario cerrar sesión y volver a entrar o reiniciar GNOME Shell."
