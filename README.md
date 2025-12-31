# AI Dev Workflow

> Automated SDLC with multiple AI platforms

## Supported Platforms

- ✅ **Claude Code** - Sub-agents and Skills
- ✅ **GitHub Copilot** - Agent configurations
- 🚧 **Coming Soon:** Cursor, Windsurf, Aider

## Quick Start

### Using Claude Code

**IMPORTANT**: Claude Code skills are **project-local**, not global plugins. There is no `/plugin install` command. Skills must be physically copied to each project's `.claude/skills/` directory.

#### Method 1: Automated Installation (Recommended)

```bash
# From dev-agents repository
cd platforms/claude
./install.sh /path/to/your/project

# Then open your project in Claude Code
cd /path/to/your/project
claude --agent business-analyst
```

#### Method 2: Use as Template Repository

```bash
# Clone this repo as your project base
git clone https://github.com/TabTabGo/dev-agents.git my-new-project
cd my-new-project

# Skills are already in platforms/claude/.claude/skills/ba-agent/
claude
```

#### Method 3: Manual Copy

```bash
# From your target project directory
mkdir -p .claude/skills/ba-agent

# Copy skills from dev-agents repo
cp -r /path/to/dev-agents/platforms/claude/.claude/skills/ba-agent/* \
      .claude/skills/ba-agent/

# Create docs directory for outputs
mkdir -p docs
```

**How It Works**: Claude Code automatically detects skills in your project's `.claude/skills/` directory. No additional installation or activation needed.

See [INSTALLATION.md](INSTALLATION.md) for detailed setup instructions including Azure DevOps MCP configuration.

### Using Copilot
```bash
cd platforms/copilot
./setup-copilot.sh
# Use @workspace in Copilot Chat
```

## Architecture Patterns (Universal)
- Clean Architecture (4 layers)
- CQRS with MediatR
- Test-First Development
- >80% Code Coverage

## Project Structure

```
dev-agents/
├── platforms/
│   ├── claude/
│   │   ├── .claude/
│   │   │   └── agents/
│   │   │       ├── business-analyst.md
│   │   │       ├── backend-agent.md
│   │   │       └── [other agents...]
│   │   └── skills/
│   │       └── [skill folders...]
│   │
│   ├── copilot/
│   │   ├── .github/
│   │   │   └── copilot-instructions.md
│   │   ├── prompts/
│   │   │   ├── backend-prompt.md
│   │   │   ├── frontend-prompt.md
│   │   │   └── [other prompts...]
│   │   └── README.md
│   │
│   └── shared/
│       ├── patterns/
│       │   ├── clean-architecture/
│       │   │   ├── structure.md
│       │   │   └── examples/
│       │   ├── cqrs/
│       │   │   ├── command-template.cs
│       │   │   └── query-template.cs
│       │   └── test-first/
│       │       └── test-templates/
│       │
│       ├── templates/
│       │   ├── dotnet/
│       │   │   ├── domain/
│       │   │   ├── application/
│       │   │   └── api/
│       │   └── react/
│       │       └── components/
│       │
│       └── docs/
│           ├── architecture-guide.md
│           └── quality-standards.md
│
├── scripts/
│   ├── convert-claude-to-copilot.py  # Helper to adapt prompts
│   └── sync-patterns.sh
│
├── CLAUDE.md     # Guide for Claude Code instances
└── README.md
```

## Claude Code Skills

This repository includes **Business Analyst (BA) agent skills** that provide automated workflow for requirements analysis and user story generation.

### Available BA Skills

1. **requirement-analysis-rfd-generation**
   - Creates Functional Requirements Documents (FRD)
   - Output: `docs/frd-{functionality-name}.md`
   - Trigger: "analyze requirements", "create FRD"

2. **similar-examples-finder**
   - Finds competitor analysis and examples
   - Output: `docs/similar-examples-{functionality-name}.md`
   - Trigger: "find similar examples", "competitor analysis"

3. **requirements-document-generator**
   - Generates Word/PDF documents from FRD
   - Output: `docs/requirements-{functionality-name}.docx/.pdf`
   - Trigger: "generate formal documents"

4. **user-stories-generator-azure-devops-integration**
   - Generates user stories from FRD
   - Creates work items in Azure DevOps (optional)
   - Output: `docs/user-stories-{functionality-name}.md`
   - Trigger: "generate user stories for Sprint X"

### Testing the Skills

After installation, try this prompt:

```text
I want to build a user authentication feature with email/password login.
Please analyze the requirements and create an FRD.
```

Expected: `docs/frd-user-authentication.md` created

See [TESTING.md](TESTING.md) for complete test scenarios.

### Azure DevOps Integration (Optional)

To enable automatic work item creation in Azure DevOps, configure MCP:

1. Create `.claude/mcp.json` in your project:

```json
{
  "mcpServers": {
    "azure-devops": {
      "command": "npx",
      "args": ["-y", "@azure-devops/mcp-server"],
      "env": {
        "ADO_PAT": "${ADO_PAT}",
        "ADO_ORGANIZATION": "${ADO_ORGANIZATION}"
      }
    }
  }
}
```

2. Set environment variables:

```bash
export ADO_PAT="your-personal-access-token"
export ADO_ORGANIZATION="your-org-name"
export ADO_PROJECT_NAME="your-project-name"
```

See [INSTALLATION.md](INSTALLATION.md) for detailed MCP setup.

## Available Agents

### Claude Code

**Business Analyst** - Requirements and specifications

- Located: `platforms/claude/.claude/agents/business-analyst.md`
- Usage: `claude --agent business-analyst`

**Backend Agent** - .NET/C# with Clean Architecture + CQRS

- Located: `platforms/claude/.claude/agents/backend-agent.md`
- Usage: `claude --agent backend-agent`

### GitHub Copilot

Setup creates `.github/copilot-instructions.md` with the same architecture patterns.

- Usage: `@workspace` in Copilot Chat

## Shared Resources

### Patterns (`platforms/shared/patterns/`)

- **Clean Architecture** - 4-layer structure guide
- **CQRS** - Command and Query templates for MediatR
- **Test-First** - TDD templates and examples

### Documentation (`platforms/shared/docs/`)

- **Architecture Guide** - Comprehensive architecture documentation
- **Quality Standards** - Code quality and testing requirements

### Templates (`platforms/shared/templates/`)

- **.NET** - Domain entities, application layer structures
- **React** - Component templates and patterns

## Utility Scripts

### Convert Claude to Copilot

```bash
cd scripts
python convert-claude-to-copilot.py ../platforms/claude/.claude/agents/backend-agent.md
```

### Sync Patterns

```bash
cd scripts
./sync-patterns.sh
```

Ensures all platforms reference the latest shared patterns.

## Contributing

When adding new patterns or agents:

1. Add shared patterns to `platforms/shared/patterns/`
2. Create platform-specific agents in their respective directories
3. Run `scripts/sync-patterns.sh` to update references
4. Update this README and `CLAUDE.md`

## Quality Requirements

All implementations must meet:

- Minimum 80% code coverage
- Follow Clean Architecture layers
- Separate Commands from Queries (CQRS)
- Test-First Development approach
