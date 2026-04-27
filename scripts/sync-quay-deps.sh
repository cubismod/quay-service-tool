#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../backend"

COMMIT=$(grep -oP 'quay\.git@\K[a-f0-9]+' pyproject.toml)
echo "Syncing deps from quay@${COMMIT:0:7}..."

TMPFILE=$(mktemp)
FILTERED=$(mktemp)
trap 'rm -f "$TMPFILE" "$FILTERED"' EXIT

curl -sfL "https://raw.githubusercontent.com/quay/quay/${COMMIT}/requirements.txt" \
  | grep -E '^[a-zA-Z].*==' \
  > "$TMPFILE"

echo "Fetched $(wc -l < "$TMPFILE") upstream deps"

RESOLVED=$(grep '^name = ' uv.lock \
  | sed 's/name = "\(.*\)"/\1/' \
  | tr '[:upper:]' '[:lower:]' \
  | tr '-' '_' \
  | sort -u)

while IFS= read -r line; do
    pkg_name=$(echo "$line" | cut -d'=' -f1 | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    if ! echo "$RESOLVED" | grep -qx "$pkg_name"; then
        echo "$line" >> "$FILTERED"
    fi
done < "$TMPFILE"

MISSING=$(wc -l < "$FILTERED")
if [ "$MISSING" -eq 0 ]; then
    echo "All upstream deps already resolved. Nothing to do."
    exit 0
fi

echo "Adding $MISSING missing deps ($(( $(wc -l < "$TMPFILE") - MISSING )) already resolved)"
cat "$FILTERED"

uv add --group quay-upstream -r "$FILTERED"

echo "Done. Lockfile updated."
