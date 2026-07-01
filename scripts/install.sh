#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
CLI_WRAPPER="${BIN_DIR}/claude"
CLI_TARGET="${BIN_DIR}/claude.unprotected"
GUI_GUARD="${BIN_DIR}/claude-gui-guard"
LAUNCH_AGENT_DIR="${HOME}/Library/LaunchAgents"
LAUNCH_AGENT="${LAUNCH_AGENT_DIR}/local.claude.safe-env.plist"
LOG_DIR="${HOME}/Library/Logs"
SAFE_APP="${HOME}/Applications/Claude Safe.app"
CLAUDE_APP="/Applications/Claude.app"

log() {
  printf '[claude-safe] %s\n' "$*"
}

install_cli_wrapper() {
  local current_claude

  mkdir -p "$BIN_DIR"
  current_claude="$(command -v claude || true)"

  if [[ -z "$current_claude" && ! -e "$CLI_TARGET" ]]; then
    log "claude was not found in PATH; skipping CLI wrapper."
    return
  fi

  if [[ ! -e "$CLI_TARGET" ]]; then
    if [[ "$current_claude" == "$CLI_WRAPPER" ]]; then
      mv "$CLI_WRAPPER" "$CLI_TARGET"
    else
      ln -s "$current_claude" "$CLI_TARGET"
    fi
  fi

  cat >"$CLI_WRAPPER" <<'WRAPPER'
#!/usr/bin/env bash
# CLAUDE_SAFE_WRAPPER=1
set -euo pipefail

blocked_vars=(
  ANTHROPIC_BASE_URL
  ANTHROPIC_AUTH_TOKEN
  ANTHROPIC_API_KEY
)

for var in "${blocked_vars[@]}"; do
  if [[ -n "${!var:-}" ]]; then
    printf '[claude-safe] blocked: %s is set. Clear it before launching Claude Code.\n' "$var" >&2
    exit 64
  fi
done

export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="${CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:-1}"
export DO_NOT_TRACK="${DO_NOT_TRACK:-1}"
export DISABLE_TELEMETRY="${DISABLE_TELEMETRY:-1}"
export DISABLE_ERROR_REPORTING="${DISABLE_ERROR_REPORTING:-1}"
export DISABLE_AUTOUPDATER="${DISABLE_AUTOUPDATER:-1}"

unset OPENROUTER_API_KEY
unset OPENAI_API_KEY

target="${CLAUDE_UNPROTECTED:-${HOME}/.local/bin/claude.unprotected}"
if [[ ! -x "$target" ]]; then
  printf '[claude-safe] original claude executable was not found: %s\n' "$target" >&2
  exit 66
fi

exec "$target" "$@"
WRAPPER
  chmod 755 "$CLI_WRAPPER"

  case ":${PATH}:" in
    *":${BIN_DIR}:"*) ;;
    *) log "Add ${BIN_DIR} to PATH before other claude locations to use the CLI wrapper." ;;
  esac

  log "CLI wrapper installed at ${CLI_WRAPPER}"
}

install_gui_guard() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log "non-macOS system detected; skipping desktop guard."
    return
  fi

  mkdir -p "$BIN_DIR" "$LAUNCH_AGENT_DIR" "$LOG_DIR" "${SAFE_APP}/Contents/MacOS" "${SAFE_APP}/Contents/Resources"

  cat >"$GUI_GUARD" <<'GUARD'
#!/usr/bin/env bash
set -euo pipefail

CLAUDE_APP="/Applications/Claude.app"
LOG_PREFIX="[claude-gui-guard]"

dangerous_vars=(
  ANTHROPIC_BASE_URL
  ANTHROPIC_AUTH_TOKEN
  ANTHROPIC_API_KEY
)

sensitive_provider_vars=(
  OPENROUTER_API_KEY
  OPENAI_API_KEY
)

privacy_flags=(
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
  DO_NOT_TRACK=1
  DISABLE_TELEMETRY=1
  DISABLE_ERROR_REPORTING=1
  DISABLE_AUTOUPDATER=1
)

launchd_getenv() {
  /bin/launchctl getenv "$1" 2>/dev/null || true
}

clear_gui_env() {
  local var

  for var in "${dangerous_vars[@]}" "${sensitive_provider_vars[@]}"; do
    /bin/launchctl unsetenv "$var" 2>/dev/null || true
  done
}

set_privacy_flags() {
  local pair var value

  for pair in "${privacy_flags[@]}"; do
    var="${pair%%=*}"
    value="${pair#*=}"
    /bin/launchctl setenv "$var" "$value"
  done
}

verify_no_dangerous_gui_env() {
  local var value
  local found=0

  for var in "${dangerous_vars[@]}"; do
    value="$(launchd_getenv "$var")"
    if [[ -n "$value" ]]; then
      printf '%s %s is still set in the macOS GUI environment.\n' "$LOG_PREFIX" "$var" >&2
      found=1
    fi
  done

  return "$found"
}

show_blocked_dialog() {
  /usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
display dialog "Claude Safe blocked startup because Anthropic API/base URL variables are still present in the macOS GUI environment. Restart macOS, then open Claude Safe again." buttons {"OK"} default button "OK" with title "Claude Safe"
APPLESCRIPT
}

show_missing_app_dialog() {
  /usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
display dialog "Claude.app was not found in /Applications." buttons {"OK"} default button "OK" with title "Claude Safe"
APPLESCRIPT
}

apply_env() {
  clear_gui_env
  set_privacy_flags
  verify_no_dangerous_gui_env
  printf '%s GUI environment is clean for Claude desktop startup.\n' "$LOG_PREFIX"
}

check_env() {
  verify_no_dangerous_gui_env
  printf '%s no Anthropic API/base URL variables are present in the macOS GUI environment.\n' "$LOG_PREFIX"
}

launch_desktop() {
  if ! verify_no_dangerous_gui_env; then
    show_blocked_dialog
    exit 64
  fi

  clear_gui_env
  set_privacy_flags

  if ! verify_no_dangerous_gui_env; then
    show_blocked_dialog
    exit 64
  fi

  if [[ ! -d "$CLAUDE_APP" ]]; then
    printf '%s %s was not found.\n' "$LOG_PREFIX" "$CLAUDE_APP" >&2
    show_missing_app_dialog
    exit 66
  fi

  /usr/bin/open "$CLAUDE_APP"
}

case "${1:-apply-env}" in
  apply-env)
    apply_env
    ;;
  check)
    check_env
    ;;
  launch-desktop)
    launch_desktop
    ;;
  *)
    printf 'Usage: %s [apply-env|check|launch-desktop]\n' "$0" >&2
    exit 64
    ;;
esac
GUARD
  chmod 755 "$GUI_GUARD"

  cat >"$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>local.claude.safe-env</string>

  <key>ProgramArguments</key>
  <array>
    <string>${GUI_GUARD}</string>
    <string>apply-env</string>
  </array>

  <key>RunAtLoad</key>
  <true/>

  <key>StandardOutPath</key>
  <string>${LOG_DIR}/claude-safe-env.log</string>

  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/claude-safe-env.log</string>
</dict>
</plist>
PLIST

  cat >"${SAFE_APP}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>

  <key>CFBundleExecutable</key>
  <string>Claude Safe</string>

  <key>CFBundleIdentifier</key>
  <string>local.claude.safe.launcher</string>

  <key>CFBundleIconFile</key>
  <string>electron.icns</string>

  <key>CFBundleName</key>
  <string>Claude Safe</string>

  <key>CFBundlePackageType</key>
  <string>APPL</string>

  <key>CFBundleShortVersionString</key>
  <string>1.0</string>

  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
PLIST

  cat >"${SAFE_APP}/Contents/MacOS/Claude Safe" <<'APP'
#!/usr/bin/env bash
set -euo pipefail

exec "${HOME}/.local/bin/claude-gui-guard" launch-desktop
APP
  chmod 755 "${SAFE_APP}/Contents/MacOS/Claude Safe"

  if [[ -f "${CLAUDE_APP}/Contents/Resources/electron.icns" ]]; then
    cp "${CLAUDE_APP}/Contents/Resources/electron.icns" "${SAFE_APP}/Contents/Resources/electron.icns"
  fi

  plutil -lint "$LAUNCH_AGENT" "${SAFE_APP}/Contents/Info.plist" >/dev/null

  local uid
  uid="$(id -u)"
  /bin/launchctl bootout "gui/${uid}" "$LAUNCH_AGENT" 2>/dev/null || true
  /bin/launchctl bootstrap "gui/${uid}" "$LAUNCH_AGENT"
  /bin/launchctl kickstart -k "gui/${uid}/local.claude.safe-env"

  if [[ -x /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister ]]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$SAFE_APP" || true
  fi
  touch "$SAFE_APP"

  log "desktop guard installed at ${SAFE_APP}"
}

install_cli_wrapper
install_gui_guard
log "done"
