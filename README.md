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
3. **Spotify**: Instalación oficial vía APT (agregando la llave GPG manualmente para evitar problemas de firmas y evadiendo Snap).
4. **Discord + Vencord**: Descarga e instalación del `.deb` oficial de Discord e inyección automática de Vencord mediante su instalador CLI.
5. **OBS Studio**: Repositorio oficial PPA (`ppa:obsproject/obs-studio`) para obtener siempre la última versión.
   - **obs-shaderfilter**: Plugin de Exeldro descargado automáticamente (última release para Ubuntu).
   - **Shaders personalizados**: Se instalan automáticamente desde la carpeta `obs-shaders/` del repositorio (Caleidoscopio, Contorno Alfa, Recorte de Esquinas, Bajo el Agua, Lupa Magnifier, Glassmorphism, Sombra Paralela, Speed Lines Anime, Distorsión de Calor, Rayos Celestiales / God Rays, Visión Térmica Predator, VHS Glitch CRT, Pixel Art Retro, Arcoiris Giratorio de Baile Tuneado, Pack Progresivo de Shaders de Baile [Nivel 1 al 4: Beat Pump, Strobe RGB, Vórtice Rave, Hardcore Bass Boosted] y parches para Rain Window y Spotlight).
   - **Escenas y Recursos (Assets)**: Se incluye un sistema de backup y restauración. Durante la instalación, las escenas (`.json`) y recursos (imágenes, gifs) de la carpeta `obs-config/` se copian automáticamente al sistema (`~/.local/share/obs-assets/`). Las rutas absolutas dentro de los `.json` se reescriben al vuelo para funcionar en la nueva máquina.
   - **Wayland nativo**: Se clona y parchea el archivo `.desktop` en `~/.local/share/applications` para forzar la ejecución nativa con `obs -platform wayland`.
   
   > ⚠️ **Solución de Lag en NVIDIA (XWayland):** El analizador oficial de OBS advierte que ejecutar OBS bajo la capa de compatibilidad XWayland en tarjetas NVIDIA produce un desajuste severo en la entrega de fotogramas (frame pacing) y bloquea la captura por PipeWire. El script aplica la solución forzando la plataforma Wayland. Si luego de la instalación la interfaz se ve rota o los paneles quedan flotando, simplemente cerrá OBS por completo (`killall -9 obs`), volvelo a abrir y andá al menú superior: **Docks > Reset UI** (Restablecer interfaz). Para verificar el rendimiento, andá a **View > Stats** y asegurate de que el *Average time to render frame* ronde entre 1.5ms - 3ms.

### 🛠️ Comandos Makefile (Sincronización y Testing de OBS)
El repositorio cuenta con un `Makefile` para facilitar la gestión, testeo y transferencia rápida de escenas y shaders:

- `make sync`: Sincroniza tanto escenas como shaders a OBS Studio.
- `make sync-shaders`: Transfiere rápidamente los shaders (`obs-shaders/`) a `~/.config/obs-studio/plugins/obs-shaderfilter/data/examples/` para probarlos en vivo.
- `make sync-scenes`: Sincroniza las escenas del repo a OBS Studio, descargando los recursos (`obs-assets.zip`) únicamente si no se habían descargado antes o si la versión remota en GitHub Releases es distinta a la instalada.
- `make test-shaders`: Ejecuta una comprobación de integridad sintáctica y validación de variables en todos los shaders del repo.
- `make save-obs`: Respalda tus escenas locales de OBS y genera el `.zip` de assets listo para subir.
- `make upload-release`: Sube automáticamente `obs-assets.zip` a GitHub Releases mediante `gh`.
- `make status`: Muestra la cantidad de shaders, escenas y assets instalados versus el repositorio.

6. **Grub Customizer**: Repositorio PPA oficial (`ppa:danielrichter2007/grub-customizer`).
7. **MEGA (megasync)**: Repositorio e integración oficial de MEGA con extensión para Nautilus.
8. **Visual Studio Code**: Repositorio oficial de Microsoft APT con clave GPG dedicada.
9. **Clipboard Indicator**: Extensión de GNOME Shell con hotkey `Super+V` asignada al portapapeles (reemplazando el atajo por defecto del sistema).
10. **YoutubeController viewer**: Instalación de dependencias de sistema y ejecución de `make install` en `~/.local/share/youtube-stream-controller`. Incluye sincronización continua de BPM y fase rítmica con Spotify y OBS Studio (`make test` y `make setup-obs`).
11. **Slack**: Instalación vía snap.
12. **Fuentes**: 
    - **Microsoft Core Fonts**: Instalación del paquete `ttf-mscorefonts-installer` aceptando el EULA automáticamente, para proveer **Impact**, Arial, Times New Roman, etc.
    - **TrashHand**: Descargada automáticamente desde DaFont e instalada en el directorio local del usuario (`~/.local/share/fonts`).
13. **Firefox**: 
    - Activación automática del modo compacto (`browser.uidensity = 1` y `browser.compactmode.show = true`) para optimizar el espacio vertical sin scripts CSS externos ni comportamientos inestables.

## Idempotencia

El script es seguro de ejecutar múltiples veces. Cada sección verifica si la aplicación ya está instalada antes de proceder, evitando descargas y configuraciones innecesarias.

## Uso

```bash
git clone https://github.com/rbarcala/setup.git
cd setup
make setup       # O bien ./setup.sh para instalación completa
make sync        # Para sincronizar shaders y escenas en cualquier momento
```

> **Nota:** No ejecutar con `sudo`. El script pide permisos de superusuario cuando los necesita.