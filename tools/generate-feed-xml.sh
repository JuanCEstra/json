#!/usr/bin/env bash
set -euo pipefail

XML_DIR="${1:-webui-xml}"
IN="$XML_DIR/feed-a.xml"

if [[ ! -f "$IN" ]]; then
  echo "Error: missing $IN" >&2
  exit 1
fi

gen() {
  local out="$1"
  local from="$2"
  local to="$3"

  sed -E \
    -e "s/FEED_${from}_TYPE/FEED_${to}_TYPE/g" \
    -e "s/FEED${from}_TYPE/FEED${to}_TYPE/g" \
    -e "s/\bF${from}([A-Z0-9_]+)/F${to}\1/g" \
    -e "s/Feed ${from}/Feed ${to}/g" \
    -e "s/FEED ${from}/FEED ${to}/g" \
    "$IN" > "$out"
}

gen "$XML_DIR/feed-b.xml" "A" "B"
gen "$XML_DIR/feed-c.xml" "A" "C"
gen "$XML_DIR/feed-d.xml" "A" "D"
gen "$XML_DIR/feed-e.xml" "A" "M"
gen "$XML_DIR/feed-f.xml" "A" "N"

echo "Generated:"
ls -1 "$XML_DIR"/feed-{b,c,d,e,f}.xml