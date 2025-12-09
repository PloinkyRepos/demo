#!/bin/sh
# Get router URL from environment or default
ROUTER_URL="${PLOINKY_ROUTER_URL:-http://127.0.0.1:8080}"

cat << EOF
{
  "content": [{
    "type": "text",
    "text": "## File Explorer Access\n\n**Workspace Path:** /code\n\n**Skills Directory:** /code/.AchillesSkills\n\n**Explorer MCP Endpoint:** ${ROUTER_URL}/mcps/explorer/mcp\n\n### How to Browse Files\n\nThe explorer agent has been enabled and has access to this workspace. You can:\n\n1. **Use Explorer MCP Tools:**\n   - \`list_directory\` - List files in a directory\n   - \`read_text_file\` - Read file contents\n   - \`write_file\` - Create or update files\n   - \`create_directory\` - Create directories\n   - \`delete_file\` - Delete files\n\n2. **Access the Web Interface:**\n   Visit the ploinky dashboard to access the graphical file explorer.\n\n### Quick Actions\n\n- **View Skills:** Use \`list_directory\` on \`/code/.AchillesSkills\`\n- **Read Skill:** Use \`read_text_file\` on \`/code/.AchillesSkills/<skillName>/tskill.md\`"
  }]
}
EOF
