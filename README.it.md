[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

# 🦞 OpenClaw Backup

**Backup e ripristino con un clic per le istanze OpenClaw.**

Esegue il backup di tutto — spazio di lavoro, memoria, abilità, credenziali, token bot, chiavi API, cronologia delle sessioni dell'agente — in un singolo archivio crittografato. Ripristina su qualsiasi nuova istanza OpenClaw senza ri-accoppiamento.

## ⚡ Installazione in una riga

Dì semplicemente al tuo agente OpenClaw:

> **"Aiutami a installare il backup"**

Oppure installa manualmente:
```bash
clawhub install myclaw-backup
```

## Cosa viene salvato

| Componente | Dettagli |
|---|---|
| 🧠 Spazio di lavoro | MEMORY.md, abilità, file agente, SOUL.md, USER.md |
| ⚙️ Configurazione | openclaw.json (token bot, chiavi API, config modello) |
| 🔑 Credenziali | Stato di accoppiamento del canale — nessun ri-accoppiamento dopo il ripristino |
| 📜 Sessioni | Cronologia completa delle conversazioni dell'agente |
| ⏰ Cron job | Tutti i task pianificati |
| 🛡️ Script | Guardian, watchdog, start-gateway |

## Utilizzo

### Crea un backup
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Ripristina (esegui sempre prima la prova)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Interfaccia browser (scarica / carica / ripristina)
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Apri: http://localhost:7373/?token=IL_TUO_TOKEN
```

### Migra su un nuovo server
1. Avvia il server sulla vecchia macchina, copia l'URL di download
2. Sulla nuova macchina: installa OpenClaw → avvia il server → carica il backup → ripristina
3. Tutti i canali si riconnettono automaticamente — nessun ri-accoppiamento necessario

## ⚠️ Sicurezza

Questa abilità gestisce **dati altamente sensibili** (token bot, chiavi API, credenziali).

- Imposta sempre `--token` quando avvii il server HTTP
- Conserva gli archivi di backup in modo sicuro (chmod 600 applicato automaticamente)
- Esegui sempre `--dry-run` prima di applicare un ripristino
- Non esporre mai il server di backup a Internet senza TLS

## ClaWHub

Pubblicato su: https://clawhub.com/skills/myclaw-backup

---

<p align="center">Alimentato da <a href="https://myclaw.ai">MyClaw.ai</a></p>
