#!/usr/bin/env bash
# openclaw-restore: Restore OpenClaw from a backup archive
# Usage: restore.sh <backup.tar.gz> [--dry-run]
#
# ⚠️  WARNING: This will overwrite existing files. Run with --dry-run first.

set -euo pipefail

ARCHIVE="${1:-}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

OPENCLAW_HOME="${HOME}/.openclaw"

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }
dryrun(){ echo -e "${CYAN}[DRY]${NC} Would: $*"; }

# ── Validate ─────────────────────────────────────────────────────────────────
[ -z "$ARCHIVE" ] && error "Usage: restore.sh <backup.tar.gz> [--dry-run]"
[ ! -f "$ARCHIVE" ] && error "Archive not found: $ARCHIVE"

echo ""
echo "🦞 OpenClaw Restore"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$DRY_RUN && echo -e "${CYAN}[DRY RUN MODE — no changes will be made]${NC}\n"

# ── Extract to temp ───────────────────────────────────────────────────────────
WORK_DIR="/tmp/openclaw-restore-$$"
mkdir -p "$WORK_DIR"
trap "rm -rf $WORK_DIR" EXIT

info "Extracting archive..."
tar -xzf "$ARCHIVE" -C "$WORK_DIR"

# Find the extracted backup dir (named openclaw-backup_TIMESTAMP)
BACKUP_DIR=$(find "$WORK_DIR" -maxdepth 1 -name "openclaw-backup_*" -type d | head -1)
[ -z "$BACKUP_DIR" ] && error "Invalid archive: no openclaw-backup_* directory found"

# Show manifest
MANIFEST="${BACKUP_DIR}/MANIFEST.json"
if [ -f "$MANIFEST" ]; then
  echo ""
  echo "📋 Manifest:"
  python3 -c "
import json, sys
d = json.load(open('${MANIFEST}'))
print(f\"  Backup name : {d['backup_name']}\")
print(f\"  Created     : {d['timestamp']}\")
print(f\"  From host   : {d['hostname']}\")
print(f\"  OC version  : {d.get('openclaw_version', 'unknown')}\")
has_creds = d.get('contents', {}).get('credentials', False)
print(f\"  Credentials : {'included ✓' if has_creds else 'NOT included (old backup)'}\")
"
  echo ""
fi

# ── Explicit confirmation before destructive restore ─────────────────────────
if ! $DRY_RUN; then
  echo ""
  echo -e "${RED}⚠️  WARNING: This will OVERWRITE ~/.openclaw/ with backup data.${NC}"
  echo "   Backup: $(basename $ARCHIVE)"
  echo "   Target: ${OPENCLAW_HOME}"
  echo ""
  echo -n "   Type 'yes' to confirm: "
  read -r CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
fi

# ── Safety: auto-backup current state before overwriting ─────────────────────
if ! $DRY_RUN; then
  AUTO_BACKUP="/tmp/openclaw-pre-restore-$(date +%Y%m%d_%H%M%S).tar.gz"
  warn "Auto-backing up current state to: $AUTO_BACKUP"
  tar -czf "$AUTO_BACKUP" \
    -C "$(dirname $OPENCLAW_HOME)" \
    --exclude='.openclaw/openclaw.log' \
    --exclude='.openclaw/media' \
    "$(basename $OPENCLAW_HOME)" 2>/dev/null || warn "  Auto-backup had some errors (continuing)"
  chmod 600 "$AUTO_BACKUP"
  info "  Pre-restore backup saved: $AUTO_BACKUP"
fi

# ── Stop gateway before restore ───────────────────────────────────────────────
if ! $DRY_RUN; then
  warn "Stopping OpenClaw Gateway..."
  openclaw gateway stop 2>/dev/null || kill $(pgrep -f "openclaw gateway" | head -1) 2>/dev/null || true
  sleep 2
fi

# ── 1. Workspace ─────────────────────────────────────────────────────────────
if [ -d "${BACKUP_DIR}/workspace" ]; then
  info "Restoring workspace..."
  if $DRY_RUN; then
    dryrun "rsync workspace/ → ${OPENCLAW_HOME}/workspace/"
    find "${BACKUP_DIR}/workspace" -type f | wc -l | xargs -I{} echo "  {} files would be restored"
  else
    mkdir -p "${OPENCLAW_HOME}/workspace"
    rsync -a "${BACKUP_DIR}/workspace/" "${OPENCLAW_HOME}/workspace/"
    info "  workspace restored"
  fi
fi

# ── 2. Gateway config ─────────────────────────────────────────────────────────
if [ -f "${BACKUP_DIR}/config/openclaw.json" ]; then
  info "Restoring Gateway config (incl. bot tokens & API keys)..."
  if $DRY_RUN; then
    dryrun "cp openclaw.json → ${OPENCLAW_HOME}/openclaw.json"
  else
    cp "${BACKUP_DIR}/config/openclaw.json" "${OPENCLAW_HOME}/openclaw.json"
    info "  openclaw.json restored"
  fi
fi

# ── 3. System skills ──────────────────────────────────────────────────────────
if [ -d "${BACKUP_DIR}/skills/system" ] && [ -n "$(ls -A ${BACKUP_DIR}/skills/system 2>/dev/null)" ]; then
  info "Restoring system skills..."
  if $DRY_RUN; then
    dryrun "rsync skills/system/ → ${OPENCLAW_HOME}/skills/"
  else
    mkdir -p "${OPENCLAW_HOME}/skills"
    rsync -a "${BACKUP_DIR}/skills/system/" "${OPENCLAW_HOME}/skills/"
    info "  system skills restored"
  fi
fi

# ── 4. Credentials & channel pairing state ───────────────────────────────────
# Restoring these means no re-pairing needed after migration
if [ -d "${BACKUP_DIR}/credentials" ] && [ -n "$(ls -A ${BACKUP_DIR}/credentials 2>/dev/null)" ]; then
  info "Restoring credentials (channel pairing state)..."
  if $DRY_RUN; then
    dryrun "rsync credentials/ → ${OPENCLAW_HOME}/credentials/"
    ls "${BACKUP_DIR}/credentials/" | xargs -I{} echo "  {}"
  else
    mkdir -p "${OPENCLAW_HOME}/credentials"
    rsync -a "${BACKUP_DIR}/credentials/" "${OPENCLAW_HOME}/credentials/"
    # Ensure restrictive permissions on restored credentials
    chmod 700 "${OPENCLAW_HOME}/credentials"
    chmod 600 "${OPENCLAW_HOME}/credentials/"* 2>/dev/null || true
    info "  credentials restored (permissions hardened)"
  fi
fi

# Channel runtime state (update offsets, session data)
if [ -d "${BACKUP_DIR}/channels" ]; then
  info "Restoring channel state..."
  for channel_dir in "${BACKUP_DIR}/channels/"*/; do
    channel=$(basename "$channel_dir")
    if $DRY_RUN; then
      dryrun "rsync channels/${channel}/ → ${OPENCLAW_HOME}/${channel}/"
    else
      mkdir -p "${OPENCLAW_HOME}/${channel}"
      rsync -a "$channel_dir" "${OPENCLAW_HOME}/${channel}/"
      info "  channel state restored: ${channel}"
    fi
  done
fi

# ── 5. Agent config & session history ────────────────────────────────────────
if [ -d "${BACKUP_DIR}/agents" ]; then
  info "Restoring agent config & session history..."
  if $DRY_RUN; then
    SESSIONS_COUNT=$(find "${BACKUP_DIR}/agents" -name "*.jsonl" | wc -l | tr -d ' ')
    dryrun "rsync agents/ → ${OPENCLAW_HOME}/agents/  (${SESSIONS_COUNT} sessions)"
  else
    mkdir -p "${OPENCLAW_HOME}/agents"
    rsync -a "${BACKUP_DIR}/agents/" "${OPENCLAW_HOME}/agents/"
    info "  agents restored"
  fi
fi

# ── 6. Devices ────────────────────────────────────────────────────────────────
if [ -d "${BACKUP_DIR}/devices" ] && [ -n "$(ls -A ${BACKUP_DIR}/devices 2>/dev/null)" ]; then
  info "Restoring devices..."
  if $DRY_RUN; then
    dryrun "rsync devices/ → ${OPENCLAW_HOME}/devices/"
  else
    mkdir -p "${OPENCLAW_HOME}/devices"
    rsync -a "${BACKUP_DIR}/devices/" "${OPENCLAW_HOME}/devices/"
    info "  devices restored"
  fi
fi

# ── 7. Identity ───────────────────────────────────────────────────────────────
if [ -d "${BACKUP_DIR}/identity" ] && [ -n "$(ls -A ${BACKUP_DIR}/identity 2>/dev/null)" ]; then
  info "Restoring identity..."
  if $DRY_RUN; then
    dryrun "rsync identity/ → ${OPENCLAW_HOME}/identity/"
  else
    mkdir -p "${OPENCLAW_HOME}/identity"
    rsync -a "${BACKUP_DIR}/identity/" "${OPENCLAW_HOME}/identity/"
    info "  identity restored"
  fi
fi

# ── 9. Scripts (guardian, watchdog, start-gateway) ───────────────────────────
if [ -d "${BACKUP_DIR}/scripts" ] && [ -n "$(ls -A ${BACKUP_DIR}/scripts 2>/dev/null)" ]; then
  info "Restoring scripts..."
  if $DRY_RUN; then
    dryrun "copy scripts → ${OPENCLAW_HOME}/"
  else
    for f in "${BACKUP_DIR}/scripts/"*; do
      fname=$(basename "$f")
      cp "$f" "${OPENCLAW_HOME}/${fname}"
      chmod +x "${OPENCLAW_HOME}/${fname}"
    done
    info "  scripts restored ($(ls ${BACKUP_DIR}/scripts | tr '\n' ' '))"
  fi
fi

# ── 10. Cron ──────────────────────────────────────────────────────────────────
if [ -d "${BACKUP_DIR}/cron" ] && [ -n "$(ls -A ${BACKUP_DIR}/cron 2>/dev/null)" ]; then
  info "Restoring cron jobs..."
  if $DRY_RUN; then
    dryrun "rsync cron/ → ${OPENCLAW_HOME}/cron/"
  else
    mkdir -p "${OPENCLAW_HOME}/cron"
    rsync -a "${BACKUP_DIR}/cron/" "${OPENCLAW_HOME}/cron/"
    info "  cron jobs restored"
  fi
fi

# ── Restart gateway ───────────────────────────────────────────────────────────
if ! $DRY_RUN; then
  echo ""
  info "Starting OpenClaw Gateway..."
  if [ -f "${OPENCLAW_HOME}/start-gateway.sh" ]; then
    bash "${OPENCLAW_HOME}/start-gateway.sh" &
    sleep 3
    info "  Gateway started"
  else
    warn "  start-gateway.sh not found — start manually with: openclaw gateway start"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if $DRY_RUN; then
  echo "✅ Dry run complete. Run without --dry-run to apply."
else
  echo "✅ Restore complete!"
  echo ""
  echo "📋 All channels should reconnect automatically."
  echo "   If Telegram is silent after 30s, send /start to your bot."
  echo "   Verify: openclaw gateway status"
fi
echo ""
