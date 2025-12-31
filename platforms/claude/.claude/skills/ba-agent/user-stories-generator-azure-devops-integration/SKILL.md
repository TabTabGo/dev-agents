---
name: user-stories-generator-azure-devops-integration
description: Generate comprehensive user stories from FRD and create them in Azure DevOps backlog using ADO MCP connector. Project name from configuration, iteration/sprint from user's request. Use when FRD is approved and ready to populate Azure DevOps with user stories.
allowed-tools: Read, Write, Bash
---

# User Stories Generator & Azure DevOps Integration

This skill generates comprehensive user stories from the FRD and automatically creates them in Azure DevOps backlog using the ADO MCP connector.

## When to Use This Skill

- After FRD is approved
- Before design phase begins
- When ready to populate Azure DevOps backlog
- When project planning and sprint allocation is needed

## Prerequisites

### 1. Azure DevOps MCP Configuration

**For Claude Code**, MCP servers are configured in your workspace settings, not in a global configuration file.

**Setup Steps:**

1. **Install Azure DevOps MCP Server** (if not already available):
   ```bash
   npm install -g @azure-devops/mcp-server
   ```

2. **Configure in Claude Code Settings:**

   Claude Code MCP servers are typically configured via:
   - **VS Code Settings:** If using VS Code extension
   - **CLI Configuration:** If using Claude Code CLI
   - **Project-level `.claude/mcp.json`:** Project-specific MCP configuration

   **Option A: Project-level configuration** (Recommended)

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

   Then set environment variables:
   ```bash
   export ADO_PAT="your-personal-access-token"
   export ADO_ORGANIZATION="your-org-name"
   ```

   **Option B: VS Code Settings** (if using VS Code extension)

   Add to `.vscode/settings.json`:
   ```json
   {
     "claude.mcpServers": {
       "azure-devops": {
         "command": "npx",
         "args": ["-y", "@azure-devops/mcp-server"],
         "env": {
           "ADO_PAT": "your-personal-access-token",
           "ADO_ORGANIZATION": "your-org-name"
         }
       }
     }
   }
   ```

**Required Environment Variables:**
- **ADO_PAT**: Azure DevOps Personal Access Token with Work Items (Read, Write, Manage) permissions
  - Generate at: https://dev.azure.com/{org}/_usersSettings/tokens
- **ADO_ORGANIZATION**: Your Azure DevOps organization name (from URL: dev.azure.com/{org})

### 2. Project Configuration

**Project Name** - Read from configuration sources (in priority order):

**Option A: Environment Variables**
```bash
export ADO_PROJECT_NAME="YourProjectName"
```

**Option B: package.json**
```json
{
  "name": "your-project-name",
  "azureDevOps": {
    "project": "YourProjectName"
  }
}
```

**Option C: .env file**
```bash
ADO_PROJECT_NAME=YourProjectName
```

**Iteration/Sprint** - Specified by user in their request:

The user should specify the iteration/sprint when requesting user story generation:
- Example: "Generate user stories for Sprint 1"
- Example: "Create user stories and assign to Release 2\\Sprint 3"
- Example: "Generate stories for the backlog" (no iteration assignment)

**Configuration Parameters:**
- `ADO_PROJECT_NAME` (required): Azure DevOps project name from configuration
- Iteration/Sprint (from user prompt): Iteration path for story assignment
  - Format: "Sprint 1", "Release 1\\Sprint 2", or omit for backlog
  - Extracted from user's request during execution

## Workflow Steps

### 1. Load Configuration and Parse User Request

**A. Load Project Configuration:**

Read Azure DevOps project name from available sources:

```bash
# Priority 1: Check environment variables
if [ -n "$ADO_PROJECT_NAME" ]; then
    project_name=$ADO_PROJECT_NAME
fi

# Priority 2: Check package.json if exists
if [ -f "package.json" ]; then
    # Extract azureDevOps configuration
    project_name=$(jq -r '.azureDevOps.project // empty' package.json)
fi

# Priority 3: Check .env file if exists
if [ -f ".env" ]; then
    source .env
fi
```

**B. Extract Iteration from User Prompt:**

Parse the user's request to identify the target iteration/sprint:

```text
User examples:
- "Generate user stories for Sprint 1" → iteration = "Sprint 1"
- "Create stories for Release 2\Sprint 3" → iteration = "Release 2\Sprint 3"
- "Generate user stories" → iteration = null (backlog)
- "Add to backlog" → iteration = null (backlog)
```

**C. Validation:**
- Ensure `ADO_PROJECT_NAME` is loaded from configuration
- If not found, fail with clear error message showing all checked sources
- Parse iteration from user's request (optional)
- Log the iteration path if specified, otherwise note "backlog assignment"

### 2. Read FRD

Load the FRD file created by [requirement-analysis-rfd-generation](../requirement-analysis-rfd-generation/SKILL.md):

```bash
frd_path="./docs/frd-{functionality-name}.md"
```

### 3. Extract Functional Requirements

Parse FRD to extract:

1. **Actors** (from section 2)
2. **Functional Requirements** (from section 3)
3. **Acceptance Criteria** (within each FR)
4. **Priority** (Must/Should/Could/Won't Have)
5. **Dependencies** (between requirements)

### 4. Generate User Stories

For each Functional Requirement, create a user story in this format:

**User Story Structure:**

```markdown
# User Story: {US-ID}

## Title
{Short, descriptive title}

## User Story
As a {actor/role}
I want {goal/desire}
So that {benefit/value}

## Acceptance Criteria

### Given/When/Then Format:
1. **Scenario 1: {Scenario Name}**
   - **Given** {initial context/precondition}
   - **When** {action/event}
   - **Then** {expected outcome}

2. **Scenario 2: {Scenario Name}**
   - **Given** {initial context}
   - **When** {action}
   - **Then** {expected outcome}

### Additional Criteria:
- [ ] {Criterion 1}
- [ ] {Criterion 2}

## Priority
{Must Have / Should Have / Could Have / Won't Have}

## Story Points
{Estimation: 1, 2, 3, 5, 8, 13, 21}

## Dependencies
- Depends on: {US-XXX, US-YYY}
- Blocks: {US-ZZZ}

## Tags
{feature-area}, {component}, {priority}

## Technical Notes
{Any implementation hints from FRD}

## Definition of Done
- [ ] Code complete and peer reviewed
- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests passing
- [ ] Acceptance criteria validated
- [ ] Documentation updated
- [ ] Deployed to staging
- [ ] QA approved
```

### 5. Categorize User Stories

Group user stories by:

1. **Epic** (high-level feature area)
2. **Feature** (related group of stories)
3. **Priority** (Must/Should/Could/Won't)

### 6. Create Stories in Azure DevOps

Use Azure DevOps MCP to create user stories with proper project and iteration assignment.

**Process:**

1. **Validate Configuration:**
   - Ensure `ADO_PROJECT_NAME` is loaded from environment/package.json/.env
   - Verify MCP connection to Azure DevOps is active
   - Confirm iteration path exists if `ADO_ITERATION` is specified

2. **Create Work Items:**
   - For each user story, use MCP to create work item with:
     - **Project:** Value from `ADO_PROJECT_NAME`
     - **Work Item Type:** "User Story"
     - **Title:** Story title
     - **Description:** Full user story in "As a... I want... So that..." format
     - **Acceptance Criteria:** Given/When/Then scenarios
     - **Iteration Path:** `{ADO_PROJECT_NAME}\{ADO_ITERATION}` if iteration specified
     - **Priority:** Mapped from Must/Should/Could/Won't
     - **Story Points:** Estimated points
     - **Tags:** Feature area, priority tags

3. **Link Dependencies:**
   - Create work item links for dependencies
   - Link to parent Epic if applicable

**Example MCP Call Structure:**

```json
{
  "project": "{ADO_PROJECT_NAME}",
  "type": "User Story",
  "fields": {
    "System.Title": "User Registration",
    "System.Description": "As a new user...",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "Scenario 1: ...",
    "System.IterationPath": "{ADO_PROJECT_NAME}\\{ADO_ITERATION}",
    "Microsoft.VSTS.Scheduling.StoryPoints": 5,
    "System.Tags": "authentication; must-have"
  }
}
```

### 7. Generate Output Report

Create a comprehensive report at `./docs/user-stories-{functionality-name}.md`

## Report Structure

```markdown
# User Stories Report
# Project: {Project Name}
# Azure DevOps Project: {ADO_PROJECT_NAME}

## Document Information
- **Generated:** {timestamp}
- **Total Stories:** {count}
- **Source:** {FRD file path}
- **ADO Project:** {project_name from env}

---

## Executive Summary

### Story Distribution
- **Epics:** {count}
- **Features:** {count}
- **User Stories:** {count}
- **Total Story Points:** {sum}

### By Priority
- **Must Have:** {count} stories ({story points})
- **Should Have:** {count} stories ({story points})
- **Could Have:** {count} stories ({story points})

### By Epic
- **Epic 1:** {count} stories ({story points})
- **Epic 2:** {count} stories ({story points})

---

## Epic 1: {Epic Name}

### Epic Description
{Description from FRD}

### User Stories in This Epic

#### US-001: {Story Title}
**Azure DevOps ID:** #{work_item_id}
**Link:** {ADO URL}

**User Story:**
As a **{actor}**
I want **{goal}**
So that **{benefit}**

**Acceptance Criteria:**

1. **Scenario: {Name}**
   - **Given** {context}
   - **When** {action}
   - **Then** {outcome}

**Priority:** {Must Have}
**Story Points:** {5}
**Tags:** {tags}
**Dependencies:** {dependencies}

**Technical Notes:**
{Implementation hints}

**Definition of Done:**
- [ ] Code complete and peer reviewed
- [ ] Unit tests >80% coverage
- [ ] Integration tests passing
- [ ] Acceptance criteria validated
- [ ] Documentation updated

---

## Backlog Organization

### Sprint 0 (Setup & Infrastructure)
- US-000: Development environment setup
- US-001: CI/CD pipeline configuration

### Sprint 1 (MVP Core Features)
**Total Story Points:** {X}
- US-003: {Story} (5 pts)
- US-004: {Story} (3 pts)

**Sprint Goal:** {Sprint goal}

---

## Azure DevOps Integration Status

### Created Work Items
✅ {count} user stories created in ADO
✅ {count} epics created
✅ {count} dependencies linked

### ADO Project Details
- **Project:** {ADO_PROJECT_NAME}
- **Organization:** {ADO_ORGANIZATION}
- **Team:** {ADO_TEAM}

---

## Story Point Estimation Guidelines

Planning Poker with Fibonacci sequence:

- **1 point:** Trivial change, <1 hour
- **2 points:** Simple feature, <4 hours
- **3 points:** Moderate feature, ~1 day
- **5 points:** Complex feature, 2-3 days
- **8 points:** Very complex, ~1 week
- **13 points:** Extremely complex, 2 weeks
- **21 points:** Epic-level, needs breakdown

**If story is >13 points:** Break it down into smaller stories!

---

## Dependency Graph

```text
US-001 (Registration)
  ↓
US-002 (Email Verification)
  ↓
US-003 (Login)
  ↓
US-004 (Profile) ← US-005 (Dashboard)
```

---

## Priority Matrix

### Must Have (P0) - MVP Critical
Stories without which the product cannot function:
- US-001: {Story}
- US-002: {Story}

**Total:** {count} stories, {points} story points

### Should Have (P1) - Important
Important features for good user experience:
- US-010: {Story}

**Total:** {count} stories, {points} story points

### Could Have (P2) - Nice to Have
Features that improve UX but not critical:
- US-020: {Story}

**Total:** {count} stories, {points} story points

---

## Next Steps

1. **Review Stories:** Team reviews all user stories for clarity
2. **Refine Estimates:** Planning poker session to validate story points
3. **Sprint Planning:** Assign stories to sprints based on priority
4. **Backlog Grooming:** Regular refinement of upcoming stories
5. **ADO Sync:** Keep Azure DevOps updated with any changes
```

## Error Handling

### If ADO_PROJECT_NAME Not Set

```text
❌ Error: ADO_PROJECT_NAME not found in any configuration source!

Configuration checked:
- Environment variable: ADO_PROJECT_NAME not set
- package.json: No azureDevOps.project field found
- .env file: Not found or ADO_PROJECT_NAME not defined

To fix (choose one option):

Option 1: Set environment variable
export ADO_PROJECT_NAME="YourProjectName"

Option 2: Add to package.json
{
  "azureDevOps": {
    "project": "YourProjectName"
  }
}

Option 3: Create .env file
ADO_PROJECT_NAME=YourProjectName

Note: Iteration/sprint is specified in your request, not in configuration.
Example: "Generate user stories for Sprint 1"
```

### If MCP Not Configured

```text
❌ Error: Azure DevOps MCP server not configured!

Please configure the MCP server for Claude Code:

Option 1: Project-level configuration (Recommended)
Create .claude/mcp.json in your project root:
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

Then set environment variables:
export ADO_PAT="your-personal-access-token"
export ADO_ORGANIZATION="your-org-name"

Option 2: VS Code Settings (if using VS Code extension)
Add to .vscode/settings.json:
{
  "claude.mcpServers": {
    "azure-devops": {
      "command": "npx",
      "args": ["-y", "@azure-devops/mcp-server"],
      "env": {
        "ADO_PAT": "your-pat",
        "ADO_ORGANIZATION": "your-org"
      }
    }
  }
}

After configuration, restart Claude Code or reload the workspace.
```

### If MCP Connection Fails

```text
⚠️ Warning: Could not connect to Azure DevOps MCP

User stories have been generated but NOT created in ADO.

Troubleshooting:
1. Verify MCP server is configured in settings
2. Check ADO_PAT token is valid and not expired
3. Ensure ADO_ORGANIZATION is correct
4. Verify network connectivity to Azure DevOps
5. Check MCP server logs for detailed errors

Fallback:
- User stories markdown report generated at ./docs/user-stories-{functionality-name}.md
- Import manually or re-run after fixing MCP connection
```

### If Project Not Found in ADO

```text
❌ Error: Project '{ADO_PROJECT_NAME}' not found in Azure DevOps organization '{ADO_ORGANIZATION}'

Please verify:
- Project name is correct (case-sensitive)
- You have access to the project
- Organization is correct

Available projects in this organization:
{List available projects if MCP can query them}
```

### If Iteration Not Found

```text
⚠️ Warning: Iteration '{iteration}' not found in project '{ADO_PROJECT_NAME}'

The iteration you specified in your request doesn't exist in Azure DevOps.

User stories will be created in the backlog without iteration assignment.

To fix:
Option 1: Create the iteration in Azure DevOps
1. Go to Azure DevOps project settings
2. Navigate to Project configuration > Iterations
3. Create iteration: {iteration}
4. Re-run this skill with the same request

Option 2: Use an existing iteration
Check available iterations in Azure DevOps and modify your request.
Example: "Generate user stories for Sprint 2" (if Sprint 2 exists)

Option 3: Add to backlog
Simply request: "Generate user stories" (without specifying iteration)
```

## Output Summary

After completion:

```text
✅ User Stories Generated Successfully!

📊 Summary:
- Total Stories: {count}
- Total Story Points: {sum}
- Epics: {count}
- Must Have: {count} stories
- Should Have: {count} stories

📄 Report: ./docs/user-stories-{functionality-name}.md

🔗 Azure DevOps:
- Organization: {ADO_ORGANIZATION}
- Project: {ADO_PROJECT_NAME}
- Iteration: {iteration from user prompt} (or "Backlog" if not specified)
- Stories Created: {count}
- Epics Created: {count}
- View: https://dev.azure.com/{ADO_ORGANIZATION}/{ADO_PROJECT_NAME}/_backlogs

📋 Configuration:
- Project source: {Environment Variable | package.json | .env file}
- Iteration source: User request

📈 Iteration Assignment:
- {iteration}: {count} stories ({points} pts)
- Backlog (unassigned): {count} stories ({points} pts)

Next Steps:
1. Review stories in Azure DevOps
2. Verify iteration assignments
3. Conduct sprint planning
4. Assign stories to team members
5. Begin development!
```

## Quality Checklist

All user stories must have:

- [ ] Clear "As a... I want... So that..." format
- [ ] At least 2 acceptance scenarios in Given/When/Then
- [ ] Testable and measurable criteria
- [ ] Priority assigned
- [ ] Story points estimated
- [ ] Technical notes (if applicable)
- [ ] Dependencies identified
- [ ] Definition of Done specified
- [ ] >80% code coverage requirement included

## Integration with Other Skills

- **Requires:** [requirement-analysis-rfd-generation](../requirement-analysis-rfd-generation/SKILL.md) (FRD must exist)
- **Feeds into:** Design Agent (references user stories), QA Agent (creates tests from acceptance criteria)
- **Updates:** Azure DevOps backlog for project tracking

## Notes

### Configuration Sources

**Project Name:**
- Read from configuration in this order: **Environment Variables** → **package.json** → **.env file**
- Never hardcode project names
- Always validate configuration is loaded before making ADO calls

**Iteration/Sprint:**
- **NOT from configuration** - parsed from user's request
- User specifies in prompt: "Generate user stories for Sprint 1"
- If user doesn't specify, stories go to backlog
- Never read iteration from environment variables or config files

### Azure DevOps MCP Setup

- **Required:** MCP server must be configured in Claude Code workspace settings
- **Configuration Location:**
  - Project-level: `.claude/mcp.json` (recommended)
  - VS Code: `.vscode/settings.json`
- **PAT Token:** Needs Work Items (Read, Write, Manage) permissions
- **Organization:** Must be specified in MCP env configuration
- **Security:** Use environment variables for sensitive tokens (PAT)

### Work Item Creation

- Project name from `ADO_PROJECT_NAME` configuration
- Iteration from user's prompt (e.g., "Sprint 1", "Release 2\Sprint 3")
- Iteration path format: `{ADO_PROJECT_NAME}\{iteration-from-prompt}`
- If iteration not found, stories created in backlog with warning
- Create epics before stories for proper linking
- Use consistent tagging for filtering and reporting

### User Request Examples

- "Generate user stories for Sprint 1" → Assigns to Sprint 1
- "Create user stories for Release 2\Sprint 3" → Assigns to Release 2\Sprint 3
- "Generate user stories" → Creates in backlog (no iteration)
- "Add to backlog" → Creates in backlog (no iteration)

### Best Practices

- Follow Azure DevOps naming conventions
- Parse iteration from user's natural language request
- Include ADO work item IDs in markdown report for traceability
- Generate markdown report even if MCP connection fails (fallback documentation)
- Enforce >80% code coverage in Definition of Done per CLAUDE.md
- All test requirements must meet the minimum coverage threshold
- Validate iteration exists before assignment or warn user

### Troubleshooting

- If MCP fails, gracefully generate the markdown report only
- Clear error messages should guide users to fix configuration issues
- Report should include all work item details for manual import if needed
- If user doesn't specify iteration, confirm: "Stories will be added to backlog"
