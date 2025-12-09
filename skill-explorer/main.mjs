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

// Format result for output - extract meaningful content from orchestrator results
function formatResult(result) {
    // Handle string results
    if (typeof result === 'string') {
        try {
            const parsed = JSON.parse(result);
            return formatResult(parsed);
        } catch {
            return result;
        }
    }

    // Handle null/undefined
    if (!result) {
        return 'No result';
    }

    // Handle orchestrator results - extract the actual result from executions
    if (result.type === 'orchestrator' || result.executions) {
        const executions = result.executions || [];

        // Get the last execution's result
        for (let i = executions.length - 1; i >= 0; i--) {
            const exec = executions[i];
            if (exec.outcome?.result) {
                return exec.outcome.result;
            }
            if (exec.result) {
                return typeof exec.result === 'string' ? exec.result : formatResult(exec.result);
            }
        }

        // If no execution result, return notes or a summary
        if (result.notes) {
            return result.notes;
        }

        return 'Operation completed';
    }

    // Handle nested result property
    if (result.result) {
        return formatResult(result.result);
    }

    // Handle outcome property
    if (result.outcome?.result) {
        return result.outcome.result;
    }

    // Handle message property
    if (result.message) {
        return result.message;
    }

    // Handle data property with records
    if (result.data?.records && Array.isArray(result.data.records)) {
        return formatAsTable(result.data.records);
    }

    // Handle arrays
    if (Array.isArray(result)) {
        return formatAsTable(result);
    }

    // Default: stringify objects
    if (typeof result === 'object') {
        return JSON.stringify(result, null, 2);
    }

    return String(result);
}

// Format array of objects as markdown table
function formatAsTable(records) {
    if (!records || records.length === 0) {
        return 'No records found.';
    }

    // Get all unique keys from all records
    const keys = [...new Set(records.flatMap(r => Object.keys(r)))];

    if (keys.length === 0) {
        return 'No data to display.';
    }

    // Build markdown table
    const header = '| ' + keys.join(' | ') + ' |';
    const separator = '| ' + keys.map(() => '---').join(' | ') + ' |';
    const rows = records.map(record => {
        const values = keys.map(key => {
            const val = record[key];
            if (val === null || val === undefined) return '';
            if (typeof val === 'object') return JSON.stringify(val);
            return String(val).replace(/\|/g, '\\|').replace(/\n/g, ' ');
        });
        return '| ' + values.join(' | ') + ' |';
    });

    return [header, separator, ...rows].join('\n');
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
    process.stdin.on('error', () => { });

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
            const helpRows = [
                '## skill-explorer - Skill Management CLI',
                '',
                '| Action | Summary | Try saying |',
                '| --- | --- | --- |',
                '| `list skills` | List all skills in .AchillesSkills | "list skills", "show skills" |',
                '| `read skill` | View a skill definition | "read joker", "show skill greeter" |',
                '| `create skill` | Create a new skill from template | "create tskill inventory" |',
                '| `update skill` | Modify an existing skill | "update joker to tell programming jokes" |',
                '| `delete skill` | Remove a skill | "delete skill test" |',
                '| `validate skill` | Check skill against schema | "validate inventory" |',
                '| `generate code` | Generate .mjs from tskill | "generate code for inventory" |',
                '| `test code` | Test generated code | "test inventory" |',
                '| `refine skill` | Iteratively improve until tests pass | "refine inventory" |',
                '| `execute skill` | Run a skill with input | "execute joker" |',
                '| `read specs` | View skill specifications | "read specs for inventory" |',
                '| `write specs` | Create/update specifications | "write specs for inventory" |',
                '',
                '### Skill Types',
                '',
                '| Type | Description |',
                '| --- | --- |',
                '| `tskill` | Database table (fields, validators, presenters) |',
                '| `cskill` | Code skill (LLM-generated code) |',
                '| `iskill` | Interactive (user input collection) |',
                '| `oskill` | Orchestrator (routes to other skills) |',
                '| `mskill` | MCP tool integration |',
            ];
            console.log(helpRows.join('\n'));
            return;
        }

        try {
            isProcessing = true;

            // Output processing indicator (triggers typing animation in webchat)
            console.log('...');

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
