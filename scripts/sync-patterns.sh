#!/bin/bash

# Sync shared patterns across all platform configurations
# Ensures all platforms reference the same architecture standards

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SHARED_PATTERNS="$ROOT_DIR/platforms/shared/patterns"

echo -e "${BLUE}Syncing patterns across platforms...${NC}"

# Function to update pattern references in agent files
update_agent_references() {
    local agent_file=$1
    local platform=$2

    echo -e "${YELLOW}Updating references in: $(basename "$agent_file")${NC}"

    # Update pattern paths to point to shared directory
    # This is a simple reference update - customize based on your needs
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|platforms/$platform/patterns|platforms/shared/patterns|g" "$agent_file"
    else
        # Linux
        sed -i "s|platforms/$platform/patterns|platforms/shared/patterns|g" "$agent_file"
    fi
}

# Sync Claude agents
echo -e "${GREEN}Syncing Claude agents...${NC}"
CLAUDE_AGENTS="$ROOT_DIR/platforms/claude/.claude/agents"

if [ -d "$CLAUDE_AGENTS" ]; then
    for agent in "$CLAUDE_AGENTS"/*.md; do
        if [ -f "$agent" ]; then
            update_agent_references "$agent" "claude"
            echo "  ✓ $(basename "$agent")"
        fi
    done
else
    echo "  ℹ No Claude agents found"
fi

# Sync Copilot instructions
echo -e "${GREEN}Syncing Copilot instructions...${NC}"
COPILOT_INSTRUCTIONS="$ROOT_DIR/platforms/copilot/.github/copilot-instructions.md"

if [ -f "$COPILOT_INSTRUCTIONS" ]; then
    update_agent_references "$COPILOT_INSTRUCTIONS" "copilot"
    echo "  ✓ copilot-instructions.md"
else
    echo "  ℹ No Copilot instructions found"
fi

# Verify shared patterns exist
echo -e "${GREEN}Verifying shared patterns...${NC}"
REQUIRED_PATTERNS=("clean-architecture" "cqrs" "test-first")

for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if [ -d "$SHARED_PATTERNS/$pattern" ]; then
        echo "  ✓ $pattern"
    else
        echo -e "  ${YELLOW}⚠ Missing: $pattern${NC}"
    fi
done

# Generate pattern index
echo -e "${GREEN}Generating pattern index...${NC}"
INDEX_FILE="$SHARED_PATTERNS/README.md"

cat > "$INDEX_FILE" << 'EOF'
# Shared Architecture Patterns

This directory contains platform-agnostic architecture patterns and templates used across all AI development platforms.

## Available Patterns

### Clean Architecture
- **Location**: `clean-architecture/`
- **Description**: 4-layer architecture with strict dependency rules
- **Files**: `structure.md`, examples

### CQRS (Command Query Responsibility Segregation)
- **Location**: `cqrs/`
- **Description**: Separate commands (write) from queries (read)
- **Files**: `command-template.cs`, `query-template.cs`

### Test-First Development
- **Location**: `test-first/`
- **Description**: TDD approach with >80% coverage requirement
- **Files**: `unit-test-template.cs`, test templates

## Usage

These patterns are referenced by:
- Claude Code agents in `platforms/claude/.claude/agents/`
- GitHub Copilot in `platforms/copilot/.github/copilot-instructions.md`
- Other AI platforms as they are added

## Updating Patterns

When updating patterns:
1. Modify files in this `shared/patterns/` directory
2. Run `scripts/sync-patterns.sh` to update platform references
3. Test with each platform to ensure compatibility

## Quality Standards

All patterns enforce:
- Clean Architecture layer separation
- CQRS for commands and queries
- Test-First Development (TDD)
- Minimum 80% code coverage
- SOLID principles
EOF

echo "  ✓ Pattern index created"

echo -e "${GREEN}✓ Pattern sync complete!${NC}"
echo ""
echo "Summary:"
echo "  - Claude agents: Updated"
echo "  - Copilot instructions: Updated"
echo "  - Pattern index: Generated"
echo ""
echo "All platforms now reference: platforms/shared/patterns/"
