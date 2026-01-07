#!/bin/bash

# Claude Code Installation Script
# Copies Claude agents and skills to target project or ~/.claude

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "macOS";;
        CYGWIN*|MINGW*|MSYS*) echo "Windows";;
        *)          echo "Unknown";;
    esac
}

OS=$(detect_os)
echo -e "${GREEN}Detected OS: $OS${NC}"

# Check if target path is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}No project path provided.${NC}"
    echo -e "${YELLOW}Install to root Claude folder (~/.claude)? (y/n)${NC}"
    read -r INSTALL_ROOT

    if [ "$INSTALL_ROOT" = "y" ] || [ "$INSTALL_ROOT" = "Y" ]; then
        TARGET_PATH="$HOME/.claude"
        IS_ROOT_INSTALL=true
        echo -e "${GREEN}Installing to: $TARGET_PATH${NC}"
    else
        echo -e "${RED}Installation cancelled.${NC}"
        echo "Usage: ./install.sh [/path/to/project]"
        echo "  - Provide a path to install to a specific project"
        echo "  - Or run without arguments to install to ~/.claude"
        exit 1
    fi
else
    TARGET_PATH="$1"
    IS_ROOT_INSTALL=false

    # Validate target path exists
    if [ ! -d "$TARGET_PATH" ]; then
        echo -e "${RED}Error: Target path does not exist: $TARGET_PATH${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Installing Claude Code agents and skills...${NC}"
echo "Target: $TARGET_PATH"

# Create .claude directory if it doesn't exist
# For root install, TARGET_PATH is already ~/.claude, so don't nest it
if [ "$IS_ROOT_INSTALL" = true ]; then
    CLAUDE_DIR="$TARGET_PATH"
else
    CLAUDE_DIR="$TARGET_PATH/.claude"
fi

mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/skills"

# Copy all .claude contents
echo -e "${YELLOW}Copying .claude contents...${NC}"

# Copy agents
if [ -d ".claude/agents" ]; then
    echo "  → Copying agents..."
    cp -r .claude/agents/* "$CLAUDE_DIR/agents/" 2>/dev/null || true
    agent_count=$(find "$CLAUDE_DIR/agents" -type f -name "*.md" | wc -l)
    echo "    ✓ $agent_count agent(s) installed"
fi

# Copy skills (entire skills directory structure)
if [ -d ".claude/skills" ]; then
    echo "  → Copying skills..."
    # Copy all skills maintaining directory structure
    cp -r .claude/skills/* "$CLAUDE_DIR/skills/" 2>/dev/null || true

    # Count installed skills
    skill_count=$(find "$CLAUDE_DIR/skills" -type f -name "SKILL.md" | wc -l)
    echo "    ✓ $skill_count skill(s) installed"

    # List installed skills with their paths
    echo -e "${GREEN}Installed skills:${NC}"
    find "$CLAUDE_DIR/skills" -type f -name "SKILL.md" | while read -r skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill_name=$(basename "$skill_dir")
        relative_path=$(echo "$skill_file" | sed "s|$CLAUDE_DIR/skills/||" | sed 's|/SKILL.md||')
        echo "    - $relative_path"
    done
fi

# Copy any additional .claude contents (prompts, configs, etc.)
for item in .claude/*; do
    if [ -e "$item" ]; then
        basename_item=$(basename "$item")
        # Skip already copied agents and skills
        if [ "$basename_item" != "agents" ] && [ "$basename_item" != "skills" ]; then
            echo "  → Copying $basename_item..."
            if [ -d "$item" ]; then
                mkdir -p "$CLAUDE_DIR/$basename_item"
                cp -r "$item"/* "$CLAUDE_DIR/$basename_item/" 2>/dev/null || true
            else
                cp "$item" "$CLAUDE_DIR/" 2>/dev/null || true
            fi
            echo "    ✓ $basename_item copied"
        fi
    fi
done

# Create docs directory for skill outputs (only for project installs)
if [ "$IS_ROOT_INSTALL" = false ]; then
    mkdir -p "$TARGET_PATH/docs"
    echo "  ✓ Created docs directory for skill outputs"
fi

# Copy shared patterns as reference (optional)
echo -e "${YELLOW}Would you like to copy shared patterns? (y/n)${NC}"
read -r COPY_PATTERNS

if [ "$COPY_PATTERNS" = "y" ] || [ "$COPY_PATTERNS" = "Y" ]; then
    PATTERNS_DIR="$CLAUDE_DIR/patterns"
    mkdir -p "$PATTERNS_DIR"
    cp -r ../../shared/patterns/* "$PATTERNS_DIR/"
    echo "  ✓ Patterns copied to $PATTERNS_DIR/"
fi

# Create a README in the target .claude directory
cat > "$CLAUDE_DIR/README.md" << EOF
# Claude Code Configuration

This directory contains Claude Code agents, skills, and configurations.

## Installation Summary

Installed on: $(date)

## Agents

Agents are specialized AI assistants for different roles:
$(find "$CLAUDE_DIR/agents" -type f -name "*.md" -exec basename {} .md \; 2>/dev/null | sed 's/^/- /' || echo "- No agents installed")

## Skills

Skills are reusable capabilities that can be invoked during development:
$(find "$CLAUDE_DIR/skills" -type f -name "SKILL.md" 2>/dev/null | while read -r f; do echo "- $(echo "$f" | sed "s|$CLAUDE_DIR/skills/||" | sed 's|/SKILL.md||')"; done || echo "- No skills installed")

## Usage

### Using Agents

\`\`\`bash
# Use a specific agent
claude --agent business-analyst

# List available agents
ls $CLAUDE_DIR/agents/
\`\`\`

### Using Skills

Skills are invoked automatically based on context, or manually:

\`\`\`bash
# Example: Invoke skills manually (if available globally)
/analyze-requirements
/research-examples
/generate-stories
/export-requirements
\`\`\`

## Architecture Standards

This project follows:
- Clean Architecture (4 layers)
- CQRS with MediatR
- Test-First Development
- **>80% Code Coverage requirement**

## Directory Structure

\`\`\`
.claude/
├── agents/          # Specialized AI agent definitions
├── skills/          # Reusable skill implementations
└── README.md        # This file
\`\`\`

## Documentation

- Agent instructions are in \`.md\` files under \`agents/\`
- Skill definitions are in \`SKILL.md\` files under \`skills/\`
- Generated outputs (FRDs, user stories) will be in \`docs/\` directory

## Support

For issues or questions about these agents and skills:
- Repository: https://github.com/tabtabgo/dev-agents
- Documentation: See README.md in the repository root
EOF

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Installation Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$IS_ROOT_INSTALL" = true ]; then
    echo "📁 Installation Location: $TARGET_PATH (Global)"
    echo "✓ These agents and skills are now available globally"
else
    echo "📁 Installation Location: $CLAUDE_DIR"
    echo "✓ Installed for this project only"
fi

echo ""
echo "📋 Installed Agents:"
agent_files=$(find "$CLAUDE_DIR/agents" -type f -name "*.md" 2>/dev/null)
if [ -n "$agent_files" ]; then
    echo "$agent_files" | while read -r f; do
        agent_name=$(basename "$f" .md)
        echo "   ✓ $agent_name"
    done
else
    echo "   - No agents installed"
fi

echo ""
echo "⚡ Installed Skills:"
skill_files=$(find "$CLAUDE_DIR/skills" -type f -name "SKILL.md" 2>/dev/null)
if [ -n "$skill_files" ]; then
    echo "$skill_files" | while read -r f; do
        skill_path=$(echo "$f" | sed "s|$CLAUDE_DIR/skills/||" | sed 's|/SKILL.md||')
        echo "   ✓ $skill_path"
    done
else
    echo "   - No skills installed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$IS_ROOT_INSTALL" = true ]; then
    echo "Navigate to any project directory and run:"
    echo "  $ claude --agent business-analyst"
else
    echo "1. Navigate to your project:"
    echo "   $ cd $TARGET_PATH"
    echo ""
    echo "2. Launch an agent:"
    echo "   $ claude --agent business-analyst"
fi

echo ""
echo "📚 Documentation: See $CLAUDE_DIR/README.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
