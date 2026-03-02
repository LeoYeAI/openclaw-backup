[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## Acerca de MyClaw.ai

**[MyClaw.ai](https://myclaw.ai)** es una plataforma de asistente personal con IA que proporciona a cada usuario un servidor completo con control total del código, acceso a la red y uso de herramientas. Tu agente IA no es solo un chatbot — puede escribir código, gestionar archivos, ejecutar scripts y ahora: hacer copias de seguridad de sí mismo y restaurarse en cualquier nueva instancia.

Este skill forma parte del ecosistema abierto de skills de [MyClaw.ai](https://myclaw.ai). Se instala en cualquier instancia de OpenClaw en segundos.

---

# 🦞 OpenClaw Backup

**Copia de seguridad y restauración en un clic para instancias OpenClaw.**

Guarda todo — workspace, memoria, skills, credenciales, tokens de bot, claves API, historial de sesiones del agente — en un único archivo. Restaura en cualquier nueva instancia de OpenClaw sin volver a emparejar los canales.

## ⚡ Instalación

Solo dile a tu agente OpenClaw:

> **"Ayúdame a instalar el backup"**

O manualmente:
```bash
clawhub install myclaw-backup
```

## Qué se guarda

| Componente | Detalles |
|---|---|
| 🧠 Workspace | MEMORY.md, skills, archivos del agente, SOUL.md, USER.md |
| ⚙️ Configuración | openclaw.json (tokens de bot, claves API, config del modelo) |
| 🔑 Credenciales | Estado de emparejamiento de canales — sin reemparejamiento al restaurar |
| 📜 Sesiones | Historial completo de conversaciones del agente |
| ⏰ Cron jobs | Todas las tareas programadas |
| 🛡️ Scripts | Guardian, watchdog, start-gateway |

## Uso

### Crear una copia de seguridad
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Restaurar (siempre dry-run primero)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Interfaz web
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Abrir: http://localhost:7373/?token=TU_TOKEN
```

### Migrar a un nuevo servidor
1. Iniciar el servidor en la máquina antigua → descargar la copia de seguridad
2. Nueva máquina: instalar OpenClaw → instalar skill → subir → restaurar
3. Todos los canales se reconectan automáticamente — sin reemparejamiento

## ⚠️ Seguridad

Este skill maneja **datos altamente sensibles** (tokens, claves API, credenciales).

- `--token` obligatorio para el servidor HTTP (rechaza el inicio sin token)
- Los archivos se establecen automáticamente en `chmod 600`
- Siempre ejecutar `--dry-run` antes de una restauración
- No exponer el servidor HTTP a internet sin TLS

---

<p align="center">
  <a href="https://myclaw.ai">
    <img src="https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=for-the-badge" alt="Powered by MyClaw.ai">
  </a>
</p>
