#!/bin/bash

# Claude Code Installation Script
# Copies Claude agents and skills to target project

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if target path is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Target project path required${NC}"
    echo "Usage: ./install.sh /path/to/project"
    exit 1
fi

TARGET_PATH="$1"

# Validate target path exists
if [ ! -d "$TARGET_PATH" ]; then
    echo -e "${RED}Error: Target path does not exist: $TARGET_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}Installing Claude Code agents and skills...${NC}"
echo "Target: $TARGET_PATH"

# Create .claude directory if it doesn't exist
CLAUDE_DIR="$TARGET_PATH/.claude"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/skills"

# Copy agents
echo -e "${YELLOW}Copying agents...${NC}"
cp -r .claude/agents/* "$CLAUDE_DIR/agents/"
echo "  ✓ Agents copied to $CLAUDE_DIR/agents/"

# Copy skills
if [ -d "skills" ] && [ "$(ls -A skills 2>/dev/null)" ]; then
    echo -e "${YELLOW}Copying skills...${NC}"
    cp -r skills/* "$CLAUDE_DIR/skills/"
    echo "  ✓ Skills copied to $CLAUDE_DIR/skills/"
else
    echo "  ℹ No skills to copy"
fi

# Copy shared patterns as reference (optional)
echo -e "${YELLOW}Would you like to copy shared patterns? (y/n)${NC}"
read -r COPY_PATTERNS

if [ "$COPY_PATTERNS" = "y" ] || [ "$COPY_PATTERNS" = "Y" ]; then
    PATTERNS_DIR="$TARGET_PATH/.claude/patterns"
    mkdir -p "$PATTERNS_DIR"
    cp -r ../../shared/patterns/* "$PATTERNS_DIR/"
    echo "  ✓ Patterns copied to $PATTERNS_DIR/"
fi

# Create a README in the target .claude directory
cat > "$CLAUDE_DIR/README.md" << 'EOF'
# Claude Code Configuration

This directory contains Claude Code agents and skills for this project.

## Agents

Agents are specialized AI assistants for different roles:
- `business-analyst.md` - Requirements gathering and specification
- `backend-agent.md` - Backend development with Clean Architecture + CQRS

## Skills

Skills are reusable capabilities that can be invoked during development.

## Usage

```bash
# Use a specific agent
claude --agent business-analyst

# List available agents
ls .claude/agents/
```

## Architecture Standards

This project follows:
- Clean Architecture (4 layers)
- CQRS with MediatR
- Test-First Development
- >80% Code Coverage requirement

See patterns directory for templates and examples.
EOF

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_PATH"
echo "  2. claude --agent business-analyst"
echo ""
echo "Available agents:"
ls -1 "$CLAUDE_DIR/agents/" | sed 's/^/  - /'
