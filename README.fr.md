[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

# 🦞 OpenClaw Backup

**Sauvegarde et restauration en un clic pour les instances OpenClaw.**

Sauvegarde tout — espace de travail, mémoire, compétences, identifiants, jetons de bot, clés API, historique des sessions d'agent — dans une seule archive chiffrée. Restaurez sur n'importe quelle nouvelle instance OpenClaw sans re-jumelage.

## ⚡ Installation en une ligne

Dites simplement à votre agent OpenClaw :

> **"Aide-moi à installer la sauvegarde"**

Ou installez manuellement :
```bash
clawhub install myclaw-backup
```

## Ce qui est sauvegardé

| Composant | Détails |
|---|---|
| 🧠 Espace de travail | MEMORY.md, compétences, fichiers d'agent, SOUL.md, USER.md |
| ⚙️ Configuration | openclaw.json (jetons de bot, clés API, config du modèle) |
| 🔑 Identifiants | État de jumelage des canaux — pas de re-jumelage après restauration |
| 📜 Sessions | Historique complet des conversations de l'agent |
| ⏰ Tâches cron | Toutes les tâches planifiées |
| 🛡️ Scripts | Guardian, watchdog, start-gateway |

## Utilisation

### Créer une sauvegarde
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Restaurer (toujours faire un essai à blanc d'abord)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Interface navigateur (télécharger / envoyer / restaurer)
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Ouvrir : http://localhost:7373/?token=VOTRE_TOKEN
```

### Migrer vers un nouveau serveur
1. Démarrez le serveur sur l'ancienne machine, copiez l'URL de téléchargement
2. Sur la nouvelle machine : installez OpenClaw → démarrez le serveur → envoyez la sauvegarde → restaurez
3. Tous les canaux se reconnectent automatiquement — pas de re-jumelage nécessaire

## ⚠️ Sécurité

Cette compétence traite des **données hautement sensibles** (jetons de bot, clés API, identifiants).

- Définissez toujours `--token` lors du démarrage du serveur HTTP
- Stockez les archives de sauvegarde en sécurité (chmod 600 appliqué automatiquement)
- Exécutez toujours `--dry-run` avant d'appliquer une restauration
- N'exposez jamais le serveur de sauvegarde sur Internet sans TLS

## ClaWHub

Publié sur : https://clawhub.com/skills/myclaw-backup

---

<p align="center">Propulsé par <a href="https://myclaw.ai">MyClaw.ai</a></p>
