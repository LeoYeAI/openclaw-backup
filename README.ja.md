[English](README.md) | [中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Italiano](README.it.md) | [Español](README.es.md)

[![Powered by MyClaw.ai](https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=flat-square)](https://myclaw.ai)
[![ClaWHub](https://img.shields.io/badge/ClaWHub-myclaw--backup-orange?style=flat-square)](https://clawhub.com/skills/myclaw-backup)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## MyClaw.ai について

**[MyClaw.ai](https://myclaw.ai)** は、すべてのユーザーに完全なコード制御、ネットワークアクセス、ツール呼び出し能力を持つフルサーバーを提供するAIパーソナルアシスタントプラットフォームです。あなたのAIエージェントは単なるチャットボットではありません——コードを書き、ファイルを管理し、スクリプトを実行し、そして今では：自分自身をバックアップして任意の新しいインスタンスに復元できます。

このスキルは [MyClaw.ai](https://myclaw.ai) のオープンスキルエコシステムの一部です。任意のOpenClawインスタンスに数秒でインストールできます。

---

# 🦞 OpenClaw Backup

**OpenClawインスタンスのワンクリックバックアップ＆リストア。**

ワークスペース、メモリ、スキル、認証情報、Botトークン、APIキー、エージェントのセッション履歴など、すべてを一つのアーカイブにバックアップ。再ペアリングなしで任意の新しいOpenClawインスタンスに復元できます。

## ⚡ インストール

OpenClawエージェントに話しかけるだけ：

> **「バックアップをインストールして」**

または手動で：
```bash
clawhub install myclaw-backup
```

## バックアップ対象

| コンポーネント | 詳細 |
|---|---|
| 🧠 ワークスペース | MEMORY.md、スキル、エージェントファイル、SOUL.md、USER.md |
| ⚙️ 設定 | openclaw.json（Botトークン、APIキー、モデル設定）|
| 🔑 認証情報 | チャンネルペアリング状態——復元後の再ペアリング不要 |
| 📜 セッション | エージェントの完全な会話履歴 |
| ⏰ Cronジョブ | すべてのスケジュールタスク |
| 🛡️ スクリプト | Guardian、watchdog、start-gateway |

## 使用方法

### バックアップ作成
```bash
bash scripts/backup.sh /tmp/openclaw-backups
```

### リストア（必ずdry-runを先に実行）
```bash
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz --dry-run
bash scripts/restore.sh openclaw-backup_TIMESTAMP.tar.gz
```

### ブラウザUI
```bash
bash scripts/serve.sh start --token $(openssl rand -hex 16) --port 7373
# 開く: http://localhost:7373/?token=YOUR_TOKEN
```

### 新サーバーへの移行
1. 旧マシンでサーバー起動 → バックアップをダウンロード
2. 新マシン：OpenClawインストール → このスキルインストール → アップロード → リストア
3. すべてのチャンネルが自動再接続——再ペアリング不要

## ⚠️ セキュリティ

このスキルは**高度に機密性の高いデータ**（トークン、APIキー、認証情報）を扱います。

- HTTPサーバー起動時は`--token`必須（なしでは起動拒否）
- バックアップアーカイブは自動で`chmod 600`
- リストア前に必ず`--dry-run`を実行
- TLSなしでHTTPサーバーをインターネットに公開しないこと

---

<p align="center">
  <a href="https://myclaw.ai">
    <img src="https://img.shields.io/badge/Powered%20by-MyClaw.ai-6366f1?style=for-the-badge" alt="Powered by MyClaw.ai">
  </a>
</p>
