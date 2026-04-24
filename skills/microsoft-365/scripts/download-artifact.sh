#!/usr/bin/env bash
#
# download-artifact.sh — Download a file from a client's phase folder in
# Teams/SharePoint to local disk. Resolves site URL from settings.json.
#
# Usage:
#   ./download-artifact.sh <client> <phase> <filename> [local-dest-dir]
#
# Examples:
#   ./download-artifact.sh bolignet 01-requirements ba-requirements.md
#   ./download-artifact.sh visioneers 03-architecture adr-001.md ./downloads/
#
# Exit codes:
#   0  success
#   1  usage error
#   2  settings.json missing or malformed
#   3  m365 not installed or not logged in
#   4  download failed
#
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <client> <phase> <filename> [local-dest-dir]

  client          Client folder name under ~/workspace/ (e.g. bolignet)
  phase           Phase folder name (e.g. 01-requirements)
  filename        Exact filename to download (e.g. ba-requirements.md)
  local-dest-dir  Directory to save into (default: current directory)
EOF
}

# --- arg parsing ----------------------------------------------------------------
if [[ $# -lt 3 ]]; then
  usage >&2
  exit 1
fi

CLIENT="$1"
PHASE="$2"
FILENAME="$3"
DEST_DIR="${4:-.}"

mkdir -p "$DEST_DIR"
LOCAL_PATH="$DEST_DIR/$FILENAME"

# --- locate settings.json --------------------------------------------------------
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$HOME/workspace}"
SETTINGS="$WORKSPACE_ROOT/$CLIENT/settings.json"

if [[ ! -f "$SETTINGS" ]]; then
  echo "Error: settings.json not found at $SETTINGS" >&2
  echo "Hint: set WORKSPACE_ROOT env var if your workspace is elsewhere." >&2
  exit 2
fi

# --- extract values --------------------------------------------------------------
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  exit 2
fi

TENANT_URL=$(jq -r '.m365.tenantUrl // empty' "$SETTINGS")
SITE_NAME=$(jq -r '.m365.siteName // empty' "$SETTINGS")
DOC_LIB=$(jq -r '.m365.documentLibrary // "Shared Documents"' "$SETTINGS")

if [[ -z "$TENANT_URL" ]]; then
  echo "Error: m365.tenantUrl not set in $SETTINGS" >&2
  exit 2
fi
if [[ -z "$SITE_NAME" ]]; then
  echo "Error: m365.siteName not set in $SETTINGS" >&2
  exit 2
fi

WEB_URL="${TENANT_URL%/}/sites/$SITE_NAME"
SERVER_REL_URL="/sites/$SITE_NAME/$DOC_LIB/$PHASE/$FILENAME"

# --- preflight -------------------------------------------------------------------
if ! command -v m365 >/dev/null 2>&1; then
  echo "Error: m365 CLI not installed." >&2
  echo "       Install: npm install -g @pnp/cli-microsoft365" >&2
  exit 3
fi

STATUS=$(m365 status --output json 2>/dev/null || echo '{"connectedAs":null}')
if ! echo "$STATUS" | jq -e '.connectedAs' >/dev/null 2>&1; then
  echo "Error: not logged in to m365. Run: m365 login" >&2
  exit 3
fi

# --- execute ---------------------------------------------------------------------
echo "→ Downloading $SERVER_REL_URL → $LOCAL_PATH"

if m365 spo file get \
    --webUrl "$WEB_URL" \
    --url "$SERVER_REL_URL" \
    --asFile \
    --path "$LOCAL_PATH" \
    >/tmp/m365-download-$$.log 2>&1; then
  rm -f "/tmp/m365-download-$$.log"
  if [[ -f "$LOCAL_PATH" ]]; then
    SIZE=$(stat -c%s "$LOCAL_PATH" 2>/dev/null || stat -f%z "$LOCAL_PATH" 2>/dev/null || echo "?")
    echo "✓ Downloaded: $LOCAL_PATH ($SIZE bytes)"
    exit 0
  else
    echo "✗ Command succeeded but file not found at $LOCAL_PATH" >&2
    exit 4
  fi
else
  echo "✗ Download failed:" >&2
  cat "/tmp/m365-download-$$.log" >&2
  rm -f "/tmp/m365-download-$$.log"
  echo "" >&2
  echo "Common causes:" >&2
  echo "  - File doesn't exist at that path (check with: m365 spo file list --webUrl \"$WEB_URL\" --folderUrl \"$DOC_LIB/$PHASE\")" >&2
  echo "  - Site name in settings.json doesn't match the actual SharePoint site" >&2
  echo "  - Not logged in to the right tenant (m365 connection list)" >&2
  exit 4
fi
