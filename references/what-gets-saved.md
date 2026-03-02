# OpenClaw Backup — What Gets Saved

## Backed Up ✅

| Component | Path | Why |
|---|---|---|
| **Workspace** | `~/.openclaw/workspace/` | Agent memory, MEMORY.md, skills, USER.md, SOUL.md, all custom files |
| **Gateway config** | `~/.openclaw/openclaw.json` | Models, channels config, **bot tokens**, **API keys**, plugins |
| **Credentials** | `~/.openclaw/credentials/` | Channel pairing state (telegram-allowFrom, telegram-pairing, etc.) |
| **Channel state** | `~/.openclaw/telegram/` etc. | Update offsets, session data — allows resume without re-pairing |
| **Agent config** | `~/.openclaw/agents/main/agent/` | Model provider config (apiKey, baseUrl, custom models) |
| **Session history** | `~/.openclaw/agents/main/sessions/` | Full conversation history (.jsonl) |
| **Devices** | `~/.openclaw/devices/` | Paired nodes/phones (paired.json) |
| **System skills** | `~/.openclaw/skills/` | Installed skills (find-skills, etc.) |
| **Cron jobs** | `~/.openclaw/cron/` | Scheduled tasks |
| **Identity** | `~/.openclaw/identity/` | Device identity files |
| **Scripts** | `guardian.sh`, `gw-watchdog.sh`, `start-gateway.sh` | Auto-restart and guardian logic |

## NOT Backed Up ❌ (by design)

| Component | Reason |
|---|---|
| `openclaw.log` | Runtime log, not needed for restore |
| Media files (images/audio/video) | Too large, easily regenerated |
| `node_modules/` | Reinstall with npm |
| `.git/` | Source control managed separately |
| Binary assets (png/jpg/mp4/gif/webp) | Size; regenerate as needed |
| `subagents/runs.json` | Ephemeral sub-agent run state, not needed |
| `canvas/index.html` | Static system file, reinstalled with OpenClaw |

## Security Note

The backup archive contains **bot tokens, API keys, and session credentials**.

- Archive is created with `chmod 600` (owner read/write only)
- Store backups in a secure location
- Never commit the `.tar.gz` to a public git repo
- Transfer via scp/sftp, not plain HTTP

## Post-Restore

After restore, all channels reconnect automatically — **no re-pairing needed**.

If Telegram is silent after 30 seconds, send `/start` to your bot to re-trigger the connection.

### Restore to a New Instance

```bash
# On the NEW machine (after installing OpenClaw):
chmod +x restore.sh
./restore.sh /path/to/openclaw-backup_TIMESTAMP.tar.gz --dry-run   # preview first
./restore.sh /path/to/openclaw-backup_TIMESTAMP.tar.gz             # apply
# That's it — no re-pairing needed.
```
