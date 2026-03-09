#!/usr/bin/env bash
set -euo pipefail

WEBUI_JSON="${1:-webui.json}"
IDENT_LIST="${2:-tools/feed-identifiers.txt}"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required." >&2
  exit 1
fi

if [[ ! -f "$IDENT_LIST" ]]; then
  echo "Error: missing $IDENT_LIST" >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

jq -Rn '[inputs]' < "$IDENT_LIST" > "$tmp.ident.json"

jq --slurpfile lines "$tmp.ident.json" -f tools/add-feed-pages-from-identifiers.jq "$WEBUI_JSON" > "$tmp"
jq type "$tmp" >/dev/null

mv "$tmp" "$WEBUI_JSON"
echo "Generated Feed A-F pages as scalar widgets + headers in $WEBUI_JSON"