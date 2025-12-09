#!/bin/sh
# Get router URL from environment or default
ROUTER_URL="${PLOINKY_ROUTER_URL:-http://127.0.0.1:8080}"

cat << EOF
{
  "content": [{
    "type": "text",
    "text": "## File Explorer\n\n**Open Explorer:** [${ROUTER_URL}/mcps/explorer/](${ROUTER_URL}/mcps/explorer/)\n\n**Skills Directory:** /code/.AchillesSkills\n\n**MCP Endpoint:** ${ROUTER_URL}/mcps/explorer/mcp\n\n### Available Tools\n\n| Tool | Description |\n| --- | --- |\n| \`list_directory\` | List files in a directory |\n| \`read_text_file\` | Read file contents |\n| \`write_file\` | Create or update files |\n| \`create_directory\` | Create directories |\n| \`delete_file\` | Delete files |"
  }]
}
EOF
