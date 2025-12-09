# Show Help

## Summary
Prints in markdown format all skill-manager-cli commands and brief descriptions.

## Prompt
You are the 'show-help' skill for the Skill Manager CLI. When executed, produce a markdown-formatted document that lists all available skill-manager-cli commands. For each command include:
- The command name (as inline code, e.g. `list-skills`)
- A one-sentence description
- An example usage (as inline code)

Include these exact commands and descriptions:

- `list-skills`: Lists all discovered skills in the catalog.
  - Example: `list-skills`
- `read-skill`: Reads a skill definition file.
  - Example: `read-skill greeter`
- `write-skill`: Creates or updates a skill definition file.
  - Example: `write-skill {"skillName":"calculator","fileName":"cskill.md","content":"..."}`
- `update-section`: Updates a specific section in a skill definition file.
  - Example: `update-section {"skillName":"greeter","section":"Prompt","content":"..."}`
- `delete-skill`: Deletes a skill directory and all its contents.
  - Example: `delete-skill old-skill`
- `validate-skill`: Validates a skill file against its schema.
  - Example: `validate-skill greeter`
- `get-template`: Returns a blank template for a skill type.
  - Example: `get-template cskill`
- `preview-changes`: Shows a diff before applying changes to a skill file.
  - Example: `preview-changes greeter`
- `generate-code`: Generates .mjs code from skill definitions (tskill, iskill, oskill, cskill).
  - Example: `generate-code`
- `test-code`: Tests generated code by importing and running it.
  - Example: `test-code`
- `skill-refiner`: Iteratively improves skill definitions until they meet specified requirements.
  - Example: `skill-refiner greeter`
- `execute-skill`: Executes a user skill and returns its output.
  - Example: `execute-skill echo HELLO`
- `read-specs`: Reads a skill's .specs.md specification file.
  - Example: `read-specs equipment`
- `write-specs`: Creates or updates a skill's .specs.md specification file.
  - Example: `write-specs equipment`
- `open-explorer`: Opens the AssistOS File Explorer for browsing workspace files.
  - Example: `open-explorer`

Output only the markdown document. Do not include any surrounding commentary or analysis.

## Arguments
- None

## LLM-Mode
fast