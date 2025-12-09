# Skill Explorer Deployment Scripts

Quick deployment scripts for setting up skill-explorer in a ploinky workspace.

## Quick Start

```bash
# 1. Set your API key
export ANTHROPIC_API_KEY="sk-ant-your-key"

# 2. Deploy
./deploy-dev.sh
```

## Scripts

### deploy-dev.sh

Main deployment script that:
- Sets ploinky environment variables
- Enables the skill-explorer agent
- Starts the agent on specified port

```bash
# Basic usage
./deploy-dev.sh

# Custom port
./deploy-dev.sh --port 9000

# With file explorer
./deploy-dev.sh --with-explorer

# Skip variable setup (if already configured)
./deploy-dev.sh --skip-vars
```

### setEnv.sh

Sets ploinky variables from environment. Source this before manual deployment:

```bash
source ./setEnv.sh
```

### env.example

Template for environment configuration:

```bash
cp env.example .env
# Edit .env with your API keys
source .env
./deploy-dev.sh
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `ANTHROPIC_API_KEY` | Anthropic Claude API key | Yes (or another LLM key) |
| `OPENAI_API_KEY` | OpenAI API key | Optional |
| `GEMINI_API_KEY` | Google Gemini API key | Optional |
| `ROUTER_PORT` | Ploinky router port (default: 8080) | No |

## After Deployment

Access skill-explorer at:
- **Webchat**: http://127.0.0.1:8080/webchat
- **Dashboard**: http://127.0.0.1:8080/dashboard
- **CLI**: `ploinky cli skill-explorer`

## Troubleshooting

### Agent not starting

```bash
# Check status
ploinky status

# View logs
ploinky logs skill-explorer

# Restart
ploinky stop skill-explorer
ploinky start skill-explorer
```

### API key issues

```bash
# Verify key is set
ploinky var ANTHROPIC_API_KEY

# Set key manually
ploinky var ANTHROPIC_API_KEY "sk-ant-your-key"
```
