#!/bin/sh
set -eu

# Citește tot payloadul JSON de la stdin
payload=$(cat)

# Rulează un mic script Node.js inline
node - <<'NODE' "$payload"
const raw = process.argv[2] || '{}';
let msg = '';
try {
  const data = JSON.parse(raw);
  if (data.input && typeof data.input === 'object') {
    const firstKey = Object.keys(data.input)[0];
    if (firstKey) msg = String(data.input[firstKey]);
  }
} catch {}
process.stdout.write(`Echo: ${msg}\n`);
NODE
