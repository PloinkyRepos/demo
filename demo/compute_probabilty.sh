#!/bin/sh
set -eu

payload=$(cat)
json=$(printf '%s' "$payload" | node - <<'NODE'
const fs = require('fs');
const input = fs.readFileSync(0, 'utf8') || '{}';
let samples = 1;
try {
  const data = JSON.parse(input);
  if (data && data.input) {
    const raw = data.input.samples ?? data.input.iterations ?? 1;
    const num = Number(raw);
    if (Number.isFinite(num) && num > 0) {
      samples = Math.min(Math.floor(num), 100000);
    }
  }
} catch (err) {
  process.stderr.write('Invalid JSON payload');
  process.exit(1);
}
let total = 0;
for (let i = 0; i < samples; i += 1) {
  total += Math.random();
}
const average = samples > 0 ? total / samples : Math.random();
process.stdout.write(JSON.stringify({ samples, probability: average }));
NODE
)

samples=$(printf '%s' "$json" | node - <<'NODE'
const fs = require('fs');
const text = fs.readFileSync(0, 'utf8') || '{}';
try {
  const data = JSON.parse(text);
  process.stdout.write(String(data.samples ?? 1));
} catch (err) {
  process.stdout.write('1');
}
NODE
)

value=$(printf '%s' "$json" | node - <<'NODE'
const fs = require('fs');
const text = fs.readFileSync(0, 'utf8') || '{}';
try {
  const data = JSON.parse(text);
  const num = Number(data.probability);
  if (Number.isFinite(num)) {
    process.stdout.write(num.toFixed(4));
  } else {
    process.stdout.write('0.0000');
  }
} catch (err) {
  process.stdout.write('0.0000');
}
NODE
)

printf 'Samples used: %s\nEstimated probability: %s\n' "$samples" "$value"
