#!/usr/bin/env bash
# openclaw-backup: Create a full backup of OpenClaw data
# Usage: backup.sh [output-dir]
#   output-dir: where to save the .tar.gz (default: /tmp/openclaw-backups)

set -euo pipefail

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="${1:-/tmp/openclaw-backups}"

# Agent name: read from IDENTITY.md if present, fallback to hostname
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
IDENTITY_FILE="${WORKSPACE_DIR}/IDENTITY.md"
if [ -f "$IDENTITY_FILE" ]; then
  AGENT_NAME=$(grep -m1 '\*\*Name:\*\*' "$IDENTITY_FILE" 2>/dev/null | sed 's/.*\*\*Name:\*\* *//' | tr -d '\r' | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
fi
AGENT_NAME="${AGENT_NAME:-$(hostname)}"

BACKUP_NAME="openclaw-backup_${AGENT_NAME}_${TIMESTAMP}"
WORK_DIR="/tmp/${BACKUP_NAME}"
OPENCLAW_HOME="${HOME}/.openclaw"

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

echo ""
echo "🦞 OpenClaw Backup — ${TIMESTAMP}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

# ── 1. Workspace (memory, skills, agent files) ────────────────────────────
info "Backing up workspace..."
WORKSPACE_DIR="${OPENCLAW_HOME}/workspace"
if [ -d "$WORKSPACE_DIR" ]; then
  mkdir -p "${WORK_DIR}/workspace"
  rsync -a \
    --exclude='node_modules/' \
    --exclude='.git/' \
    --exclude='*.tar.gz' \
    --exclude='*.skill' \
    --exclude='*.zip' \
    --exclude='*.png' \
    --exclude='*.jpg' \
    --exclude='*.jpeg' \
    --exclude='*.gif' \
    --exclude='*.webp' \
    --exclude='*.mp4' \
    --exclude='*.mp3' \
    "$WORKSPACE_DIR/" "${WORK_DIR}/workspace/"
  info "  workspace → $(du -sh ${WORK_DIR}/workspace | cut -f1)"
else
  warn "  workspace directory not found, skipping"
fi

# ── 2. Gateway config (openclaw.json) ────────────────────────────────────
# Contains bot tokens, model API keys, channel config — all needed for restore
info "Backing up Gateway config..."
CONFIG_FILE="${OPENCLAW_HOME}/openclaw.json"
if [ -f "$CONFIG_FILE" ]; then
  mkdir -p "${WORK_DIR}/config"
  cp "$CONFIG_FILE" "${WORK_DIR}/config/openclaw.json"
  [ -f "${CONFIG_FILE}.bak" ] && cp "${CONFIG_FILE}.bak" "${WORK_DIR}/config/openclaw.json.bak"
  info "  openclaw.json → $(wc -c < ${WORK_DIR}/config/openclaw.json) bytes"
else
  warn "  openclaw.json not found, skipping"
fi

# ── 3. System-level skills (~/.openclaw/skills/) ─────────────────────────
info "Backing up system skills..."
SYSTEM_SKILLS_DIR="${OPENCLAW_HOME}/skills"
if [ -d "$SYSTEM_SKILLS_DIR" ] && [ -n "$(ls -A ${SYSTEM_SKILLS_DIR} 2>/dev/null)" ]; then
  mkdir -p "${WORK_DIR}/skills/system"
  rsync -a "$SYSTEM_SKILLS_DIR/" "${WORK_DIR}/skills/system/"
  info "  system skills → $(ls ${WORK_DIR}/skills/system | wc -l | tr -d ' ') items"
else
  warn "  no system skills found"
fi

# ── 4. Credentials & channel pairing state ───────────────────────────────
# Includes: telegram-allowFrom.json, telegram-pairing.json, etc.
# These allow channels to reconnect without re-pairing on the new instance.
info "Backing up credentials & channel state..."
CREDS_DIR="${OPENCLAW_HOME}/credentials"
if [ -d "$CREDS_DIR" ]; then
  mkdir -p "${WORK_DIR}/credentials"
  rsync -a "$CREDS_DIR/" "${WORK_DIR}/credentials/"
  info "  credentials → $(ls ${WORK_DIR}/credentials | tr '\n' ' ')"
fi

# Channel runtime state (e.g. telegram update-offset)
for channel_dir in telegram whatsapp signal discord; do
  CHAN_DIR="${OPENCLAW_HOME}/${channel_dir}"
  if [ -d "$CHAN_DIR" ]; then
    mkdir -p "${WORK_DIR}/channels/${channel_dir}"
    rsync -a "$CHAN_DIR/" "${WORK_DIR}/channels/${channel_dir}/"
    info "  channel state: ${channel_dir}"
  fi
done

# ── 5. Agent config & session history ────────────────────────────────────
# agents/main/agent/ — model provider config (apiKey, baseUrl, models)
# agents/main/sessions/ — full conversation history (.jsonl)
info "Backing up agent config & session history..."
AGENTS_DIR="${OPENCLAW_HOME}/agents"
if [ -d "$AGENTS_DIR" ]; then
  mkdir -p "${WORK_DIR}/agents"
  rsync -a \
    --exclude='*.lock' \
    --exclude='*.deleted.*' \
    "$AGENTS_DIR/" "${WORK_DIR}/agents/"
  SESSIONS_COUNT=$(find "${WORK_DIR}/agents" -name "*.jsonl" | wc -l | tr -d ' ')
  info "  agents → model config + ${SESSIONS_COUNT} sessions"
fi

# ── 6. Devices (paired nodes/phones) ─────────────────────────────────────
info "Backing up devices..."
DEVICES_DIR="${OPENCLAW_HOME}/devices"
if [ -d "$DEVICES_DIR" ]; then
  mkdir -p "${WORK_DIR}/devices"
  rsync -a "$DEVICES_DIR/" "${WORK_DIR}/devices/"
  info "  devices → $(ls ${WORK_DIR}/devices | tr '\n' ' ')"
fi

# ── 7. Identity ───────────────────────────────────────────────────────────
info "Backing up identity..."
IDENTITY_DIR="${OPENCLAW_HOME}/identity"
if [ -d "$IDENTITY_DIR" ]; then
  mkdir -p "${WORK_DIR}/identity"
  rsync -a "$IDENTITY_DIR/" "${WORK_DIR}/identity/"
  info "  identity → $(ls ${WORK_DIR}/identity | tr '\n' ' ')"
fi

# ── 8. Guardian & watchdog scripts ───────────────────────────────────────
info "Backing up scripts..."
mkdir -p "${WORK_DIR}/scripts"
for f in guardian.sh gw-watchdog.sh start-gateway.sh; do
  [ -f "${OPENCLAW_HOME}/${f}" ] && cp "${OPENCLAW_HOME}/${f}" "${WORK_DIR}/scripts/${f}"
done
info "  scripts → $(ls ${WORK_DIR}/scripts | tr '\n' ' ')"

# ── 9. Cron jobs ──────────────────────────────────────────────────────────
info "Backing up cron state..."
CRON_DIR="${OPENCLAW_HOME}/cron"
if [ -d "$CRON_DIR" ]; then
  mkdir -p "${WORK_DIR}/cron"
  rsync -a "$CRON_DIR/" "${WORK_DIR}/cron/"
  info "  cron → $(ls ${WORK_DIR}/cron | wc -l | tr -d ' ') files"
fi

# ── 10. Manifest ─────────────────────────────────────────────────────────
cat > "${WORK_DIR}/MANIFEST.json" <<EOF
{
  "backup_name": "${BACKUP_NAME}",
  "agent_name": "${AGENT_NAME}",
  "timestamp": "${TIMESTAMP}",
  "hostname": "$(hostname)",
  "openclaw_home": "${OPENCLAW_HOME}",
  "openclaw_version": "$(openclaw --version 2>/dev/null | head -1 || echo 'unknown')",
  "created_by": "openclaw-backup skill v1.6",
  "contents": {
    "workspace": true,
    "gateway_config": true,
    "system_skills": true,
    "credentials": true,
    "channel_state": true,
    "agents": true,
    "devices": true,
    "identity": true,
    "guardian_scripts": true,
    "cron_jobs": true
  },
  "notes": "Full backup. All channels reconnect automatically after restore. Contains credentials and API keys — keep secure."
}
EOF

# ── 11. Package ──────────────────────────────────────────────────────────
echo ""
info "Packaging backup..."
ARCHIVE="${OUTPUT_DIR}/${BACKUP_NAME}.tar.gz"
tar -czf "$ARCHIVE" -C "/tmp" "$BACKUP_NAME"
rm -rf "$WORK_DIR"

# Set restrictive permissions on archive (contains secrets)
chmod 600 "$ARCHIVE"

ARCHIVE_SIZE=$(du -sh "$ARCHIVE" | cut -f1)
info "Backup saved: ${ARCHIVE}"
info "Size: ${ARCHIVE_SIZE}"
warn "Archive contains credentials — keep it secure (chmod 600 applied)"

# ── 12. Prune old backups (keep last 7) ──────────────────────────────────
BACKUP_COUNT=$(ls "${OUTPUT_DIR}"/openclaw-backup_*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 7 ]; then
  info "Pruning old backups (keeping last 7)..."
  ls -t "${OUTPUT_DIR}"/openclaw-backup_*.tar.gz | tail -n +8 | xargs rm -f
  info "  Removed $((BACKUP_COUNT - 7)) old backup(s)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Backup complete: ${BACKUP_NAME}.tar.gz"
echo "   To restore: restore.sh ${ARCHIVE}"
echo ""
