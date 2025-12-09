#!/bin/sh
cd /code
node -e "
const fs = require('fs');
const path = require('path');
const skillsDir = '/code/.AchillesSkills';
const skills = [];

if (fs.existsSync(skillsDir)) {
  fs.readdirSync(skillsDir).forEach(name => {
    const dir = path.join(skillsDir, name);
    if (fs.statSync(dir).isDirectory()) {
      const files = fs.readdirSync(dir);
      const skillFile = files.find(f => f.endsWith('skill.md'));
      const type = skillFile ? skillFile.replace('.md', '') : 'unknown';
      const hasGenerated = files.includes('tskill.generated.mjs');
      skills.push({
        name,
        type,
        path: dir,
        hasGeneratedCode: hasGenerated
      });
    }
  });
}

const output = skills.length > 0
  ? 'Skills in .AchillesSkills:\\n\\n' + skills.map(s =>
      '- **' + s.name + '** (' + s.type + ')' + (s.hasGeneratedCode ? ' [has code]' : '')
    ).join('\\n')
  : 'No skills found in .AchillesSkills directory.\\n\\nUse write_skill to create a new skill.';

console.log(JSON.stringify({
  content: [{ type: 'text', text: output }]
}));
"
