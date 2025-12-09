# Open Explorer

Opens the AssistOS File Explorer for browsing workspace files.

## Summary
Returns the URL to open the file explorer web interface. Use when user says "open explorer", "file explorer", "browse files".

## Prompt
Return EXACTLY the following markdown (do not summarize or paraphrase):

## File Explorer

**Open Explorer:** [http://127.0.0.1:8080/explorer/index.html](http://127.0.0.1:8080/explorer/index.html)

**Skills Directory:** /code/.AchillesSkills

### Available Tools

| Tool | Description |
| --- | --- |
| `list_directory` | List files in a directory |
| `read_text_file` | Read file contents |
| `write_file` | Create or update files |
| `create_directory` | Create directories |
| `delete_file` | Delete files |

## LLM-Mode
fast
