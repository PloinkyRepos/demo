#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)
probability=$(printf '%s' "$payload" | node - <<'NODE'
const fs = require('fs');
try {
  const data = JSON.parse(fs.readFileSync(0, 'utf8') || '{}');
  const raw = data.input && (data.input.samples ?? data.input.iterations ?? 1);
  let samples = Number(raw);
  if (!Number.isFinite(samples) || samples <= 0) {
    samples = 1;
  } else {
    samples = Math.min(Math.floor(samples), 100000);
  }
  let total = 0;
  for (let i = 0; i < samples; i += 1) {
    total += Math.random();
  }
  const average = samples > 0 ? total / samples : Math.random();
  process.stdout.write(JSON.stringify({ samples, probability: average }));
} catch (err) {
  process.stderr.write('Invalid JSON payload');
  process.exit(1);
}
NODE
)

samples=$(printf '%s' "$probability" | node - <<'NODE'
const fs = require('fs');
const text = fs.readFileSync(0, 'utf8') || '{}';
try {
  const data = JSON.parse(text);
  process.stdout.write(String(data.samples ?? '1'));
} catch (err) {
  process.stdout.write('1');
}
NODE
)

value=$(printf '%s' "$probability" | node - <<'NODE'
const fs = require('fs');
const text = fs.readFileSync(0, 'utf8') || '{}';
try {
  const data = JSON.parse(text);
  const num = Number(data.probability);
  if (!Number.isFinite(num)) {
    process.stdout.write('0');
  } else {
    process.stdout.write(num.toFixed(4));
  }
} catch (err) {
  process.stdout.write('0');
}
NODE
)

printf 'Samples used: %s\nEstimated probability: %s\n' "$samples" "$value"
