#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
CLI_WRAPPER="${BIN_DIR}/claude"
CLI_TARGET="${BIN_DIR}/claude.unprotected"
GUI_GUARD="${BIN_DIR}/claude-gui-guard"
LAUNCH_AGENT="${HOME}/Library/LaunchAgents/local.claude.safe-env.plist"
SAFE_APP="${HOME}/Applications/Claude Safe.app"

log() {
  printf '[claude-safe] %s\n' "$*"
}

uninstall_launch_agent() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    return
  fi

  local uid
  uid="$(id -u)"
  /bin/launchctl bootout "gui/${uid}" "$LAUNCH_AGENT" 2>/dev/null || true
  rm -f "$LAUNCH_AGENT"
}

restore_cli() {
  if [[ -f "$CLI_WRAPPER" ]] && grep -q 'CLAUDE_SAFE_WRAPPER=1' "$CLI_WRAPPER"; then
    rm -f "$CLI_WRAPPER"
    if [[ -e "$CLI_TARGET" ]]; then
      mv "$CLI_TARGET" "$CLI_WRAPPER"
      chmod 755 "$CLI_WRAPPER" 2>/dev/null || true
      log "restored original claude command."
    else
      log "removed CLI wrapper; original target was not present."
    fi
  else
    log "CLI wrapper was not installed by this project; leaving claude command unchanged."
  fi
}

uninstall_launch_agent
rm -f "$GUI_GUARD"
rm -rf "$SAFE_APP"
restore_cli
log "done"
