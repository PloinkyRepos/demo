#!/bin/sh
set -eu

# This script reads a JSON payload from stdin, extracts the value of the first
# parameter from the 'input' object, and prints it to stdout, adding a newline.

payload=$(cat)

printf '%s' "$payload" | node - <<'NODE'
const fs = require('fs');
const input = fs.readFileSync(0, 'utf8') || '{}';
let msg = '';
try {
    const data = JSON.parse(input);
    if (data && data.input && typeof data.input === 'object') {
        const keys = Object.keys(data.input);
        if (keys.length > 0) {
            const firstKey = keys[0];
            const value = data.input[firstKey];
            if (value !== null && value !== undefined) {
                msg = String(value);
            }
        }
    }
} catch (err) {
    // Exit silently on error, producing no output.
}
process.stdout.write(msg + '\n');
NODE