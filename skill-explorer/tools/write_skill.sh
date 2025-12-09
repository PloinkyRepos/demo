#!/bin/sh
INPUT=$(cat)

# Parse input parameters
node -e "
const fs = require('fs');
const path = require('path');

const input = JSON.parse(fs.readFileSync(0, 'utf8')).input || {};
const skillName = input.skillName;
const skillType = input.skillType || 'cskill';
const content = input.content || '';

if (!skillName) {
  console.log(JSON.stringify({ content: [{ type: 'text', text: 'Error: skillName is required' }] }));
  process.exit(0);
}

// Validate skill type
const validTypes = ['tskill', 'cskill', 'iskill', 'oskill', 'mskill'];
if (!validTypes.includes(skillType)) {
  console.log(JSON.stringify({
    content: [{ type: 'text', text: 'Error: Invalid skill type. Must be one of: ' + validTypes.join(', ') }]
  }));
  process.exit(0);
}

// Create skill directory
const skillDir = path.join('/code/.AchillesSkills', skillName);
fs.mkdirSync(skillDir, { recursive: true });

// Write skill file
const skillFile = path.join(skillDir, skillType + '.md');
fs.writeFileSync(skillFile, content);

console.log(JSON.stringify({
  content: [{ type: 'text', text: 'Skill written successfully to ' + skillFile }]
}));
"
