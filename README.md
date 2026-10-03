# Ubuntu Setup Script

Script de post-instalación para nuevas distribuciones Ubuntu.

## Contenido instalado y configurado

1. **Git**: Configurado automáticamente con nombre (`Ramiro Barcala Roca`) y correo (`rbarcala@fi.uba.ar`).
2. **Xournal++ y extensión Pen-GUI-n**: Instalación nativa con soporte para plugins/extensiones Lua y fórmulas LaTeX (`lua5.4`, `lua-lgi`, `dvipng`, etc.), creando `~/.config/xournalpp/plugins` e instalando la extensión **Pen-GUI-n** (incluida en el repo o descargada).
3. **Spotify**: Instalación oficial.
4. **Discord + Vencord**: Descarga e instalación del `.deb` oficial de Discord e inyección automática de Vencord mediante su instalador CLI.
5. **OBS Studio**: Repositorio oficial PPA (`ppa:obsproject/obs-studio`) para obtener siempre la última versión.
6. **Grub Customizer**: Repositorio PPA oficial (`ppa:danielrichter2007/grub-customizer`).
7. **MEGA (megasync)**: Repositorio e integración oficial de MEGA.
8. **Visual Studio Code**: Repositorio oficial de Microsoft APT con clave gpg dedicada.
9. **Clipboard Indicator**: Extensión de GNOME Shell con sus requisitos de sistema, liberando el atajo `Super+V` del sistema y asignándolo a la lista del portapapeles.
10. **YoutubeController viewer**: Instalación de dependencias de sistema y ejecución de `make install`, limpiando el repositorio descargado tras finalizar.

## Uso

```bash
git clone https://github.com/rbarcala/setup.git
cd setup
chmod +x setup.sh
./setup.sh
```