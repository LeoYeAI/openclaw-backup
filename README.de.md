[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## Über MyClaw.ai

**[MyClaw.ai](https://myclaw.ai)** ist eine KI-Persönlichkeitsassistenz-Plattform, die jedem Nutzer einen vollständigen Server mit kompletter Codekontrolle, Netzwerkzugang und Toolzugriff bietet. Ihr KI-Agent ist kein einfacher Chatbot — er kann Code schreiben, Dateien verwalten, Skripte ausführen und sich jetzt selbst sichern und auf jede neue Instanz wiederherstellen.

Dieses Skill ist Teil des offenen Skills-Ökosystems von [MyClaw.ai](https://myclaw.ai) und kann auf jeder OpenClaw-Instanz in Sekunden installiert werden.

---

# 🦞 OpenClaw Backup

**Ein-Klick-Backup und -Wiederherstellung für OpenClaw-Instanzen.**

Sichert alles — Workspace, Erinnerungen, Skills, Zugangsdaten, Bot-Token, API-Schlüssel, Agent-Sitzungsverlauf — in einem einzigen Archiv. Stellen Sie auf jeder neuen OpenClaw-Instanz ohne erneutes Pairing wieder her.

## ⚡ Installation

Sagen Sie einfach Ihrem OpenClaw-Agent:

> **„Hilf mir, Backup zu installieren"**

Oder manuell:
```bash
clawhub install myclaw-backup
```

## Was gesichert wird

| Komponente | Details |
|---|---|
| 🧠 Workspace | MEMORY.md, Skills, Agent-Dateien, SOUL.md, USER.md |
| ⚙️ Konfiguration | openclaw.json (Bot-Token, API-Schlüssel, Modellkonfiguration) |
| 🔑 Zugangsdaten | Kanal-Pairing-Status — kein erneutes Pairing nach Wiederherstellung |
| 📜 Sitzungen | Vollständiger Agent-Gesprächsverlauf |
| ⏰ Cron-Jobs | Alle geplanten Aufgaben |
| 🛡️ Skripte | Guardian, Watchdog, Start-Gateway |

## Verwendung

### Backup erstellen
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Wiederherstellen (immer zuerst dry-run)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Browser-Oberfläche
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Öffnen: http://localhost:7373/?token=IHR_TOKEN
```

### Migration auf neuen Server
1. Server auf alter Maschine starten → Backup herunterladen
2. Neue Maschine: OpenClaw installieren → Skill installieren → hochladen → wiederherstellen
3. Alle Kanäle verbinden sich automatisch — kein erneutes Pairing nötig

## ⚠️ Sicherheit

Dieses Skill verarbeitet **hochsensible Daten** (Token, API-Schlüssel, Zugangsdaten).

- `--token` ist für den HTTP-Server Pflicht (startet ohne Token nicht)
- Archive werden automatisch auf `chmod 600` gesetzt
- Immer `--dry-run` vor einer Wiederherstellung ausführen
- HTTP-Server nicht ohne TLS im Internet exponieren

---

<p align="center">
  <a href="https://myclaw.ai">
    <img src="https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=for-the-badge" alt="Powered by MyClaw.ai">
  </a>
</p>
