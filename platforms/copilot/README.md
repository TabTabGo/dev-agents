# GitHub Copilot Platform

This directory contains GitHub Copilot specific configurations and prompts for automated SDLC.

## Setup

```bash
./setup-copilot.sh /path/to/your/project
```

This will create `.github/copilot-instructions.md` in your project.

## How It Works

GitHub Copilot reads instructions from `.github/copilot-instructions.md` and applies them automatically when generating code suggestions.

## Usage

In VS Code with GitHub Copilot:

1. **Workspace Context**:
   ```
   @workspace create a new command for order creation
   ```

2. **Specific Instructions**:
   ```
   @workspace what's the CQRS pattern for this project?
   ```

3. **Code Generation**:
   Copilot will automatically follow the patterns defined in `copilot-instructions.md`

## Customization

Edit `.github/copilot-instructions.md` to:
- Add project-specific patterns
- Define custom templates
- Set code style preferences
- Include domain-specific rules

## Prompts

Store reusable prompt templates in the `prompts/` directory for common tasks:
- Backend feature implementation
- Frontend component creation
- Test generation
- API endpoint creation

## Converting from Claude Agents

Use the conversion script to adapt Claude agents for Copilot:

```bash
cd ../../scripts
python convert-claude-to-copilot.py ../platforms/claude/.claude/agents/backend-agent.md
```

## Architecture Standards

Copilot instructions enforce the same standards as Claude:
- Clean Architecture (4 layers)
- CQRS with MediatR
- Test-First Development
- >80% code coverage

## References

- Shared patterns: `../shared/patterns/`
- Architecture guide: `../shared/docs/architecture-guide.md`
- Quality standards: `../shared/docs/quality-standards.md`
