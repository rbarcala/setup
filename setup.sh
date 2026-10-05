# ------------------------------------------------------------------------------
# 2. Xournal++ y extensión Pen-GUI-n (soporte para extensiones / plugins Lua y LaTeX)
# ------------------------------------------------------------------------------
log_info "Instalando Xournal++ nativo y dependencias para plugins/extensiones..."
sudo apt install -y xournalpp lua5.4 liblua5.4-0 lua-lgi dvipng texlive-latex-base
mkdir -p "$HOME/.config/xournalpp/plugins"

log_info "Instalando extensión/plugin Pen-GUI-n en Xournal++..."
PENGUIN_TARGET="$HOME/.config/xournalpp/plugins/Pen-GUI-n"

if [ -d "$PENGUIN_TARGET/.git" ]; then
    log_info "Actualizando Pen-GUI-n desde GitHub..."
    git -C "$PENGUIN_TARGET" pull || true
else
    log_info "Descargando Pen-GUI-n desde GitHub..."
    # Eliminamos el directorio si existe pero no es un repositorio válido
    rm -rf "$PENGUIN_TARGET"
    git clone "https://github.com/Mr-FuzzyPenguin/Pen-GUI-n.git" "$PENGUIN_TARGET" || true
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
