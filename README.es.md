[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

# 🦞 OpenClaw Backup

**Copia de seguridad y restauración con un clic para instancias OpenClaw.**

Respalda todo — espacio de trabajo, memoria, habilidades, credenciales, tokens de bot, claves API, historial de sesiones del agente — en un único archivo cifrado. Restaura en cualquier nueva instancia OpenClaw sin re-emparejamiento.

## ⚡ Instalación en una línea

Solo dile a tu agente OpenClaw:

> **"Ayúdame a instalar el backup"**

O instala manualmente:
```bash
clawhub install myclaw-backup
```

## Qué se respalda

| Componente | Detalles |
|---|---|
| 🧠 Espacio de trabajo | MEMORY.md, habilidades, archivos de agente, SOUL.md, USER.md |
| ⚙️ Configuración | openclaw.json (tokens de bot, claves API, config del modelo) |
| 🔑 Credenciales | Estado de emparejamiento del canal — sin re-emparejamiento tras restaurar |
| 📜 Sesiones | Historial completo de conversaciones del agente |
| ⏰ Tareas cron | Todas las tareas programadas |
| 🛡️ Scripts | Guardian, watchdog, start-gateway |

## Uso

### Crear una copia de seguridad
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Restaurar (siempre ejecutar primero en modo simulacro)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Interfaz del navegador (descargar / subir / restaurar)
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Abrir: http://localhost:7373/?token=TU_TOKEN
```

### Migrar a un nuevo servidor
1. Inicia el servidor en la máquina antigua, copia la URL de descarga
2. En la nueva máquina: instala OpenClaw → inicia el servidor → sube el backup → restaura
3. Todos los canales se reconectan automáticamente — sin re-emparejamiento necesario

## ⚠️ Seguridad

Esta habilidad maneja **datos altamente sensibles** (tokens de bot, claves API, credenciales).

- Establece siempre `--token` al iniciar el servidor HTTP
- Guarda los archivos de backup de forma segura (chmod 600 aplicado automáticamente)
- Siempre ejecuta `--dry-run` antes de aplicar una restauración
- Nunca expongas el servidor de backup a Internet sin TLS

## ClaWHub

Publicado en: https://clawhub.com/skills/myclaw-backup

---

<p align="center">Desarrollado con <a href="https://myclaw.ai">MyClaw.ai</a></p>
