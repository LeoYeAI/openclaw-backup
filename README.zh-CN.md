[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## 关于 MyClaw.ai

**[MyClaw.ai](https://myclaw.ai)** 是一个 AI 个人助理平台，为每位用户提供一台拥有完整代码控制权、网络访问和工具调用能力的独立服务器。你的 AI Agent 不只是聊天机器人——它可以写代码、管理文件、执行脚本，现在还能：备份自身并还原到任意新实例。

本 skill 是 [MyClaw.ai](https://myclaw.ai) 开放 skills 生态的一部分，可在任意 OpenClaw 实例上秒级安装。

---

# 🦞 OpenClaw Backup

**OpenClaw 实例一键备份与还原。**

完整备份所有数据——workspace、记忆、skills、凭证、Bot Token、API Key、Agent 对话历史——打包成单个压缩文件。还原到任意新 OpenClaw 实例，无需重新配对频道。

## ⚡ 安装

直接告诉你的 OpenClaw Agent：

> **"帮我安装备份功能"**

或手动安装：
```bash
clawhub install myclaw-backup
```

## 备份内容

| 组件 | 详情 |
|---|---|
| 🧠 Workspace | MEMORY.md、skills、Agent 文件、SOUL.md、USER.md |
| ⚙️ 配置文件 | openclaw.json（Bot Token、API Key、模型配置）|
| 🔑 凭证 | 频道配对状态——还原后无需重新 pair |
| 📜 对话历史 | 完整 Agent 会话记录 |
| ⏰ 定时任务 | 所有 cron job |
| 🛡️ 脚本 | Guardian、watchdog、start-gateway |

## 使用方法

### 创建备份
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### 还原（务必先 dry-run 预览）
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### 浏览器 UI（下载 / 上传 / 还原）
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# 打开：http://localhost:7373/?token=YOUR_TOKEN
```

### 迁移到新服务器
1. 旧机器启动 server → 浏览器下载备份文件
2. 新机器：安装 OpenClaw → 安装本 skill → 上传备份 → 还原
3. 所有频道自动重连——无需重新 pair

## ⚠️ 安全须知

本 skill 处理**高度敏感数据**（Bot Token、API Key、频道凭证）。

- 启动 HTTP server 时必须设置 `--token`（不设置则拒绝启动）
- 备份文件自动设为 `chmod 600`，请妥善保管
- 执行还原前务必先运行 `--dry-run` 确认内容
- 不要在没有 TLS 的情况下将 backup server 暴露到公网

## ClaWHub

发布地址：[clawhub.com/skills/myclaw-backup](https://clawhub.com/skills/myclaw-backup)

---

<p align="center">
  <a href="https://myclaw.ai">
    <img src="https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=for-the-badge" alt="Powered by MyClaw.ai">
  </a>
</p>
