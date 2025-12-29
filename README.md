# AI Dev Workflow

> Automated SDLC with multiple AI platforms

## Supported Platforms

- ✅ **Claude Code** - Sub-agents and Skills
- ✅ **GitHub Copilot** - Agent configurations
- 🚧 **Coming Soon:** Cursor, Windsurf, Aider

## Quick Start

### Using Claude
```bash
cd platforms/claude
./install.sh /path/to/project
claude --agent business-analyst
```

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
