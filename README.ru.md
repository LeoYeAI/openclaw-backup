[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

# 🦞 OpenClaw Backup

**Резервное копирование и восстановление экземпляров OpenClaw в один клик.**

Сохраняет всё — рабочее пространство, память, навыки, учётные данные, токены ботов, ключи API, историю сессий агента — в единый зашифрованный архив. Восстанавливайте на любом новом экземпляре OpenClaw без повторного сопряжения.

## ⚡ Установка в одну строку

Просто скажите своему агенту OpenClaw:

> **«Помоги мне установить резервное копирование»**

Или установите вручную:
```bash
clawhub install myclaw-backup
```

## Что сохраняется

| Компонент | Подробности |
|---|---|
| 🧠 Рабочее пространство | MEMORY.md, навыки, файлы агента, SOUL.md, USER.md |
| ⚙️ Конфигурация | openclaw.json (токены ботов, ключи API, конфигурация модели) |
| 🔑 Учётные данные | Состояние сопряжения каналов — повторное сопряжение после восстановления не требуется |
| 📜 Сессии | Полная история разговоров агента |
| ⏰ Задания cron | Все запланированные задачи |
| 🛡️ Скрипты | Guardian, watchdog, start-gateway |

## Использование

### Создать резервную копию
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### Восстановить (всегда сначала пробный запуск)
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### Браузерный интерфейс (скачать / загрузить / восстановить)
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# Открыть: http://localhost:7373/?token=ВАШ_ТОКЕН
```

### Миграция на новый сервер
1. Запустите сервер на старой машине, скопируйте URL для скачивания
2. На новой машине: установите OpenClaw → запустите сервер → загрузите резервную копию → восстановите
3. Все каналы подключаются автоматически — повторное сопряжение не требуется

## ⚠️ Безопасность

Этот навык работает с **крайне чувствительными данными** (токены ботов, ключи API, учётные данные).

- Всегда устанавливайте `--token` при запуске HTTP-сервера
- Храните архивы резервных копий в безопасном месте (chmod 600 применяется автоматически)
- Всегда запускайте `--dry-run` перед применением восстановления
- Никогда не открывайте сервер резервного копирования в публичный интернет без TLS

## ClaWHub

Опубликовано по адресу: https://clawhub.com/skills/myclaw-backup

---

<p align="center">Работает на базе <a href="https://myclaw.ai">MyClaw.ai</a></p>
