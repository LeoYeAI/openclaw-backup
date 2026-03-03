#!/usr/bin/env bash
# openclaw-backup-schedule: Set up a cron job for periodic automatic backups
#
# ⚠️  PERSISTENCE NOTICE: This script modifies your system crontab (crontab -e).
# It adds one entry to run backup.sh on a schedule. Use --disable to remove it.
#
# Usage: schedule.sh [--interval <daily|weekly|hourly>] [--output-dir <dir>] [--disable]

set -euo pipefail

INTERVAL="daily"
OUTPUT_DIR="/tmp/openclaw-backups"
DISABLE=false
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --interval) INTERVAL="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --disable) DISABLE=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

BACKUP_SCRIPT="${SKILL_DIR}/scripts/backup.sh"

if $DISABLE; then
  # Remove existing cron
  EXISTING=$(crontab -l 2>/dev/null | grep -v "openclaw-backup" || true)
  echo "$EXISTING" | crontab -
  info "Backup cron job disabled"
  exit 0
fi

case $INTERVAL in
  hourly) CRON_EXPR="0 * * * *" ;;
  daily)  CRON_EXPR="0 3 * * *" ;;  # 3 AM daily
  weekly) CRON_EXPR="0 3 * * 0" ;;  # 3 AM Sunday
  *)      echo "Unknown interval: $INTERVAL (use hourly/daily/weekly)"; exit 1 ;;
esac

# Ensure backup script is executable
chmod +x "$BACKUP_SCRIPT"

# Add to crontab — notify user explicitly
EXISTING=$(crontab -l 2>/dev/null | grep -v "openclaw-backup" || true)
NEW_CRON="${CRON_EXPR} ${BACKUP_SCRIPT} ${OUTPUT_DIR} >> /tmp/openclaw-backup.log 2>&1 # openclaw-backup"

warn "This will add the following entry to your crontab:"
echo "    ${NEW_CRON}"
echo ""

{
  echo "$EXISTING"
  echo "$NEW_CRON"
} | crontab -

info "Backup scheduled: ${INTERVAL} (${CRON_EXPR})"
info "Output directory: ${OUTPUT_DIR}"
info "Log: /tmp/openclaw-backup.log"
warn "Note: Using system cron. Alternatively, use 'openclaw-backup schedule-cron' to use OpenClaw's built-in cron."
