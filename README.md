[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## Built on MyClaw.ai

**[MyClaw.ai](https://myclaw.ai)** is an AI personal assistant platform that gives every user a full server with complete code control, networking, and tool access. Your AI agent isn't just a chatbot — it can write code, manage files, run scripts, and now: back itself up and restore to any new instance.

This skill is part of the [MyClaw.ai](https://myclaw.ai) open skills ecosystem. Install it on any OpenClaw instance in seconds.

---

# 🦞 OpenClaw Backup

**One-click backup & restore for OpenClaw instances.**

Backs up everything — workspace, memory, skills, credentials, bot tokens, API keys, agent session history — into a single archive. Restore to any new OpenClaw instance with zero re-pairing.

## ⚡ Install

Just tell your OpenClaw agent:

> **"Help me install backup"**

Or manually:
```bash
clawhub install myclaw-backup
```

## What Gets Backed Up

| Component | Details |
|---|---|
| 🧠 Workspace | MEMORY.md, skills, agent files, SOUL.md, USER.md |
| ⚙️ Config | openclaw.json (bot tokens, API keys, model config) |
| 🔑 Credentials | Channel pairing state — no re-pairing after restore |
| 📜 Sessions | Full agent conversation history |
| ⏰ Cron jobs | All scheduled tasks |
| 🛡️ Scripts | Guardian, watchdog, start-gateway |

## Usage

### Create a backup
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Restore (always dry-run first)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Browser UI (download / upload / restore)
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Open: http://localhost:7373/?token=YOUR_TOKEN
```

### Migrate to a new server
1. Start server on old machine → download backup via browser
2. On new machine: install OpenClaw → install this skill → upload backup → restore
3. All channels reconnect automatically — no re-pairing needed

## ⚠️ Security

This skill handles **highly sensitive data** (bot tokens, API keys, credentials).

- Always set `--token` when starting the HTTP server (required, server refuses to start without it)
- Backup archives are `chmod 600` automatically
- Always run `--dry-run` before applying a restore
- Never expose the backup server to the public internet without TLS

## ClaWHub

Published at: [clawhub.com/skills/myclaw-backup](https://clawhub.com/skills/myclaw-backup)

---

<p align="center">
  <a href="https://myclaw.ai">
    <img src="https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=for-the-badge" alt="Powered by MyClaw.ai">
  </a>
</p>
