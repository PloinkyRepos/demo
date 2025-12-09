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

cd /code
node --experimental-vm-modules -e "
const fs = require('fs');
const path = require('path');

const skillName = '$SKILL_NAME';
const skillDir = path.join('/code/.AchillesSkills', skillName);

if (!fs.existsSync(skillDir)) {
  console.log(JSON.stringify({ content: [{ type: 'text', text: 'Skill not found: ' + skillName }] }));
  process.exit(0);
}

// Find skill file
const files = fs.readdirSync(skillDir);
const skillFile = files.find(f => f.match(/^(t|c|i|o|m)skill\.md$/));

if (!skillFile) {
  console.log(JSON.stringify({ content: [{ type: 'text', text: 'No skill definition file found in ' + skillDir }] }));
  process.exit(0);
}

const skillType = skillFile.replace('.md', '');
const content = fs.readFileSync(path.join(skillDir, skillFile), 'utf8');

// Basic validation - check for required sections based on type
const errors = [];

// Common checks
if (!content.includes('# ')) {
  errors.push('Missing title (# heading)');
}

// Type-specific checks
if (skillType === 'tskill') {
  if (!content.includes('## Fields')) {
    errors.push('tskill requires ## Fields section');
  }
} else if (skillType === 'cskill') {
  if (!content.includes('## Implementation') && !content.includes('## Code')) {
    errors.push('cskill requires ## Implementation or ## Code section');
  }
} else if (skillType === 'oskill') {
  if (!content.includes('## Skills') && !content.includes('## Routes')) {
    errors.push('oskill requires ## Skills or ## Routes section');
  }
}

if (errors.length > 0) {
  console.log(JSON.stringify({
    content: [{ type: 'text', text: '## Validation Failed\\n\\n' + errors.map(e => '- ' + e).join('\\n') }]
  }));
} else {
  console.log(JSON.stringify({
    content: [{ type: 'text', text: '## Validation Passed\\n\\nSkill **' + skillName + '** (' + skillType + ') is valid.' }]
  }));
}
"
