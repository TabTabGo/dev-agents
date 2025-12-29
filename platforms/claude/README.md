# Claude Code Platform

This directory contains Claude Code specific agents and skills for automated SDLC.

## Installation

```bash
./install.sh /path/to/your/project
```

This will copy agents and skills to your project's `.claude/` directory.

## Available Agents

### Business Analyst
- **File**: `.claude/agents/business-analyst.md`
- **Purpose**: Requirements gathering, user story creation, technical specifications
- **Usage**: `claude --agent business-analyst`

### Backend Agent
- **File**: `.claude/agents/backend-agent.md`
- **Purpose**: .NET/C# development with Clean Architecture and CQRS
- **Usage**: `claude --agent backend-agent`

## Skills

Skills are reusable capabilities that extend Claude Code's functionality. Add custom skills in the `skills/` directory.

## Architecture Standards

All agents enforce:
- **Clean Architecture** - 4-layer separation (Domain, Application, Infrastructure, API)
- **CQRS with MediatR** - Commands modify state, Queries read data
- **Test-First Development** - Write tests before implementation
- **Quality** - >80% code coverage required

## Creating Custom Agents

1. Create a new markdown file in `.claude/agents/`
2. Define the agent's role and responsibilities
3. Include architecture constraints and patterns
4. Reference shared patterns from `platforms/shared/patterns/`

Example structure:
```markdown
# Your Agent Name

You are a [role] AI agent specialized in [domain].

## Your Responsibilities
1. ...
2. ...

## Architecture Constraints
- Follow Clean Architecture
- Use CQRS patterns
...
```

## References

- Shared patterns: `../shared/patterns/`
- Architecture guide: `../shared/docs/architecture-guide.md`
- Quality standards: `../shared/docs/quality-standards.md`
