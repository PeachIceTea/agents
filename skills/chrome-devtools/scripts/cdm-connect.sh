#!/usr/bin/env bash
# Connect the chrome-devtools CLI to the running Flatpak Chrome via its
# remote debugging websocket (enabled in chrome://inspect/#remote-debugging).
set -euo pipefail

PROFILE_DIR="${CDM_PROFILE_DIR:-$HOME/.var/app/com.google.Chrome/config/google-chrome}"
PORT_FILE="$PROFILE_DIR/DevToolsActivePort"

if ! command -v chrome-devtools >/dev/null 2>&1; then
  echo "error: chrome-devtools not found. Install with: npm i chrome-devtools-mcp@latest -g" >&2
  exit 1
fi

if [[ ! -f "$PORT_FILE" ]]; then
  echo "error: $PORT_FILE not found." >&2
  echo "Is Flatpak Chrome running with remote debugging enabled (chrome://inspect/#remote-debugging)?" >&2
  exit 1
fi

# Line 1: port, line 2: path (with a leading slash).
port=$(sed -n 1p "$PORT_FILE")
path=$(sed -n 2p "$PORT_FILE")
if [[ -z "${port:-}" || -z "${path:-}" ]]; then
  echo "error: unexpected contents in $PORT_FILE" >&2
  exit 1
fi
# Strip the leading slash: Chrome 144+'s debug server rejects // with a 403.
path="${path#/}"
ws="ws://127.0.0.1:${port}/${path}"

# A running daemon does NOT mean a live connection: the connection to Chrome
# is only established when a command reaches it, and the user has to accept
# it (chrome://inspect/#remote-debugging). So probe with list_pages to tell
# the states apart:
#   - JSON with a "pages" key   -> already connected, leave it alone
#   - "Could not connect"       -> stale endpoint (e.g. Chrome restarted),
#                                  restart the daemon with the new endpoint
#   - still running after 10s   -> connection request pending user acceptance
# Success must be checked positively: list_pages exits 0 even on hard
# failures (e.g. a daemon without a wsEndpoint fails with "Could not find
# Google Chrome executable" — in JSON mode as a JSON error object), so the
# absence of an error string is NOT evidence of a live connection.
if chrome-devtools status 2>/dev/null | grep -q 'daemon is running'; then
  probe_rc=0
  probe_out=$(timeout 10 chrome-devtools list_pages --output-format=json 2>&1) || probe_rc=$?
  if (( probe_rc == 0 )) && grep -q '"pages":\[' <<<"$probe_out"; then
    echo "already connected: $ws"
    echo "verify with: chrome-devtools list_pages"
    exit 0
  elif (( probe_rc == 124 )); then
    echo "connection request is pending; accept it in Chrome (chrome://inspect/#remote-debugging), then verify with: chrome-devtools list_pages"
    exit 0
  else
    # Not positively connected: stale endpoint, daemon started without a
    # wsEndpoint, or some other probe failure. Fall through to restart the
    # daemon with a fresh endpoint.
    echo "existing daemon is not connected; restarting it" >&2
  fi
  chrome-devtools stop >/dev/null 2>&1 || true
fi

chrome-devtools start --wsEndpoint "$ws" --categoryExperimentalWebmcp true 2>&1 \
  | grep -v '^Google collects\|^For more details\|^chrome-devtools-mcp exposes\|^debug\|^Performance\|^Avoid\|^For more' \
  || true

echo "connected: $ws"
echo "a command (e.g. 'chrome-devtools list_pages') establishes the connection;"
echo "accept the prompt in Chrome at chrome://inspect/#remote-debugging"
