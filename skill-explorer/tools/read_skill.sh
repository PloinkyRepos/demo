#!/bin/sh
INPUT=$(cat)
SKILL_NAME=$(echo "$INPUT" | node -e "
const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
console.log(input.input?.skillName || '');
")

if [ -z "$SKILL_NAME" ]; then
  echo '{"content":[{"type":"text","text":"Error: skillName is required"}]}'
  exit 0
fi

SKILL_DIR="/code/.AchillesSkills/$SKILL_NAME"
if [ ! -d "$SKILL_DIR" ]; then
  echo "{\"content\":[{\"type\":\"text\",\"text\":\"Skill not found: $SKILL_NAME\"}]}"
  exit 0
fi

# Find the skill file
SKILL_FILE=$(ls "$SKILL_DIR"/*.md 2>/dev/null | grep -E '(tskill|cskill|iskill|oskill|mskill)\.md$' | head -1)
if [ -z "$SKILL_FILE" ]; then
  echo "{\"content\":[{\"type\":\"text\",\"text\":\"No skill definition file found in $SKILL_DIR\"}]}"
  exit 0
fi

# Read and output the content
node -e "
const fs = require('fs');
const content = fs.readFileSync('$SKILL_FILE', 'utf8');
const filename = '$SKILL_FILE'.split('/').pop();
const output = '## ' + filename + '\\n\\n\`\`\`markdown\\n' + content + '\\n\`\`\`';
console.log(JSON.stringify({ content: [{ type: 'text', text: output }] }));
"
