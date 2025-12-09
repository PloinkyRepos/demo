#!/bin/sh
INPUT=$(cat)

cd /code
node --experimental-vm-modules -e "
(async () => {
  const fs = require('fs');
  const path = require('path');

  const inputData = JSON.parse(fs.readFileSync(0, 'utf8')).input || {};
  const skillName = inputData.skillName;
  const skillInput = inputData.input || '';

  if (!skillName) {
    console.log(JSON.stringify({ content: [{ type: 'text', text: 'Error: skillName is required' }] }));
    return;
  }

  const skillDir = path.join('/code/.AchillesSkills', skillName);
  if (!fs.existsSync(skillDir)) {
    console.log(JSON.stringify({ content: [{ type: 'text', text: 'Skill not found: ' + skillName }] }));
    return;
  }

  try {
    const { RecursiveSkilledAgent } = await import('achillesAgentLib/RecursiveSkilledAgents');
    const { LLMAgent } = await import('achillesAgentLib/LLMAgents');

    const llmAgent = new LLMAgent({ name: 'skill-executor' });
    const agent = new RecursiveSkilledAgent({
      llmAgent,
      startDir: '/code',
      additionalSkillRoots: ['/code/skill-manager-skills'],
    });

    if (agent.pendingPreparations?.length > 0) {
      await Promise.all(agent.pendingPreparations);
    }

    const result = await agent.executePrompt(skillInput, {
      skillName: skillName,
      context: { workingDir: '/code', skillsDir: '/code/.AchillesSkills' }
    });

    console.log(JSON.stringify({
      content: [{ type: 'text', text: typeof result === 'string' ? result : JSON.stringify(result, null, 2) }]
    }));
  } catch (e) {
    console.log(JSON.stringify({
      content: [{ type: 'text', text: 'Error executing skill: ' + e.message }]
    }));
  }
})();
" <<< "$INPUT" 2>&1
