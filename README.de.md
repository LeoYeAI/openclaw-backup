[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

# 🦞 OpenClaw Backup

**Ein-Klick-Backup & Wiederherstellung für OpenClaw-Instanzen.**

Sichert alles — Arbeitsbereich, Speicher, Skills, Anmeldedaten, Bot-Token, API-Schlüssel, Agent-Sitzungsverlauf — in einem einzigen verschlüsselten Archiv. Stellen Sie auf jeder neuen OpenClaw-Instanz ohne erneutes Pairing wieder her.

## ⚡ Installation in einer Zeile

Sagen Sie einfach Ihrem OpenClaw-Agenten:

> **"Hilf mir, das Backup zu installieren"**

Oder manuell installieren:
```bash
clawhub install myclaw-backup
```

## Was wird gesichert

| Komponente | Details |
|---|---|
| 🧠 Arbeitsbereich | MEMORY.md, Skills, Agent-Dateien, SOUL.md, USER.md |
| ⚙️ Konfiguration | openclaw.json (Bot-Token, API-Schlüssel, Modell-Konfiguration) |
| 🔑 Anmeldedaten | Kanal-Pairing-Status — kein erneutes Pairing nach der Wiederherstellung |
| 📜 Sitzungen | Vollständiger Agent-Gesprächsverlauf |
| ⏰ Cron-Jobs | Alle geplanten Aufgaben |
| 🛡️ Skripte | Guardian, Watchdog, start-gateway |

## Verwendung

### Backup erstellen
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Wiederherstellen (immer zuerst Probelauf)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Browser-Oberfläche (herunterladen / hochladen / wiederherstellen)
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Öffnen: http://localhost:7373/?token=IHR_TOKEN
```

### Auf einen neuen Server migrieren
1. Server auf der alten Maschine starten, Download-URL kopieren
2. Auf der neuen Maschine: OpenClaw installieren → Server starten → Backup hochladen → wiederherstellen
3. Alle Kanäle verbinden sich automatisch wieder — kein erneutes Pairing erforderlich

## ⚠️ Sicherheit

Dieser Skill verarbeitet **hochsensible Daten** (Bot-Token, API-Schlüssel, Anmeldedaten).

- Beim Starten des HTTP-Servers immer `--token` setzen
- Backup-Archive sicher aufbewahren (chmod 600 wird automatisch angewendet)
- Immer `--dry-run` ausführen, bevor eine Wiederherstellung angewendet wird
- Den Backup-Server niemals ohne TLS im öffentlichen Internet zugänglich machen

## ClaWHub

Veröffentlicht unter: https://clawhub.com/skills/myclaw-backup

---

<p align="center">Unterstützt von <a href="https://myclaw.ai">MyClaw.ai</a></p>
