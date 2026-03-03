#!/usr/bin/env bash
# openclaw-restore: Restore OpenClaw from a backup archive
# Usage: restore.sh <backup.tar.gz> [--dry-run] [--overwrite-gateway-token]
#
# ⚠️  WARNING: This will overwrite existing files. Run with --dry-run first.
#
# By default, the gateway auth token from the NEW server is preserved after restore.
# This prevents "gateway token mismatch" errors in Control UI / Dashboard.
# Use --overwrite-gateway-token to override this behavior (e.g. full disaster recovery).

set -euo pipefail

ARCHIVE="${1:-}"
DRY_RUN=false
OVERWRITE_GATEWAY_TOKEN=false

for arg in "${@:2}"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --overwrite-gateway-token) OVERWRITE_GATEWAY_TOKEN=true ;;
  esac
done

OPENCLAW_HOME="${HOME}/.openclaw"

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }
dryrun(){ echo -e "${CYAN}[DRY]${NC} Would: $*"; }

# ── Validate ─────────────────────────────────────────────────────────────────
[ -z "$ARCHIVE" ] && error "Usage: restore.sh <backup.tar.gz> [--dry-run] [--overwrite-gateway-token]"
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
print(f\"  Agent name  : {d.get('agent_name', 'unknown')}\")
print(f\"  Created     : {d['timestamp']}\")
print(f\"  From host   : {d['hostname']}\")
print(f\"  OC version  : {d.get('openclaw_version', 'unknown')}\")
has_creds = d.get('contents', {}).get('credentials', False)
print(f\"  Credentials : {'included ✓' if has_creds else 'NOT included (old backup)'}\")
"
  echo ""
fi

# ── Read current gateway token BEFORE any restore ────────────────────────────
# This token belongs to THIS server — preserve it unless --overwrite-gateway-token
CURRENT_GATEWAY_TOKEN=""
CURRENT_CONFIG="${OPENCLAW_HOME}/openclaw.json"
if [ -f "$CURRENT_CONFIG" ]; then
  CURRENT_GATEWAY_TOKEN=$(python3 -c "
import json, sys
try:
    d = json.load(open('${CURRENT_CONFIG}'))
    print(d.get('gateway', {}).get('auth', {}).get('token', ''))
except Exception:
    print('')
" 2>/dev/null || true)
fi

# Show token preservation strategy
echo "🔑 Gateway Token Strategy:"
if $OVERWRITE_GATEWAY_TOKEN; then
  warn "  --overwrite-gateway-token set: backup token will replace current token"
  warn "  You may need to update Control UI / Dashboard with the restored token"
else
  if [ -n "$CURRENT_GATEWAY_TOKEN" ]; then
    info "  Current server token preserved (prevents Dashboard token mismatch)"
    echo "       Token: ${CURRENT_GATEWAY_TOKEN:0:8}...${CURRENT_GATEWAY_TOKEN: -4}"
  else
    warn "  No current token found — backup token will be used as-is"
  fi
fi
echo ""

# ── Explicit confirmation before destructive restore ─────────────────────────
if ! $DRY_RUN; then
  echo ""
  echo -e "${RED}⚠️  WARNING: This will OVERWRITE ~/.openclaw/ with backup data.${NC}"
  echo "   Backup: $(basename $ARCHIVE)"
  echo "   Target: ${OPENCLAW_HOME}"
  if [ -n "$CURRENT_GATEWAY_TOKEN" ] && ! $OVERWRITE_GATEWAY_TOKEN; then
    echo -e "   ${GREEN}Gateway token: preserved (this server's token kept)${NC}"
  fi
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
  info "Restoring Gateway config (bot tokens, API keys, channels)..."
  if $DRY_RUN; then
    dryrun "cp openclaw.json → ${OPENCLAW_HOME}/openclaw.json"
    if [ -n "$CURRENT_GATEWAY_TOKEN" ] && ! $OVERWRITE_GATEWAY_TOKEN; then
      echo -e "  ${CYAN}[DRY]${NC} gateway.auth.token will be preserved (not overwritten from backup)"
    fi
  else
    cp "${BACKUP_DIR}/config/openclaw.json" "${OPENCLAW_HOME}/openclaw.json"

    # ── KEY FIX: Preserve this server's gateway token ──────────────────────
    # The backup's gateway token belongs to the OLD server.
    # Overwriting it causes "gateway token mismatch" in Control UI / Dashboard.
    # We write back the token we saved before restore began.
    if [ -n "$CURRENT_GATEWAY_TOKEN" ] && ! $OVERWRITE_GATEWAY_TOKEN; then
      python3 -c "
import json, sys
path = '${OPENCLAW_HOME}/openclaw.json'
token = '${CURRENT_GATEWAY_TOKEN}'
d = json.load(open(path))
if 'gateway' not in d:
    d['gateway'] = {}
if 'auth' not in d['gateway']:
    d['gateway']['auth'] = {}
d['gateway']['auth']['token'] = token
json.dump(d, open(path, 'w'), indent=2)
print('  gateway token restored to current server value')
"
      info "  openclaw.json restored (gateway token preserved: ${CURRENT_GATEWAY_TOKEN:0:8}...)"
    else
      info "  openclaw.json restored (gateway token from backup used)"
    fi

    [ -f "${BACKUP_DIR}/config/openclaw.json.bak" ] && \
      cp "${BACKUP_DIR}/config/openclaw.json.bak" "${OPENCLAW_HOME}/openclaw.json.bak"
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
if [ -d "${BACKUP_DIR}/credentials" ] && [ -n "$(ls -A ${BACKUP_DIR}/credentials 2>/dev/null)" ]; then
  info "Restoring credentials (channel pairing state)..."
  if $DRY_RUN; then
    dryrun "rsync credentials/ → ${OPENCLAW_HOME}/credentials/"
    ls "${BACKUP_DIR}/credentials/" | xargs -I{} echo "  {}"
  else
    mkdir -p "${OPENCLAW_HOME}/credentials"
    rsync -a "${BACKUP_DIR}/credentials/" "${OPENCLAW_HOME}/credentials/"
    chmod 700 "${OPENCLAW_HOME}/credentials"
    chmod 600 "${OPENCLAW_HOME}/credentials/"* 2>/dev/null || true
    info "  credentials restored (permissions hardened)"
  fi
fi

# Channel runtime state
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

# ── 8. Scripts (guardian, watchdog, start-gateway) ───────────────────────────
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

# ── 9. Cron ──────────────────────────────────────────────────────────────────
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
  if [ -n "$CURRENT_GATEWAY_TOKEN" ] && ! $OVERWRITE_GATEWAY_TOKEN; then
    echo "🔑 Gateway token: preserved (this server's token kept)"
    echo "   Control UI / Dashboard should connect without any changes."
  else
    echo "🔑 Gateway token: restored from backup"
    echo "   ⚠️  If Control UI shows 'token mismatch', copy this token into Dashboard settings:"
    python3 -c "
import json
d = json.load(open('${OPENCLAW_HOME}/openclaw.json'))
print('   ' + d.get('gateway', {}).get('auth', {}).get('token', '(not found)'))
" 2>/dev/null || true
  fi
  echo ""
  echo "📋 All channels should reconnect automatically."
  echo "   If Telegram is silent after 30s, send /start to your bot."
  echo "   Verify: openclaw gateway status"

  # ── Write restore-complete flag for Agent to detect on next startup ──────
  # Agent reads this file on first heartbeat/startup and sends a restore report
  # to the user, then deletes the file (one-shot).
  RESTORE_FLAG="${OPENCLAW_HOME}/workspace/.restore-complete.json"
  BACKUP_META="${BACKUP_DIR}/MANIFEST.json"
  RESTORED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  AGENT_NAME="unknown"
  BACKUP_NAME_VAL="unknown"
  if [ -f "$BACKUP_META" ]; then
    AGENT_NAME=$(python3 -c "import json; d=json.load(open('${BACKUP_META}')); print(d.get('agent_name','unknown'))" 2>/dev/null || echo "unknown")
    BACKUP_NAME_VAL=$(python3 -c "import json; d=json.load(open('${BACKUP_META}')); print(d.get('backup_name','unknown'))" 2>/dev/null || echo "unknown")
  fi

  python3 -c "
import json
data = {
  'restored_at': '${RESTORED_AT}',
  'backup_name': '${BACKUP_NAME_VAL}',
  'agent_name': '${AGENT_NAME}',
  'pre_restore_snapshot': '${AUTO_BACKUP}',
  'contents': ['workspace','config','credentials','channel_state','agents','devices','identity','scripts','cron']
}
with open('${RESTORE_FLAG}', 'w') as f:
    json.dump(data, f, indent=2)
print('  flag written: .restore-complete.json')
" 2>/dev/null || warn "  Could not write restore flag (non-critical)"

fi
echo ""
