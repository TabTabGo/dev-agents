# Installing BA Agent Skills in Claude Code

This guide explains how to install and use the BA agent skills as a plugin in Claude Code.

## Installation Methods

### Method 1: Install into Existing Project (Recommended)

Use the installation script to copy skills to your project:

```bash
# From the dev-agents repository root
cd platforms/claude
./install.sh /path/to/your/project

# Example:
./install.sh ~/projects/my-web-app
```

This will:
- ✅ Copy BA agent skills to `your-project/.claude/skills/ba-agent/`
- ✅ Create `.claude/agents/` directory with agent definitions
- ✅ Create `docs/` directory for outputs
- ✅ Optionally copy shared patterns

### Method 2: Use as Template Repository

Clone this repository as a template for new projects:

```bash
# Clone the repository
git clone https://github.com/TabTabGo/dev-agents.git my-new-project

# Navigate to your project
cd my-new-project

# The skills are already in platforms/claude/.claude/skills/ba-agent/
# You can start using them immediately in Claude Code
```

### Method 3: Manual Installation

Copy the skills directory manually:

```bash
# From your target project directory
mkdir -p .claude/skills/ba-agent

# Copy skills from dev-agents repo
cp -r /path/to/dev-agents/platforms/claude/.claude/skills/ba-agent/* \
      .claude/skills/ba-agent/

# Create docs directory
mkdir -p docs
```

## Verify Installation

After installation, verify the skills are in place:

```bash
# Check skills directory
ls .claude/skills/ba-agent/

# Expected output:
# requirement-analysis-rfd-generation/
# requirements-document-generator/
# similar-examples-finder/
# user-stories-generator-azure-devops-integration/

# Check each skill has SKILL.md
find .claude/skills/ba-agent -name "SKILL.md"
```

## Configuration

### 1. Basic Setup (No Azure DevOps)

For basic usage without Azure DevOps integration:

```bash
# No additional configuration needed!
# Just ensure docs directory exists
mkdir -p docs
```

### 2. Azure DevOps Integration Setup

For the `user-stories-generator-azure-devops-integration` skill:

**Step A: Create MCP Configuration**

Create `.claude/mcp.json` in your project root:

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

**Step B: Set Environment Variables**

```bash
# Create .env file (don't commit this!)
cat > .env << EOF
ADO_PAT=your-personal-access-token
ADO_ORGANIZATION=your-org-name
ADO_PROJECT_NAME=your-project-name
EOF

# Or export directly
export ADO_PAT="your-personal-access-token"
export ADO_ORGANIZATION="your-org-name"
export ADO_PROJECT_NAME="your-project-name"
```

**Step C: Get Azure DevOps PAT Token**

1. Go to: https://dev.azure.com/{your-org}/_usersSettings/tokens
2. Click "New Token"
3. Give it a name: "Claude Code MCP"
4. Set expiration
5. Select scopes: **Work Items (Read, Write, Manage)**
6. Click "Create"
7. Copy the token (you won't see it again!)

**Step D: Alternative - Use package.json**

```json
{
  "name": "my-project",
  "azureDevOps": {
    "project": "MyProjectName"
  }
}
```

## Usage

### Starting Claude Code with BA Skills

Once installed, Claude Code will automatically detect the skills:

```bash
# Start Claude Code in your project
cd /path/to/your/project
claude

# Or use specific agent
claude --agent business-analyst
```

### Testing the Skills

**Test 1: Generate FRD**

Prompt Claude:
```text
I want to build a user authentication feature with email/password login.
Please analyze the requirements and create an FRD.
```

Expected: `docs/frd-user-authentication.md` created

**Test 2: Find Similar Examples**

Prompt Claude:
```text
Find similar examples and competitor analysis for authentication systems.
```

Expected: `docs/similar-examples-user-authentication.md` created

**Test 3: Generate User Stories**

Prompt Claude:
```text
Generate user stories from the authentication FRD for Sprint 1
```

Expected: `docs/user-stories-user-authentication.md` created
(And work items in Azure DevOps if MCP configured)

## Skill Reference

### Available Skills

1. **requirement-analysis-rfd-generation**
   - Creates Functional Requirements Documents (FRD)
   - Output: `docs/frd-{functionality-name}.md`
   - Trigger: "analyze requirements", "create FRD"

2. **requirements-document-generator**
   - Generates Word/PDF documents from FRD
   - Output: `docs/requirements-{functionality-name}.docx/.pdf`
   - Trigger: "generate formal documents"

3. **similar-examples-finder**
   - Finds competitor analysis and examples
   - Output: `docs/similar-examples-{functionality-name}.md`
   - Trigger: "find similar examples", "competitor analysis"

4. **user-stories-generator-azure-devops-integration**
   - Generates user stories from FRD
   - Creates work items in Azure DevOps
   - Output: `docs/user-stories-{functionality-name}.md`
   - Trigger: "generate user stories for Sprint X"

## Directory Structure After Installation

```
your-project/
├── .claude/
│   ├── agents/
│   │   ├── business-analyst.md
│   │   └── fullstack-developer.md
│   ├── skills/
│   │   └── ba-agent/
│   │       ├── requirement-analysis-rfd-generation/
│   │       │   └── SKILL.md
│   │       ├── requirements-document-generator/
│   │       │   └── SKILL.md
│   │       ├── similar-examples-finder/
│   │       │   └── SKILL.md
│   │       └── user-stories-generator-azure-devops-integration/
│   │           └── SKILL.md
│   └── mcp.json (if using Azure DevOps)
├── docs/
│   ├── frd-*.md
│   ├── user-stories-*.md
│   └── similar-examples-*.md
├── .env (if using Azure DevOps - DON'T COMMIT!)
└── package.json (optional, for ADO project config)
```

## Troubleshooting

### Skills Not Recognized

**Issue:** Claude doesn't use the skills automatically

**Solutions:**
1. Verify skills are in `.claude/skills/ba-agent/` directory
2. Check each skill has `SKILL.md` file
3. Verify YAML frontmatter is correct (starts with `---`)
4. Explicitly reference: "Use the requirement-analysis-rfd-generation skill to..."
5. Restart Claude Code or reload workspace

### Azure DevOps MCP Not Working

**Issue:** Can't create work items in Azure DevOps

**Solutions:**
1. Verify `.claude/mcp.json` exists and is valid JSON
2. Check environment variables are set: `echo $ADO_PAT`
3. Verify PAT token has correct permissions (Work Items: Read, Write, Manage)
4. Test token at: https://dev.azure.com/{org}/_apis/projects
5. Check MCP server is installed: `npx @azure-devops/mcp-server --version`
6. Note: Skills still work without MCP - they generate markdown reports

### Output Files Not Created

**Issue:** No files in `docs/` directory

**Solutions:**
1. Create docs directory: `mkdir -p docs`
2. Check file permissions: `chmod 755 docs`
3. Verify working directory is project root
4. Check Claude Code logs for errors

### Permission Denied Errors

**Issue:** Installation script fails with permission errors

**Solutions:**
```bash
# Make install script executable
chmod +x platforms/claude/install.sh

# Run with proper permissions
./platforms/claude/install.sh /path/to/project
```

## Updating Skills

To update skills to the latest version:

```bash
# Pull latest changes
cd /path/to/dev-agents
git pull origin master

# Re-run installation
cd platforms/claude
./install.sh /path/to/your/project
```

## Uninstalling

To remove the skills:

```bash
# Remove skills directory
rm -rf .claude/skills/ba-agent

# Optionally remove agents
rm -rf .claude/agents

# Keep generated docs if you want
# Or remove them: rm -rf docs
```

## Getting Help

1. **Check TESTING.md** for test scenarios and examples
2. **Check CLAUDE.md** for repository guidelines
3. **Check skill SKILL.md files** for detailed documentation
4. **Open an issue** at: https://github.com/TabTabGo/dev-agents/issues

## Next Steps

After installation:

1. ✅ Test the requirement-analysis-rfd-generation skill
2. ✅ Review generated FRDs in `docs/` directory
3. ✅ Configure Azure DevOps MCP (if needed)
4. ✅ Try the complete workflow from requirements to user stories
5. ✅ Customize skills for your organization (optional)

Happy coding! 🎉
