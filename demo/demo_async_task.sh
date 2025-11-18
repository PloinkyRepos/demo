#!/bin/sh
set -eu

payload="$(cat || true)"

start_ts="$(date -Iseconds)"
sleep 8
end_ts="$(date -Iseconds)"

node - <<'NODE' "$payload"
process.stdout.write(`Task completed`);
NODE
