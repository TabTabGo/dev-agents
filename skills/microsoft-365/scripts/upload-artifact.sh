#!/usr/bin/env bash
#
# upload-artifact.sh — Upload a local file to the right phase folder in a client's
# Teams/SharePoint workspace. Resolves site URL from the client's settings.json.
#
# Usage:
#   ./upload-artifact.sh <client> <phase> <local-file> [--publish] [--comment "msg"]
#
# Examples:
#   ./upload-artifact.sh bolignet 01-requirements ./ba-requirements.md
#   ./upload-artifact.sh visioneers 03-architecture ./adr-001.md --publish --comment "Architect Agent v1"
#
# Exit codes:
#   0  success
#   1  usage error
#   2  settings.json missing or malformed
#   3  m365 not installed or not logged in
#   4  upload failed
#
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <client> <phase> <local-file> [--publish] [--comment "message"]

  client       Client folder name under ~/workspace/ (e.g. bolignet)
  phase        Phase folder name (e.g. 01-requirements, 02-design, ...)
  local-file   Path to the file to upload
  --publish    Publish the file after upload (optional)
  --comment    Comment for publish or version (optional; default: auto-generated)

Valid phases:
  01-requirements, 02-design, 03-architecture, 04-qa-test-cases,
  05-frontend, 06-backend, 07-qa-execution
  (or pass any folder name — will be created if it doesn't exist)
EOF
}

# --- arg parsing ----------------------------------------------------------------
if [[ $# -lt 3 ]]; then
  usage >&2
  exit 1
fi

CLIENT="$1"
PHASE="$2"
LOCAL_FILE="$3"
shift 3

PUBLISH=false
COMMENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --publish) PUBLISH=true; shift ;;
    --comment) COMMENT="${2:-}"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "Error: local file not found: $LOCAL_FILE" >&2
  exit 1
fi

# --- locate settings.json --------------------------------------------------------
# Search order: $WORKSPACE_ROOT/<client>/settings.json, ~/workspace/<client>/settings.json
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$HOME/workspace}"
SETTINGS="$WORKSPACE_ROOT/$CLIENT/settings.json"

if [[ ! -f "$SETTINGS" ]]; then
  echo "Error: settings.json not found at $SETTINGS" >&2
  echo "Hint: set WORKSPACE_ROOT env var if your workspace is elsewhere," >&2
  echo "      or create the file with tenantUrl / siteName / documentLibrary fields." >&2
  exit 2
fi

# --- extract values --------------------------------------------------------------
# Require jq — don't try to parse JSON in bash
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  echo "       Install: apt-get install jq  |  brew install jq" >&2
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
FOLDER="$DOC_LIB/$PHASE"

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

# --- ensure folder exists --------------------------------------------------------
# m365 spo file add doesn't create parent folders; check and create if missing.
# We don't fail if the folder already exists — just swallow that error.
if ! m365 spo folder get \
      --webUrl "$WEB_URL" \
      --folderUrl "$FOLDER" \
      --output json >/dev/null 2>&1; then
  echo "→ Phase folder doesn't exist, creating: $FOLDER"
  m365 spo folder add \
    --webUrl "$WEB_URL" \
    --parentFolderUrl "$DOC_LIB" \
    --name "$PHASE" \
    --output json >/dev/null
fi

# --- build upload command --------------------------------------------------------
COMMENT="${COMMENT:-Uploaded by upload-artifact.sh at $(date -u +%Y-%m-%dT%H:%M:%SZ)}"

UPLOAD_ARGS=(
  spo file add
  --webUrl "$WEB_URL"
  --folder "$FOLDER"
  --path "$LOCAL_FILE"
)

if $PUBLISH; then
  UPLOAD_ARGS+=(--publish --publishComment "$COMMENT")
fi

# --- execute ---------------------------------------------------------------------
echo "→ Uploading $(basename "$LOCAL_FILE") to $WEB_URL/$FOLDER"

if m365 "${UPLOAD_ARGS[@]}" --output json >/tmp/m365-upload-$$.json 2>&1; then
  RESULT=$(cat "/tmp/m365-upload-$$.json")
  rm -f "/tmp/m365-upload-$$.json"
  FILE_URL=$(echo "$RESULT" | jq -r '.ServerRelativeUrl // empty' 2>/dev/null || true)
  if [[ -n "$FILE_URL" ]]; then
    echo "✓ Uploaded: $FILE_URL"
  else
    echo "✓ Upload complete"
  fi
  exit 0
else
  echo "✗ Upload failed:" >&2
  cat "/tmp/m365-upload-$$.json" >&2
  rm -f "/tmp/m365-upload-$$.json"
  exit 4
fi
