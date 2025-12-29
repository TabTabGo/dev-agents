# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a multi-platform AI agent framework for automated SDLC (Software Development Life Cycle). It provides standardized agent configurations, skills, and architecture patterns that work across multiple AI coding platforms (Claude Code, GitHub Copilot, Cursor, Windsurf, Aider).

**Current Status**: Template/blueprint repository in early development. The structure described in README.md is the planned architecture - not all components are implemented yet.

## Repository Structure

```
dev-agents/
├── platforms/
│   ├── claude/          # Claude Code agents and skills
│   │   ├── .claude/agents/   # Agent definitions (.md files)
│   │   └── skills/           # Reusable skill implementations
│   ├── copilot/         # GitHub Copilot configurations
│   ├── shared/          # Platform-agnostic patterns and templates
│   │   ├── patterns/    # Clean Architecture, CQRS, Test-First
│   │   ├── templates/   # .NET and React scaffolds
│   │   └── docs/        # Architecture guides and quality standards
│   └── scripts/         # Cross-platform tooling
```

## Key Commands

### Claude Code Setup
```bash
cd platforms/claude
./install.sh /path/to/project  # When implemented
claude --agent business-analyst
```

### Copilot Setup
```bash
cd platforms/copilot
./setup-copilot.sh  # When implemented
```

## Architecture Standards

This repository enforces universal patterns across all platforms:

### Clean Architecture (4 Layers)
Projects using these patterns should follow strict layer separation:
1. **Domain** - Entities, value objects, domain events
2. **Application** - Use cases, commands/queries (CQRS), interfaces
3. **Infrastructure** - Data access, external services
4. **Presentation** - API controllers, UI components

### CQRS with MediatR
- Commands modify state (no return value or ID only)
- Queries return data (no side effects)
- MediatR handles request/response pipeline
- Templates available in `shared/patterns/cqrs/`

### Test-First Development
- Write tests before implementation
- **Minimum 80% code coverage** required
- Test templates in `shared/patterns/test-first/`

## Working with Agents

### Creating New Claude Agents
Agent definitions live in `platforms/claude/.claude/agents/` as Markdown files. When creating agents:
- Follow the established naming pattern: `{role}-agent.md` (e.g., `backend-agent.md`)
- Include clear responsibilities and constraints
- Reference shared patterns from `platforms/shared/patterns/`
- Ensure agents enforce the >80% coverage requirement

### Creating Skills
Skills are reusable Claude Code capabilities in `platforms/claude/skills/`. Each skill should:
- Be self-contained and focused on a single concern
- Work with the architecture patterns defined in `shared/`
- Include usage documentation

## Technology Stack

Based on planned templates:
- **.NET** (C#) - Primary backend language, uses MediatR for CQRS
- **React** - Frontend framework
- **Cross-platform** - Designed to work with multiple AI tools

## Adding New Patterns

When adding shared patterns to `platforms/shared/patterns/`:
1. Create pattern documentation in `{pattern-name}/structure.md`
2. Provide concrete examples in `{pattern-name}/examples/`
3. Include templates if applicable (e.g., C# class templates)
4. Update this CLAUDE.md if the pattern affects how agents should work

## Platform-Specific Adaptations

When implementing for a new platform (Cursor, Windsurf, Aider):
1. Create platform directory under `platforms/`
2. Adapt shared patterns to platform-specific format
3. Use `scripts/convert-claude-to-copilot.py` as reference for conversion logic
4. Ensure architectural standards remain consistent across platforms

## Important Notes

- **This is a template repository** - many scripts and structures described in README.md are planned but not yet implemented
- Always check if files/scripts exist before referencing them in code or documentation
- Maintain consistency: changes to shared patterns should be reflected in all platform-specific configurations
- Quality bar: >80% code coverage is non-negotiable for any implementation work
