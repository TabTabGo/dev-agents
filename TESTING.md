# Testing BA Agent Skills

This document provides test scenarios for the Business Analyst agent skills.

## Prerequisites

1. **For Azure DevOps Integration Skill:**
   - Configure MCP as described in the skill documentation
   - Set up environment variables or package.json with `ADO_PROJECT_NAME`

2. **Directory Structure:**
   - Skills are located in: `platforms/claude/.claude/skills/ba-agent/`
   - Output directory will be: `./docs/`

## Test Scenarios

### Scenario 1: Generate FRD for User Authentication

**Prompt to Claude Code:**
```text
I want to build a user authentication module with the following features:
- User registration with email and password
- Email verification
- Login with JWT tokens
- Password reset functionality
- Multi-factor authentication (optional)

Target users: Web application users
Expected load: 10,000 concurrent users
Security: Must comply with OWASP top 10
```

**Expected Output:**
- File: `./docs/frd-user-authentication.md`
- Contains: Actors, Functional Requirements, NFRs, etc.

**Skill Used:** `requirement-analysis-rfd-generation`

---

### Scenario 2: Find Similar Examples

**Prompt to Claude Code:**
```text
Find similar examples and competitor analysis for a user authentication system.
I want to see what best practices exist in the market.
```

**Expected Output:**
- File: `./docs/similar-examples-user-authentication.md`
- Contains: Competitor analysis, open source examples, design patterns

**Skill Used:** `similar-examples-finder`

---

### Scenario 3: Generate User Stories (Without Azure DevOps)

**Prompt to Claude Code:**
```text
Generate user stories from the user authentication FRD for Sprint 1
```

**Expected Output:**
- File: `./docs/user-stories-user-authentication.md`
- Contains: User stories with acceptance criteria, story points
- If MCP not configured: Markdown report only (no ADO creation)

**Skill Used:** `user-stories-generator-azure-devops-integration`

---

### Scenario 4: Generate Formal Requirements Documents

**Prompt to Claude Code:**
```text
Generate formal Word and PDF requirements documents from the user authentication FRD
```

**Expected Output:**
- File: `./docs/requirements-user-authentication.docx`
- File: `./docs/requirements-user-authentication.pdf`

**Skill Used:** `requirements-document-generator`

---

## Complete Workflow Test

**Step 1: Requirements Analysis**
```text
Analyze requirements for a task management application for remote teams:
- Create, assign, and track tasks
- Real-time collaboration
- File attachments
- Comments and notifications
- Sprint planning boards

Target: 1000 concurrent users
Tech stack: React, .NET, PostgreSQL
```

**Step 2: Find Examples**
```text
Find similar examples for task management applications
```

**Step 3: Generate User Stories**
```text
Generate user stories for Sprint 1 focusing on core task management features
```

**Step 4: Generate Documents** (Optional)
```text
Generate formal requirements documents for stakeholder review
```

---

## Debugging Tips

### If Skills Don't Activate:

1. **Check Skill Location:**
   ```bash
   ls -la platforms/claude/.claude/skills/ba-agent/*/SKILL.md
   ```

2. **Verify YAML Frontmatter:**
   - Each SKILL.md must start with `---` on line 1
   - Must have `name` and `description` fields
   - Must close with `---`

3. **Check Permissions:**
   ```bash
   chmod -R 755 platforms/claude/.claude/skills/
   ```

4. **Explicitly Reference Skills:**
   ```text
   "Use the requirement-analysis-rfd-generation skill to..."
   ```

### If Azure DevOps Integration Fails:

1. **Check MCP Configuration:**
   - Verify `.claude/mcp.json` exists and is valid JSON
   - Check environment variables: `ADO_PAT`, `ADO_ORGANIZATION`, `ADO_PROJECT_NAME`

2. **Test Without ADO:**
   - The skill will generate markdown report even if MCP fails
   - Review the generated markdown in `./docs/user-stories-*.md`

3. **Check Project Configuration:**
   ```bash
   # Check if ADO_PROJECT_NAME is set
   echo $ADO_PROJECT_NAME

   # Or check package.json
   cat package.json | grep -A 3 "azureDevOps"
   ```

---

## Expected File Structure After Testing

```
dev-agents/
├── docs/
│   ├── frd-user-authentication.md
│   ├── frd-task-management.md
│   ├── similar-examples-user-authentication.md
│   ├── similar-examples-task-management.md
│   ├── user-stories-user-authentication.md
│   ├── user-stories-task-management.md
│   ├── requirements-user-authentication.docx
│   ├── requirements-user-authentication.pdf
│   └── ...
├── platforms/
│   └── claude/.claude/skills/ba-agent/
│       ├── requirement-analysis-rfd-generation/
│       ├── requirements-document-generator/
│       ├── similar-examples-finder/
│       └── user-stories-generator-azure-devops-integration/
└── TESTING.md (this file)
```

---

## Quick Start Command

To start testing immediately:

```bash
# Create docs directory if it doesn't exist
mkdir -p docs

# Start Claude Code
# Then paste this prompt:
```

**Test Prompt:**
```text
I want to build a simple blog application with:
- User authentication (register, login, logout)
- Create, edit, delete blog posts
- Comments on posts
- Categories and tags
- Search functionality

Please analyze these requirements and generate an FRD.
```

This should trigger the `requirement-analysis-rfd-generation` skill automatically.

---

## Validation Checklist

After running tests:

- [ ] FRD generated in `./docs/` directory
- [ ] FRD contains all 12 standard sections
- [ ] File naming follows `frd-{functionality-name}.md` pattern
- [ ] >80% code coverage mentioned in Technical KPIs
- [ ] Actors properly identified
- [ ] Functional requirements numbered (FR-XXX-YYY)
- [ ] Non-functional requirements defined
- [ ] User stories have Given/When/Then format (if generated)
- [ ] Azure DevOps work items created (if MCP configured)

---

## Need Help?

If skills aren't working:

1. Check the skill descriptions in SKILL.md files
2. Verify YAML frontmatter is correctly formatted
3. Try explicitly referencing the skill name
4. Check Claude Code logs for errors
5. Ensure working directory is the project root
