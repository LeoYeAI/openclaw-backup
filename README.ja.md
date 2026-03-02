[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

# 🦞 OpenClaw バックアップ

**OpenClaw インスタンスのワンクリックバックアップ＆リストア。**

ワークスペース、メモリ、スキル、認証情報、ボットトークン、APIキー、エージェントセッション履歴など、すべてを単一の暗号化アーカイブにバックアップします。再ペアリングなしで任意の新しい OpenClaw インスタンスに復元できます。

## ⚡ 1行でインストール

OpenClaw エージェントに伝えるだけ：

> **「バックアップのインストールを手伝って」**

または手動でインストール：
```bash
clawhub install myclaw-backup
```

## バックアップ対象

| コンポーネント | 詳細 |
|---|---|
| 🧠 ワークスペース | MEMORY.md、スキル、エージェントファイル、SOUL.md、USER.md |
| ⚙️ 設定 | openclaw.json（ボットトークン、APIキー、モデル設定）|
| 🔑 認証情報 | チャンネルペアリング状態 — 復元後の再ペアリング不要 |
| 📜 セッション | エージェントの完全な会話履歴 |
| ⏰ Cronジョブ | すべてのスケジュールされたタスク |
| 🛡️ スクリプト | Guardian、watchdog、start-gateway |

## 使い方

### バックアップを作成
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### 復元（常にドライランを先に実行）
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### ブラウザUI（ダウンロード / アップロード / 復元）
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# 開く: http://localhost:7373/?token=YOUR_TOKEN
```

### 新しいサーバーへの移行
1. 古いマシンでサーバーを起動し、ダウンロードURLをコピー
2. 新しいマシンで：OpenClawをインストール → サーバーを起動 → バックアップをアップロード → 復元
3. すべてのチャンネルが自動的に再接続 — 再ペアリング不要

## ⚠️ セキュリティ

このスキルは**高度に機密性の高いデータ**（ボットトークン、APIキー、認証情報）を扱います。

- HTTPサーバー起動時は必ず `--token` を設定してください
- バックアップアーカイブを安全に保存してください（chmod 600 が自動的に適用されます）
- 復元を適用する前に必ず `--dry-run` を実行してください
- TLSなしでバックアップサーバーを公開インターネットに公開しないでください

## ClaWHub

公開先: https://clawhub.com/skills/myclaw-backup

---

<p align="center"><a href="https://myclaw.ai">MyClaw.ai</a> が提供</p>
