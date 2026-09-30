#!/usr/bin/env bash
# sync-mcp.sh — điểm vào duy nhất để đồng bộ MCP config từ mcp-servers.json
# Sử dụng:  ./sync-mcp.sh            (dry-run, xem trước)
#           ./sync-mcp.sh --apply    (backup + ghi + verify)
#           ./sync-mcp.sh --client codex
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$DIR/sync_mcp.py" "$@"
