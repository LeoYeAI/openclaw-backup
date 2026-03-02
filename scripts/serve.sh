#!/usr/bin/env bash
# openclaw-backup-serve: Start/stop the backup HTTP server
# Usage:
#   serve.sh start  [--port 7373] [--token mytoken] [--backup-dir /tmp/openclaw-backups]
#   serve.sh stop
#   serve.sh status
#   serve.sh url     → print the access URL (with token if set)

set -euo pipefail

ACTION="${1:-start}"
shift || true

PORT="7373"
TOKEN=""
BACKUP_DIR="/tmp/openclaw-backups"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="/tmp/openclaw-backup-server.pid"
LOG_FILE="/tmp/openclaw-backup-server.log"

while [[ $# -gt 0 ]]; do
  case $1 in
    --port)       PORT="$2";       shift 2 ;;
    --token)      TOKEN="$2";      shift 2 ;;
    --backup-dir) BACKUP_DIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

case "$ACTION" in
  start)
    # Token is mandatory — this server exposes credentials and API keys
    if [ -z "$TOKEN" ]; then
      echo ""
      error "❌ --token is required. This server handles sensitive data."$'\n'"   Example: serve.sh start --token \$(openssl rand -hex 16)"
    fi

    # Kill existing
    if [ -f "$PID_FILE" ]; then
      OLD_PID=$(cat "$PID_FILE" 2>/dev/null || echo "")
      [ -n "$OLD_PID" ] && kill "$OLD_PID" 2>/dev/null || true
    fi

    mkdir -p "$BACKUP_DIR"

    # Start server
    BACKUP_PORT="$PORT" BACKUP_TOKEN="$TOKEN" BACKUP_DIR="$BACKUP_DIR" \
      node "${SKILL_DIR}/scripts/server.js" \
        --port "$PORT" --token "$TOKEN" --backup-dir "$BACKUP_DIR" \
      >> "$LOG_FILE" 2>&1 &

    echo $! > "$PID_FILE"
    sleep 1

    # Verify it's running
    if kill -0 $(cat "$PID_FILE") 2>/dev/null; then
      info "Backup server started (pid $(cat $PID_FILE))"
      echo ""
      echo "  🌐 Web UI:  http://localhost:${PORT}/?token=${TOKEN}"
      echo "  📥 Upload:  POST http://localhost:${PORT}/upload?token=${TOKEN}"
      echo "  📤 List:    GET  http://localhost:${PORT}/backups?token=${TOKEN}"
      echo "  📋 Log:     ${LOG_FILE}"
      echo ""
      warn "Share the URL above to download/restore from another machine (requires network access)"
    else
      error "Server failed to start. Check log: $LOG_FILE"
    fi
    ;;

  stop)
    if [ -f "$PID_FILE" ]; then
      PID=$(cat "$PID_FILE")
      kill "$PID" 2>/dev/null && info "Server stopped (pid $PID)" || warn "Server was not running"
      rm -f "$PID_FILE"
    else
      warn "No PID file found — server may not be running"
    fi
    ;;

  status)
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
      info "Server is running (pid $(cat $PID_FILE))"
      echo "  Log: $LOG_FILE"
      tail -5 "$LOG_FILE" 2>/dev/null || true
    else
      warn "Server is NOT running"
    fi
    ;;

  url)
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
      grep "Access URL:" "$LOG_FILE" 2>/dev/null | tail -1 || echo "Server running on port ${PORT}"
    else
      warn "Server is not running"
    fi
    ;;

  *)
    echo "Usage: serve.sh [start|stop|status|url] [--port 7373] [--token TOKEN] [--backup-dir DIR]"
    exit 1
    ;;
esac
