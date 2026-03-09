#!/usr/bin/env bash
set -euo pipefail

WEBUI_JSON="${1:-webui.json}"
XML_DIR="${2:-webui-xml}"

letters=(a b c d e f)

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required." >&2
  exit 1
fi

for l in "${letters[@]}"; do
  f="$XML_DIR/feed-$l.xml"
  if [[ ! -f "$f" ]]; then
    echo "Error: missing $f" >&2
    exit 1
  fi
done

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

xml_map="$(mktemp)"
trap 'rm -f "$xml_map"' EXIT

{
  echo '{'
  first=1
  for l in "${letters[@]}"; do
    upper="${l^^}"
    f="$XML_DIR/feed-$l.xml"
    val="$(jq -Rs . < "$f")"
    if [[ $first -eq 0 ]]; then
      echo ','
    fi
    first=0
    printf '  "%s": %s' "$upper" "$val"
  done
  echo
  echo '}'
} > "$xml_map"

jq --slurpfile xml "$xml_map" -f tools/add-feed-pages-from-xml-new-layout.jq "$WEBUI_JSON" > "$tmp"
jq type "$tmp" >/dev/null

mv "$tmp" "$WEBUI_JSON"
echo "Added Feed A-F pages with XML widgets to $WEBUI_JSON"