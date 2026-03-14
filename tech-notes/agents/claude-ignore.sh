#!/bin/bash

CLAUDEIGNORE=".claudeignore"
GITIGNORE=".gitignore"
SETTINGS_FILE=".claude/settings.json"
ADDED_IGNORE=()
ADDED_DENY=()

mkdir -p .claude

if [ -f "$GITIGNORE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$line" ] && [[ ! "$line" =~ ^#.*$ ]]; then
      if ! grep -Fxq "$line" "$CLAUDEIGNORE" 2>/dev/null; then
        echo "$line" >> "$CLAUDEIGNORE"
        ADDED_IGNORE+=("$line")
      fi
    fi
  done < "$GITIGNORE"
fi

SETTINGS_ENTRY=".claude/settings.json"
if ! grep -Fxq "$SETTINGS_ENTRY" "$CLAUDEIGNORE" 2>/dev/null; then
  echo "$SETTINGS_ENTRY" >> "$CLAUDEIGNORE"
  ADDED_IGNORE+=("$SETTINGS_ENTRY")
fi

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{"writePermissions":{"deny":[]}}' > "$SETTINGS_FILE"
fi

TEMP_FILE=$(mktemp)
if [ -f "$GITIGNORE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$line" ] && [[ ! "$line" =~ ^#.*$ ]]; then
      if ! grep -q "\"$line\"" "$SETTINGS_FILE" 2>/dev/null; then
        ADDED_DENY+=("$line")
      fi
    fi
  done < "$GITIGNORE"
fi

if [ ${#ADDED_DENY[@]} -gt 0 ]; then
  python3 -c "
import json
import sys

with open('$SETTINGS_FILE', 'r') as f:
    data = json.load(f)

if 'writePermissions' not in data:
    data['writePermissions'] = {}
if 'deny' not in data['writePermissions']:
    data['writePermissions']['deny'] = []

deny_list = data['writePermissions']['deny']
new_entries = [$(printf '"%s",' "${ADDED_DENY[@]}" | sed 's/,$//')]
for entry in new_entries:
    if entry not in deny_list:
        deny_list.append(entry)

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
fi

echo "Added entries to .claudeignore:"
for entry in "${ADDED_IGNORE[@]}"; do
  echo "  - $entry"
done

if [ ${#ADDED_IGNORE[@]} -eq 0 ]; then
  echo "  (no new entries added)"
fi

echo ""
echo "Added write permission denies to .claude/settings.json:"
for entry in "${ADDED_DENY[@]}"; do
  echo "  - $entry"
done

if [ ${#ADDED_DENY[@]} -eq 0 ]; then
  echo "  (no new denies added)"
fi
