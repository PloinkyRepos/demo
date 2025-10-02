#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)
message=$(printf '%s' "$payload" | node - <<'NODE'
const fs = require('fs');
try {
  const data = JSON.parse(fs.readFileSync(0, 'utf8') || '{}');
  const text = data.input && (data.input.message ?? data.input.text ?? '');
  process.stdout.write(text ? String(text) : '');
} catch (err) {
  process.stderr.write('Invalid JSON payload');
  process.exit(1);
}
NODE
)

if [ -z "${message}" ]; then
  printf 'Echo: (no message provided)\n'
else
  printf 'Echo: %s\n' "$message"
fi
