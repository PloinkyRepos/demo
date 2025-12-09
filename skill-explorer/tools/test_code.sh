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

  // Check for generated code
  const generatedPath = path.join(skillDir, 'tskill.generated.mjs');
  if (!fs.existsSync(generatedPath)) {
    console.log(JSON.stringify({
      content: [{ type: 'text', text: 'No generated code found. Run generate_code first.' }]
    }));
    return;
  }

  try {
    // Try to use the skill-manager test-code skill
    const { RecursiveSkilledAgent } = await import('achillesAgentLib/RecursiveSkilledAgents');
    const { LLMAgent } = await import('achillesAgentLib/LLMAgents');

    const llmAgent = new LLMAgent({ name: 'code-tester' });
    const agent = new RecursiveSkilledAgent({
      llmAgent,
      startDir: '/code',
      additionalSkillRoots: ['/code/skill-manager-skills'],
    });

    if (agent.pendingPreparations?.length > 0) {
      await Promise.all(agent.pendingPreparations);
    }

    const result = await agent.executePrompt('test code for ' + skillName, {
      skillName: 'test-code',
      context: { workingDir: '/code', skillsDir: '/code/.AchillesSkills' }
    });

    console.log(JSON.stringify({
      content: [{ type: 'text', text: typeof result === 'string' ? result : JSON.stringify(result, null, 2) }]
    }));
  } catch (e) {
    console.log(JSON.stringify({
      content: [{ type: 'text', text: 'Error testing code: ' + e.message }]
    }));
  }
})();
" 2>&1
