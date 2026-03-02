[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## О MyClaw.ai

**[MyClaw.ai](https://myclaw.ai)** — платформа персонального ИИ-ассистента, которая предоставляет каждому пользователю полноценный сервер с полным контролем над кодом, сетевым доступом и инструментами. Ваш ИИ-агент — не просто чат-бот: он умеет писать код, управлять файлами, выполнять скрипты, а теперь — создавать резервные копии и восстанавливаться на любой новый экземпляр.

Этот skill является частью открытой экосистемы skills [MyClaw.ai](https://myclaw.ai). Устанавливается на любой экземпляр OpenClaw за секунды.

---

# 🦞 OpenClaw Backup

**Резервное копирование и восстановление OpenClaw в один клик.**

Сохраняет всё — workspace, память, skills, учётные данные, токены ботов, API-ключи, историю сессий агента — в единый архив. Восстановление на любой новый экземпляр OpenClaw без повторного сопряжения каналов.

## ⚡ Установка

Просто скажите своему агенту OpenClaw:

> **«Помоги мне установить резервное копирование»**

Или вручную:
```bash
clawhub install myclaw-backup
```

## Что сохраняется

| Компонент | Детали |
|---|---|
| 🧠 Workspace | MEMORY.md, skills, файлы агента, SOUL.md, USER.md |
| ⚙️ Конфигурация | openclaw.json (токены, API-ключи, настройки модели) |
| 🔑 Учётные данные | Состояние сопряжения каналов — без повторного сопряжения |
| 📜 Сессии | Полная история разговоров агента |
| ⏰ Cron-задачи | Все запланированные задачи |
| 🛡️ Скрипты | Guardian, watchdog, start-gateway |

## Использование

### Создание резервной копии
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Восстановление (сначала всегда dry-run)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Веб-интерфейс
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Открыть: http://localhost:7373/?token=ВАШ_ТОКЕН
```

### Миграция на новый сервер
1. Запустить сервер на старой машине → скачать резервную копию
2. Новая машина: установить OpenClaw → установить skill → загрузить → восстановить
3. Все каналы переподключаются автоматически — без повторного сопряжения

## ⚠️ Безопасность

Skill работает с **высокочувствительными данными** (токены, API-ключи, учётные данные).

- `--token` обязателен для HTTP-сервера (без токена сервер не запустится)
- Архивы автоматически получают `chmod 600`
- Перед восстановлением всегда запускайте `--dry-run`
- Не открывайте HTTP-сервер в интернет без TLS

---

<p align="center">
  <a href="https://myclaw.ai">
    <img src="https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=for-the-badge" alt="Powered by MyClaw.ai">
  </a>
</p>
