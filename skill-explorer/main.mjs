#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Directories
const workingDir = process.env.SKILL_EXPLORER_WORKDIR || '/code';
const skillsDir = path.join(workingDir, '.AchillesSkills');
const builtInSkillsDir = path.join(workingDir, 'skill-manager-skills');

// Parse webchat envelope format
function parseWebchatEnvelope(input) {
  try {
    const parsed = JSON.parse(input);
    if (parsed.__webchatMessage) {
      return {
        text: parsed.text || '',
        user: parsed.user || {},
        attachments: parsed.attachments || []
      };
    }
  } catch {
    // Not a JSON envelope, treat as plain text
  }
  return { text: input, user: {}, attachments: [] };
}

// Format result for output
function formatResult(result) {
  if (typeof result === 'string') {
    try {
      const parsed = JSON.parse(result);
      // Check if it's an orchestrator result
      if (parsed && (parsed.executions || parsed.type === 'orchestrator')) {
        // Extract meaningful content
        if (parsed.executions?.length > 0) {
          const lastExecution = parsed.executions[parsed.executions.length - 1];
          if (lastExecution.result) {
            return typeof lastExecution.result === 'string'
              ? lastExecution.result
              : JSON.stringify(lastExecution.result, null, 2);
          }
        }
        return JSON.stringify(parsed, null, 2);
      }
      return JSON.stringify(parsed, null, 2);
    } catch {
      return result;
    }
  }

  if (result && typeof result === 'object') {
    // Handle result with nested result property
    if (result.result) {
      return formatResult(result.result);
    }
    return JSON.stringify(result, null, 2);
  }

  return String(result);
}

async function main() {
  // Ensure skills directory exists
  if (!fs.existsSync(skillsDir)) {
    fs.mkdirSync(skillsDir, { recursive: true });
  }

  // Dynamic imports for ESM modules
  let RecursiveSkilledAgent, LLMAgent;
  try {
    const rsaModule = await import('achillesAgentLib/RecursiveSkilledAgents');
    const llmModule = await import('achillesAgentLib/LLMAgents');
    RecursiveSkilledAgent = rsaModule.RecursiveSkilledAgent;
    LLMAgent = llmModule.LLMAgent;
  } catch (err) {
    console.error('Failed to load achillesAgentLib:', err.message);
    console.error('Make sure dependencies are installed correctly');
    process.exit(1);
  }

  // Initialize LLM Agent
  const llmAgent = new LLMAgent({ name: 'skill-explorer-agent' });

  // Determine additional skill roots
  const additionalSkillRoots = [];
  if (fs.existsSync(builtInSkillsDir)) {
    additionalSkillRoots.push(builtInSkillsDir);
  }

  // Initialize RecursiveSkilledAgent with built-in skills
  const agent = new RecursiveSkilledAgent({
    llmAgent,
    startDir: workingDir,
    additionalSkillRoots,
  });

  // Wait for skill preparations to complete
  if (agent.pendingPreparations && agent.pendingPreparations.length > 0) {
    console.log(`Preparing ${agent.pendingPreparations.length} skill(s)...`);
    await Promise.all(agent.pendingPreparations);
    agent.pendingPreparations.length = 0;
  }

  // Context for skill execution
  const context = {
    workingDir,
    skillsDir,
    skilledAgent: agent,
    llmAgent,
  };

  console.log('skill-explorer ready');
  console.log(`Skills directory: ${skillsDir}`);
  console.log('Type your commands or use natural language to manage skills');
  console.log('');

  // Container mode detection - keep process alive when no TTY
  const isContainerMode = !process.stdin.isTTY;
  if (isContainerMode) {
    process.stdin.resume();
  }

  // REPL loop using readline with event-based handling
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
  });

  // Track if we're processing to prevent premature shutdown
  let isProcessing = false;

  // Inactivity timeout - shutdown if no input for 30 minutes
  const INACTIVITY_TIMEOUT_MS = 30 * 60 * 1000;
  let inactivityTimer = null;

  const resetInactivityTimer = () => {
    if (inactivityTimer) {
      clearTimeout(inactivityTimer);
    }
    inactivityTimer = setTimeout(() => {
      console.log('Inactivity timeout reached, shutting down...');
      process.exit(0);
    }, INACTIVITY_TIMEOUT_MS);
  };

  // Handle readline close - in container mode, stay alive
  rl.on('close', () => {
    if (isContainerMode) {
      // Stay alive for inactivity timeout in container mode
      return;
    }
    setTimeout(() => {
      if (!isProcessing) {
        process.exit(0);
      }
    }, 5000);
  });

  // Handle stdin end - ignore in container mode
  process.stdin.on('end', () => {
    if (isContainerMode) {
      // Ignore stdin end in container mode
      return;
    }
  });

  // Handle stdin errors gracefully
  process.stdin.on('error', () => {});

  // Start inactivity timer
  resetInactivityTimer();

  // Process each line of input using events (not for-await)
  rl.on('line', async (line) => {
    resetInactivityTimer();

    const trimmed = line.trim();
    if (!trimmed) return;

    // Parse webchat envelope if present
    const { text, user } = parseWebchatEnvelope(trimmed);
    if (!text) return;

    // Handle exit commands
    if (text === 'exit' || text === 'quit' || text === '.exit') {
      console.log('Goodbye!');
      rl.close();
      process.exit(0);
    }

    // Handle help command
    if (text === 'help' || text === '/help') {
      console.log(`
skill-explorer - Skill Management CLI

Commands:
  list skills           - List all skills in .AchillesSkills
  read <skill>          - Read a skill definition
  create <type> <name>  - Create a new skill (tskill, cskill, iskill, oskill, mskill)
  validate <skill>      - Validate a skill against its schema
  generate <skill>      - Generate code for a tskill
  test <skill>          - Test generated code
  refine <skill>        - Iteratively improve a skill until tests pass

  help                  - Show this help
  exit                  - Exit the CLI

Skill Types:
  tskill  - Database table (fields, validators, presenters)
  cskill  - Code skill (LLM-generated code)
  iskill  - Interactive (user input collection)
  oskill  - Orchestrator (routes to other skills)
  mskill  - MCP tool integration
`);
      return;
    }

    try {
      isProcessing = true;

      // Execute through skills-orchestrator
      const result = await agent.executePrompt(text, {
        skillName: 'skills-orchestrator',
        context,
        mode: 'deep',
      });

      // Format and output result
      const output = formatResult(result);
      console.log(output);
    } catch (error) {
      console.error(`Error: ${error.message}`);
      if (process.env.DEBUG) {
        console.error(error.stack);
      }
    } finally {
      isProcessing = false;
    }
  });
}

main().catch(err => {
  console.error('Fatal error:', err.message);
  process.exit(1);
});
