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
(async () => {
  const fs = require('fs');
  const path = require('path');

  const skillName = '$SKILL_NAME';
  const skillDir = path.join('/code/.AchillesSkills', skillName);

  if (!fs.existsSync(skillDir)) {
    console.log(JSON.stringify({ content: [{ type: 'text', text: 'Skill not found: ' + skillName }] }));
    return;
  }

  // Check if it's a tskill
  const tskillPath = path.join(skillDir, 'tskill.md');
  if (!fs.existsSync(tskillPath)) {
    console.log(JSON.stringify({
      content: [{ type: 'text', text: 'Code generation is only available for tskill types. No tskill.md found in ' + skillDir }]
    }));
    return;
  }

  try {
    // Try to use the skill-manager generate-code skill
    const { RecursiveSkilledAgent } = await import('achillesAgentLib/RecursiveSkilledAgents');
    const { LLMAgent } = await import('achillesAgentLib/LLMAgents');

    const llmAgent = new LLMAgent({ name: 'code-generator' });
    const agent = new RecursiveSkilledAgent({
      llmAgent,
      startDir: '/code',
      additionalSkillRoots: ['/code/skill-manager-skills'],
    });

    if (agent.pendingPreparations?.length > 0) {
      await Promise.all(agent.pendingPreparations);
    }

    const result = await agent.executePrompt('generate code for ' + skillName, {
      skillName: 'generate-code',
      context: { workingDir: '/code', skillsDir: '/code/.AchillesSkills' }
    });

    console.log(JSON.stringify({
      content: [{ type: 'text', text: typeof result === 'string' ? result : JSON.stringify(result, null, 2) }]
    }));
  } catch (e) {
    console.log(JSON.stringify({
      content: [{ type: 'text', text: 'Error generating code: ' + e.message }]
    }));
  }
})();
" 2>&1
