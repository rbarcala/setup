# Makefile para Configuración del Sistema y Recursos de OBS Studio
SHELL := /bin/bash

.PHONY: help setup sync sync-scenes sync-shaders save-obs upload-release test-shaders status clean

help:
	@echo "=================================================================="
	@echo "                   Ubuntu Setup & OBS Makefile                    "
	@echo "=================================================================="
	@echo "Comandos disponibles:"
	@echo "  make setup          -> Ejecuta la instalación y configuración completa del sistema (setup.sh)"
	@echo "  make sync           -> Sincroniza tanto escenas como shaders a OBS Studio"
	@echo "  make sync-scenes    -> Sincroniza escenas del repo a OBS (descarga assets solo si faltan o cambiaron)"
	@echo "  make sync-shaders   -> Transfiere todos los shaders (obs-shaders/) a OBS Studio"
	@echo "  make test-shaders   -> Prueba/compila la sintaxis básica de los shaders personalizados"
	@echo "  make save-obs       -> Guarda tus escenas y assets actuales de OBS hacia el repo y crea zip"
	@echo "  make upload-release -> Sube el archivo obs-assets.zip a GitHub Releases con 'gh'"
	@echo "  make status         -> Muestra el estado de sincronización entre el repo y OBS"
	@echo "  make clean          -> Limpia archivos temporales (.zip huérfanos, logs viejos)"
	@echo "=================================================================="

# Instalación completa del sistema
setup:
	@./setup.sh

# Sincronización completa de OBS (Escenas + Shaders)
sync: sync-scenes sync-shaders
	@echo "✓ Todo el entorno de OBS ha sido sincronizado desde el repositorio."

# Sincronizar escenas y assets de forma inteligente (idempotente)
sync-scenes:
	@./scripts/sync_scenes.sh

# Transferir shaders personalizados al directorio de ejemplos de obs-shaderfilter
sync-shaders:
	@./scripts/sync_shaders.sh

# Probar shaders comprobando integridad sintáctica básica (uniforms bien cerrados, variables requeridas)
test-shaders:
	@echo "[*] Verificando sintaxis e integridad de shaders personalizados..."
	@errors=0; \
	for f in obs-shaders/*.shader; do \
		if ! grep -q "mainImage" "$$f"; then \
			echo "  [FAIL] $$f: No contiene función mainImage"; \
			errors=$$((errors + 1)); \
		fi; \
		if grep -q "uniform float beat_offset" "$$f"; then \
			prev_line=$$(grep -B 1 "uniform float beat_offset" "$$f" | head -n 1); \
			if echo "$$prev_line" | grep -q "step ="; then \
				echo "  [FAIL] $$f: Falta cerrar el bloque anterior antes de beat_offset (> = valor;)"; \
				errors=$$((errors + 1)); \
			fi; \
		fi; \
	done; \
	if [ $$errors -eq 0 ]; then \
		echo "✓ Todos los shaders pasaron la verificación sintáctica."; \
	else \
		echo "✗ Se encontraron $$errors errores en los shaders."; \
		exit 1; \
	fi

# Respaldar la configuración actual de OBS al repositorio
save-obs:
	@./save_obs_to_repo.sh

# Subir assets pesados a GitHub Releases
upload-release:
	@./upload_release.sh

# Comparar estado entre OBS y Repo
status:
	@echo "=================================================================="
	@echo "                 Estado de Sincronización de OBS                  "
	@echo "=================================================================="
	@echo "1. Shaders en Repo: $$(ls -1 obs-shaders/*.shader 2>/dev/null | wc -l)"
	@echo "   Shaders instalados en OBS: $$(ls -1 ~/.config/obs-studio/plugins/obs-shaderfilter/data/examples/*.shader 2>/dev/null | wc -l)"
	@echo "2. Escenas en Repo: $$(ls -1 obs-config/scenes/*.json 2>/dev/null | wc -l)"
	@echo "   Escenas en OBS: $$(ls -1 ~/.config/obs-studio/basic/scenes/*.json 2>/dev/null | wc -l)"
	@echo "3. Assets instalados en ~/.local/share/obs-assets: $$(find ~/.local/share/obs-assets -type f 2>/dev/null | wc -l) archivos"
	@echo "=================================================================="

clean:
	@rm -f /tmp/obs-assets-*.zip /tmp/obs-assets-unpack-*
	@echo "✓ Archivos temporales eliminados."

