#!/bin/sh
# Get router URL from environment or default
ROUTER_URL="${PLOINKY_ROUTER_URL:-http://127.0.0.1:8080}"

# Get the workspace name from PLOINKY_WORKSPACE_NAME or default
WORKSPACE_NAME="${PLOINKY_WORKSPACE_NAME:-testSkillExplorer}"

cat << EOF
{
  "content": [{
    "type": "text",
    "text": "## File Explorer\n\n**Open Explorer:** [${ROUTER_URL}/explorer/index.html](${ROUTER_URL}/explorer/index.html)\n\n**Navigate to:** \`.ploinky/repos/demo/skill-explorer/\` to see skill files\n\n**Skills Directory:** \`.ploinky/repos/demo/skill-explorer/.AchillesSkills/\`\n\n### Available Tools\n\n| Tool | Description |\n| --- | --- |\n| \`list_directory\` | List files in a directory |\n| \`read_text_file\` | Read file contents |\n| \`write_file\` | Create or update files |\n| \`create_directory\` | Create directories |\n| \`delete_file\` | Delete files |"
  }]
}
EOF
