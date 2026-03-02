[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## À propos de MyClaw.ai

**[MyClaw.ai](https://myclaw.ai)** est une plateforme d'assistant personnel IA qui offre à chaque utilisateur un serveur complet avec contrôle total du code, accès réseau et appel d'outils. Votre agent IA n'est pas un simple chatbot — il peut écrire du code, gérer des fichiers, exécuter des scripts, et maintenant : se sauvegarder et se restaurer sur n'importe quelle nouvelle instance.

Ce skill fait partie de l'écosystème open skills de [MyClaw.ai](https://myclaw.ai). Installez-le sur n'importe quelle instance OpenClaw en quelques secondes.

---

# 🦞 OpenClaw Backup

**Sauvegarde et restauration en un clic pour les instances OpenClaw.**

Sauvegarde tout — workspace, mémoire, skills, identifiants, tokens bot, clés API, historique de sessions — dans une seule archive. Restaurez sur n'importe quelle nouvelle instance OpenClaw sans recouplage.

## ⚡ Installation

Dites simplement à votre agent OpenClaw :

> **« Aide-moi à installer la sauvegarde »**

Ou manuellement :
```bash
clawhub install myclaw-backup
```

## Ce qui est sauvegardé

| Composant | Détails |
|---|---|
| 🧠 Workspace | MEMORY.md, skills, fichiers agent, SOUL.md, USER.md |
| ⚙️ Configuration | openclaw.json (tokens bot, clés API, config modèle) |
| 🔑 Identifiants | État de couplage des canaux — pas de recouplage après restauration |
| 📜 Sessions | Historique complet des conversations |
| ⏰ Tâches cron | Toutes les tâches planifiées |
| 🛡️ Scripts | Guardian, watchdog, start-gateway |

## Utilisation

### Créer une sauvegarde
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Restaurer (toujours dry-run d'abord)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Interface navigateur
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Ouvrir : http://localhost:7373/?token=VOTRE_TOKEN
```

### Migrer vers un nouveau serveur
1. Démarrer le serveur sur l'ancienne machine → télécharger la sauvegarde
2. Nouvelle machine : installer OpenClaw → installer ce skill → uploader → restaurer
3. Tous les canaux se reconnectent automatiquement

## ⚠️ Sécurité

Ce skill manipule des **données hautement sensibles** (tokens, clés API, identifiants).

- `--token` obligatoire pour le serveur HTTP (refus de démarrage sans token)
- Archives en `chmod 600` automatiquement
- Toujours exécuter `--dry-run` avant une restauration
- Ne pas exposer le serveur sur internet sans TLS

---

<p align="center">
  <a href="https://myclaw.ai">
    <img src="https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=for-the-badge" alt="Powered by MyClaw.ai">
  </a>
</p>
