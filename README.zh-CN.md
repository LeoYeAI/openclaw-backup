[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

# 🦞 OpenClaw 备份

**一键备份与恢复 OpenClaw 实例。**

备份所有内容——工作区、记忆、技能、凭证、机器人令牌、API 密钥、代理会话历史——打包成单个加密归档文件。恢复到任何新的 OpenClaw 实例，无需重新配对。

## ⚡ 一行安装

直接告诉您的 OpenClaw 代理：

> **"帮我安装备份"**

或手动安装：
```bash
clawhub install myclaw-backup
```

## 备份内容

| 组件 | 详情 |
|---|---|
| 🧠 工作区 | MEMORY.md、技能、代理文件、SOUL.md、USER.md |
| ⚙️ 配置 | openclaw.json（机器人令牌、API 密钥、模型配置）|
| 🔑 凭证 | 频道配对状态——恢复后无需重新配对 |
| 📜 会话 | 完整的代理对话历史 |
| ⏰ 定时任务 | 所有已调度的任务 |
| 🛡️ 脚本 | Guardian、watchdog、start-gateway |

## 使用方法

### 创建备份
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### 恢复（始终先进行演习）
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### 浏览器界面（下载 / 上传 / 恢复）
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# 打开：http://localhost:7373/?token=YOUR_TOKEN
```

### 迁移到新服务器
1. 在旧机器上启动服务器，复制下载 URL
2. 在新机器上：安装 OpenClaw → 启动服务器 → 上传备份 → 恢复
3. 所有频道自动重新连接——无需重新配对

## ⚠️ 安全

本技能处理**高度敏感数据**（机器人令牌、API 密钥、凭证）。

- 启动 HTTP 服务器时始终设置 `--token`
- 安全存储备份归档（自动应用 chmod 600）
- 始终在应用恢复之前运行 `--dry-run`
- 不要在没有 TLS 的情况下将备份服务器暴露在公共互联网上

## ClaWHub

发布地址：https://clawhub.com/skills/myclaw-backup

---

<p align="center">由 <a href="https://myclaw.ai">MyClaw.ai</a> 提供支持</p>
