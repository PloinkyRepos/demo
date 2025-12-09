#!/bin/sh
cat << 'EOF'
{
  "content": [{
    "type": "text",
    "text": "# Skill Types Overview\n\n## tskill (Table Skill)\nDatabase entity with fields, validators, presenters, and resolvers.\n- **Fields:** Define columns with types and constraints\n- **Validators:** Data validation rules per field\n- **Presenters:** Display formatting for field values\n- **Resolvers:** Reference lookups and computed values\n\n### Example tskill.md:\n```markdown\n# Inventory\n\n## Summary\nTrack inventory items with quantity and location.\n\n## Fields\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| item_id | string | yes | Unique identifier |\n| name | string | yes | Item name |\n| quantity | number | yes | Current quantity |\n| location | string | no | Storage location |\n```\n\n## cskill (Code Skill)\nLLM-generated code execution for custom operations.\n- Define inputs and expected outputs\n- LLM generates implementation on demand\n- Supports complex logic and transformations\n\n## iskill (Interactive Skill)\nConversational skill for user input collection.\n- Multi-turn dialogues\n- Slot filling for required information\n- Form-like data collection\n\n## oskill (Orchestrator Skill)\nRoutes requests to other skills based on intent.\n- Intent classification patterns\n- Multi-step task planning\n- Skill composition and chaining\n\n## mskill (MCP Skill)\nIntegration with external MCP tools.\n- Wraps external tool endpoints\n- Parameter mapping\n- Response transformation"
  }]
}
EOF
