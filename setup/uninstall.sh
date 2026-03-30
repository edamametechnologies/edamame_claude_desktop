#!/usr/bin/env bash
set -euo pipefail

SLUG="claude-desktop-edamame"
MCP_KEY="edamame"

OS_KERNEL="$(uname -s)"
case "$OS_KERNEL" in
  Darwin)
    CONFIG_HOME="$HOME/Library/Application Support/$SLUG"
    STATE_HOME="$CONFIG_HOME/state"
    DATA_HOME="$HOME/Library/Application Support/$SLUG"
    DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    ;;
  *)
    CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/$SLUG"
    STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/$SLUG"
    DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/$SLUG"
    DESKTOP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/Claude/claude_desktop_config.json"
    ;;
esac

remove_mcp_entry() {
  local config_path="$1"
  [[ -f "$config_path" ]] || return 0
  python3 - "$config_path" "$MCP_KEY" <<'PY'
import json
import shutil
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
key = sys.argv[2]
try:
    raw = config_path.read_text(encoding="utf-8")
    root = json.loads(raw)
except Exception:
    sys.exit(0)

servers = root.get("mcpServers")
if not isinstance(servers, dict) or key not in servers:
    sys.exit(0)

shutil.copy2(config_path, Path(str(config_path) + ".bak"))
servers.pop(key, None)
config_path.write_text(json.dumps(root, indent=2) + "\n", encoding="utf-8")
PY
}

remove_mcp_entry "$HOME/.claude.json"
remove_mcp_entry "$DESKTOP_CONFIG"

rm -rf "$DATA_HOME"
if [[ "$CONFIG_HOME" != "$DATA_HOME" ]]; then
  rm -rf "$CONFIG_HOME"
fi
if [[ "$STATE_HOME" != "$DATA_HOME" && "$STATE_HOME" != "$CONFIG_HOME" ]]; then
  rm -rf "$STATE_HOME"
fi

echo "Uninstalled EDAMAME for Claude Desktop from:"
echo "  $DATA_HOME"
