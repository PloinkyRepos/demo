#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)

if [[ -z "$payload" ]]; then
  echo "Expected JSON input on stdin." >&2
  exit 1
fi

PAYLOAD="$payload" node <<'NODE'
const raw = process.env.PAYLOAD;

let payload;
try {
  payload = JSON.parse(raw);
} catch (error) {
  console.error('Invalid JSON input:', error.message);
  process.exit(1);
}

const samples = payload?.input?.samples;
if (!Number.isInteger(samples) || samples <= 0) {
  console.error('`input.samples` must be a positive integer.');
  process.exit(1);
}

let total = 0;
for (let index = 0; index < samples; index += 1) {
  total += Math.random();
}

const probability = total / samples;

console.log(probability);
console.log(`samples used: ${samples}`);
NODE
