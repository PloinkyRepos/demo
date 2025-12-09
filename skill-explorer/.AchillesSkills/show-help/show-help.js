/**
 * Show Help Skill - Returns help documentation without LLM call
 */

export async function action(input, context = {}) {
    const helpText = `# Skill Manager CLI Commands

## Viewing/Listing

| Command | Description | Example |
| --- | --- | --- |
| \`list-skills\` | Lists all discovered skills in the catalog | \`list skills\` |
| \`read-skill\` | Reads a skill definition file | \`read skill greeter\` |
| \`read-specs\` | Reads a skill's .specs.md specification file | \`read specs equipment\` |

## Creating/Writing

| Command | Description | Example |
| --- | --- | --- |
| \`write-skill\` | Creates or updates a skill definition file | \`create a cskill called calculator\` |
| \`write-specs\` | Creates or updates a skill's .specs.md file | \`write specs equipment\` |
| \`get-template\` | Returns a blank template for a skill type | \`get template tskill\` |

## Updating

| Command | Description | Example |
| --- | --- | --- |
| \`update-section\` | Updates a specific section in a skill file | \`update joker prompt to tell jokes\` |
| \`preview-changes\` | Shows a diff before applying changes | \`preview changes greeter\` |

## Management

| Command | Description | Example |
| --- | --- | --- |
| \`delete-skill\` | Deletes a skill directory and all its contents | \`delete skill old-skill\` |
| \`validate-skill\` | Validates a skill file against its schema | \`validate greeter\` |

## Code Generation

| Command | Description | Example |
| --- | --- | --- |
| \`generate-code\` | Generates .mjs code from tskill definitions | \`generate code for inventory\` |
| \`test-code\` | Tests generated code by importing and running it | \`test inventory\` |
| \`skill-refiner\` | Iteratively improves until requirements are met | \`refine inventory\` |

## Execution

| Command | Description | Example |
| --- | --- | --- |
| \`execute-skill\` | Executes a user skill and returns its output | \`execute echo HELLO\` |

## Tools

| Command | Description | Example |
| --- | --- | --- |
| \`open-explorer\` | Opens the AssistOS File Explorer | \`open explorer\` |
| \`show-help\` | Shows this help documentation | \`help\` |`;

    return {
        success: true,
        message: helpText
    };
}
