# Ubuntu Setup Script

Script de post-instalación para nuevas distribuciones Ubuntu.

## Contenido instalado y configurado

### Dependencias base

- **Paquetes base**: `curl`, `wget`, `gpg`, `software-properties-common`, `make`, `build-essential`, `lsb-release`, etc.
- **snapd**: Instalado automáticamente si no está presente. En **Linux Mint** se detecta y deshabilita el bloqueo `nosnap.pref` antes de instalar.

### Aplicaciones

1. **Git**: Configurado automáticamente con nombre (`Ramiro Barcala Roca`) y correo (`rbarcala@fi.uba.ar`).
2. **Xournal++**: Instalación nativa con soporte para plugins/extensiones Lua y fórmulas LaTeX (`lua5.4`, `lua-lgi`, `dvipng`, etc.).
   - **Pen-GUI-n**: Extensión de interfaz gráfica (incluida en el repo o descargada desde GitHub).
   - **Dracula theme**: Paleta de colores y toolbar Dracula. Requiere activación manual en Xournal++ (*View → Toolbars → Dracula* y color de fondo `#282a36`).
3. **Spotify**: Instalación vía snap (o repositorio apt como fallback).
4. **Discord + Vencord**: Descarga e instalación del `.deb` oficial de Discord e inyección automática de Vencord mediante su instalador CLI.
5. **OBS Studio**: Repositorio oficial PPA (`ppa:obsproject/obs-studio`) para obtener siempre la última versión.
   - **obs-shaderfilter**: Plugin de Exeldro descargado automáticamente (última release para Ubuntu).
   - **Shaders personalizados**: Se instalan automáticamente desde la carpeta `obs-shaders/` del repositorio (Caleidoscopio, Contorno Alfa, Recorte de Esquinas, Bajo el Agua y un parche para Rain Window sin zoom forzado).
   - **Escenas y Recursos (Assets)**: Se incluye un sistema de backup y restauración. Durante la instalación, las escenas (`.json`) y recursos (imágenes, gifs) de la carpeta `obs-config/` se copian automáticamente al sistema (`~/.local/share/obs-assets/`). Las rutas absolutas dentro de los `.json` se reescriben al vuelo para funcionar en la nueva máquina.
   - **Wayland nativo**: Se clona y parchea el archivo `.desktop` en `~/.local/share/applications` para forzar `QT_QPA_PLATFORM=wayland`. Además, el script limpia automáticamente la geometría de los paneles guardada en `user.ini` para evitar que la UI se rompa por el cambio de X11 a Wayland.

### 🛠️ Script Auxiliar: `save_obs_to_repo.sh`
Se incluye el script `save_obs_to_repo.sh` para facilitar las actualizaciones. Si modificás tus escenas en OBS o agregás imágenes/videos nuevos a la carpeta de recursos del sistema (`~/.local/share/obs-assets`), simplemente ejecutá `./save_obs_to_repo.sh` y el script copiará automáticamente la última versión de tus JSON y generará el `.zip` listo para subir a GitHub Releases.
6. **Grub Customizer**: Repositorio PPA oficial (`ppa:danielrichter2007/grub-customizer`).
7. **MEGA (megasync)**: Repositorio e integración oficial de MEGA con extensión para Nautilus.
8. **Visual Studio Code**: Repositorio oficial de Microsoft APT con clave GPG dedicada.
9. **Clipboard Indicator**: Extensión de GNOME Shell con hotkey `Super+V` asignada al portapapeles (reemplazando el atajo por defecto del sistema).
10. **YoutubeController viewer**: Instalación de dependencias de sistema y ejecución de `make install`, limpiando el repositorio descargado tras finalizar.
11. **Slack**: Instalación vía snap.
12. **Fuentes**: 
    - **Microsoft Core Fonts**: Instalación del paquete `ttf-mscorefonts-installer` aceptando el EULA automáticamente, para proveer **Impact**, Arial, Times New Roman, etc.
    - **TrashHand**: Descargada automáticamente desde DaFont e instalada en el directorio local del usuario (`~/.local/share/fonts`).

## Idempotencia

El script es seguro de ejecutar múltiples veces. Cada sección verifica si la aplicación ya está instalada antes de proceder, evitando descargas y configuraciones innecesarias.

## Uso

```bash
git clone https://github.com/rbarcala/setup.git
cd setup
chmod +x setup.sh
./setup.sh
```

> **Nota:** No ejecutar con `sudo`. El script pide permisos de superusuario cuando los necesita.