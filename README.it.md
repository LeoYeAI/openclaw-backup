[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## Informazioni su MyClaw.ai

**[MyClaw.ai](https://myclaw.ai)** è una piattaforma di assistente personale IA che offre a ogni utente un server completo con pieno controllo del codice, accesso alla rete e agli strumenti. Il tuo agente IA non è solo un chatbot — può scrivere codice, gestire file, eseguire script e ora: fare il backup di se stesso e ripristinarsi su qualsiasi nuova istanza.

Questo skill fa parte dell'ecosistema open skills di [MyClaw.ai](https://myclaw.ai). Si installa su qualsiasi istanza OpenClaw in pochi secondi.

---

# 🦞 OpenClaw Backup

**Backup e ripristino in un click per le istanze OpenClaw.**

Salva tutto — workspace, memoria, skills, credenziali, token bot, chiavi API, cronologia sessioni — in un unico archivio. Ripristina su qualsiasi nuova istanza OpenClaw senza riassociazione dei canali.

## ⚡ Installazione

Di' semplicemente al tuo agente OpenClaw:

> **"Aiutami a installare il backup"**

Oppure manualmente:
```bash
clawhub install myclaw-backup
```

## Cosa viene salvato

| Componente | Dettagli |
|---|---|
| 🧠 Workspace | MEMORY.md, skills, file agente, SOUL.md, USER.md |
| ⚙️ Configurazione | openclaw.json (token bot, chiavi API, config modello) |
| 🔑 Credenziali | Stato associazione canali — nessuna riassociazione dopo il ripristino |
| 📜 Sessioni | Cronologia completa conversazioni agente |
| ⏰ Cron job | Tutti i task pianificati |
| 🛡️ Script | Guardian, watchdog, start-gateway |

## Utilizzo

### Creare un backup
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Ripristinare (sempre dry-run prima)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Interfaccia browser
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Aprire: http://localhost:7373/?token=IL_TUO_TOKEN
```

### Migrare su un nuovo server
1. Avviare il server sulla vecchia macchina → scaricare il backup
2. Nuova macchina: installare OpenClaw → installare skill → caricare → ripristinare
3. Tutti i canali si riconnettono automaticamente

## ⚠️ Sicurezza

Questo skill gestisce **dati altamente sensibili** (token, chiavi API, credenziali).

- `--token` obbligatorio per il server HTTP (rifiuta l'avvio senza token)
- Gli archivi vengono automaticamente impostati a `chmod 600`
- Eseguire sempre `--dry-run` prima di un ripristino
- Non esporre il server su internet senza TLS

---

<p align="center">
  <a href="https://myclaw.ai">
    <img src="https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=for-the-badge" alt="Powered by MyClaw.ai">
  </a>
</p>
