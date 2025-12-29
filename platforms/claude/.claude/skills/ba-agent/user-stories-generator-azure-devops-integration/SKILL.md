---
name: user-stories-generator-azure-devops-integration
description: Generate comprehensive user stories from FRD and create them in Azure DevOps backlog using ADO MCP connector. Use when FRD is approved and ready to populate Azure DevOps with user stories for sprint planning.
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

### Environment Variables Required

The following environment variables must be set:

```bash
# Required
export ADO_PROJECT_NAME="YourProjectName"

# Optional but recommended
export ADO_ORGANIZATION="YourOrgName"
export ADO_TEAM="YourTeamName"
```

### Azure DevOps MCP Setup

Ensure Azure DevOps MCP connector is configured and accessible.

## Workflow Steps

### 1. Read FRD

Load the FRD file created by [requirement-analysis-rfd-generation](../requirement-analysis-rfd-generation/SKILL.md):

```bash
frd_path="./docs/frd-{project-name}.md"
```

### 2. Extract Functional Requirements

Parse FRD to extract:

1. **Actors** (from section 2)
2. **Functional Requirements** (from section 3)
3. **Acceptance Criteria** (within each FR)
4. **Priority** (Must/Should/Could/Won't Have)
5. **Dependencies** (between requirements)

### 3. Generate User Stories

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

### 4. Categorize User Stories

Group user stories by:

1. **Epic** (high-level feature area)
2. **Feature** (related group of stories)
3. **Priority** (Must/Should/Could/Won't)

### 5. Create Stories in Azure DevOps

Use Azure DevOps MCP to create user stories.

**Important:** Always validate that `ADO_PROJECT_NAME` environment variable is set before attempting to create work items.

### 6. Generate Output Report

Create a comprehensive report at `./docs/user-stories-{project-name}.md`

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
❌ Error: ADO_PROJECT_NAME environment variable not set!

To fix:
export ADO_PROJECT_NAME="YourProjectName"

Or add to your .env file:
ADO_PROJECT_NAME=YourProjectName
```

### If MCP Connection Fails

```text
⚠️ Warning: Could not connect to Azure DevOps MCP

User stories have been generated but NOT created in ADO.

Options:
1. Check MCP connector configuration
2. Verify Azure DevOps credentials
3. Create stories manually using the generated report
4. Re-run after fixing MCP connection
```

### If Project Not Found in ADO

```text
❌ Error: Project '{ADO_PROJECT_NAME}' not found in Azure DevOps

Update environment variable to match existing project.
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

📄 Report: ./docs/user-stories-{project-name}.md

🔗 Azure DevOps:
- Project: {ADO_PROJECT_NAME}
- Stories Created: {count}
- Epics Created: {count}

📈 Sprint Allocation:
- Sprint 1: {count} stories ({points} pts)
- Sprint 2: {count} stories ({points} pts)
- Backlog: {count} stories ({points} pts)

Next Steps:
1. Review stories in Azure DevOps
2. Conduct sprint planning
3. Assign stories to team members
4. Begin development!
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

- Always read project name from `ADO_PROJECT_NAME` environment variable
- Never hardcode project names
- Validate environment variable before making ADO calls
- Create epics before stories for proper linking
- Use consistent tagging for filtering and reporting
- Follow Azure DevOps naming conventions
- Include ADO work item IDs in the report for traceability
- Enforce >80% code coverage in Definition of Done per CLAUDE.md
- All test requirements must meet the minimum coverage threshold
