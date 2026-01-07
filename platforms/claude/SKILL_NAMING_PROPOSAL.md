# Skill Naming Proposal

## Current Skill Names (Issues)

| Current Name | Issues |
|-------------|--------|
| `requirement-analysis-frd-generation` | Too long, unclear action, mixed concepts |
| `similar-examples-finder` | Good, but could be more BA-specific |
| `user-stories-generator-azure-devops-integration` | Way too long, mixes feature with platform |
| `requirements-document-generator` | Redundant with first skill, unclear difference |

## Naming Principles

1. **Action-Oriented**: Use verb-noun pattern (e.g., `analyze-requirements`, `generate-stories`)
2. **Concise**: 2-3 words max, use dashes for readability
3. **Clear Purpose**: Name should instantly communicate what it does
4. **Consistent Pattern**: Follow same structure across all skills
5. **Platform-Agnostic**: Don't embed integration details in name (use description instead)

## Proposed New Names

### Option 1: Action-Verb Pattern (RECOMMENDED)

| Old Name | New Name | Slash Command | Purpose |
|----------|----------|---------------|---------|
| `requirement-analysis-frd-generation` | `analyze-requirements` | `/analyze-requirements` | Analyze requirements and generate FRD |
| `similar-examples-finder` | `research-examples` | `/research-examples` | Research similar solutions and competitors |
| `user-stories-generator-azure-devops-integration` | `generate-stories` | `/generate-stories` | Generate user stories (with optional ADO integration) |
| `requirements-document-generator` | `export-requirements` | `/export-requirements` | Export FRD to formal Word/PDF documents |

**Benefits:**
- ✅ Short and memorable
- ✅ Clear action verbs
- ✅ Easy to type
- ✅ Consistent pattern

### Option 2: Noun-Based Pattern

| Old Name | New Name | Slash Command | Purpose |
|----------|----------|---------------|---------|
| `requirement-analysis-frd-generation` | `frd-generator` | `/frd-generator` | Generate Functional Requirements Document |
| `similar-examples-finder` | `market-research` | `/market-research` | Research market and competitors |
| `user-stories-generator-azure-devops-integration` | `story-generator` | `/story-generator` | Generate user stories |
| `requirements-document-generator` | `doc-exporter` | `/doc-exporter` | Export to Word/PDF |

**Benefits:**
- ✅ Noun-focused (thing it creates)
- ✅ Short
- ⚠️ Less action-oriented

### Option 3: BA-Prefixed Pattern (If used in multi-domain system)

| Old Name | New Name | Slash Command | Purpose |
|----------|----------|---------------|---------|
| `requirement-analysis-frd-generation` | `ba-analyze` | `/ba-analyze` | BA: Analyze requirements |
| `similar-examples-finder` | `ba-research` | `/ba-research` | BA: Research examples |
| `user-stories-generator-azure-devops-integration` | `ba-stories` | `/ba-stories` | BA: Generate stories |
| `requirements-document-generator` | `ba-export` | `/ba-export` | BA: Export documents |

**Benefits:**
- ✅ Namespace separation (if you add dev/qa/design skills later)
- ✅ Very short
- ⚠️ Adds extra prefix

## Recommendation: Option 1 (Action-Verb Pattern)

I recommend **Option 1** because:

1. **Clear Intent**: Action verbs immediately communicate what the skill does
2. **User-Friendly**: Easy to remember and type
3. **Professional**: Follows industry conventions for commands/tools
4. **Scalable**: Works well even if you add 50+ more skills
5. **Self-Documenting**: Name describes the action

## Implementation Plan

### 1. Rename Directories

```bash
cd /Users/gsamara/src/github/tabtabgo/dev-agents/platforms/claude/.claude/skills

# Rename skills
mv requirement-analysis-frd-generation analyze-requirements
mv similar-examples-finder research-examples
mv user-stories-generator-azure-devops-integration generate-stories
mv requirements-document-generator export-requirements
```

### 2. Update SKILL.md Frontmatter

Update the `name` field in each SKILL.md:

**analyze-requirements/SKILL.md:**
```yaml
---
name: analyze-requirements
description: Analyze project requirements and generate comprehensive Functional Requirements Documents (FRD). Use when the user describes a project idea and needs structured requirements analysis with actors, functionalities, and NFRs documented.
---
```

**research-examples/SKILL.md:**
```yaml
---
name: research-examples
description: Search for and analyze similar applications, competitor products, and reference implementations. Use when the user wants to see competitor analysis, industry best practices, or design inspiration before finalizing requirements.
---
```

**generate-stories/SKILL.md:**
```yaml
---
name: generate-stories
description: Generate comprehensive user stories from FRD and create them in Azure DevOps backlog using ADO MCP connector. Project name from configuration, iteration/sprint from user's request. Use when FRD is approved and ready to populate Azure DevOps with user stories.
---
```

**export-requirements/SKILL.md:**
```yaml
---
name: export-requirements
description: Generate professional requirements documents in Microsoft Word (.docx) and PDF formats from FRD. Use when formal documentation is required for stakeholders, regulatory compliance, or external vendor communication.
---
```

### 3. Update business-analyst.md Agent

Update references from:
- `/requirement-analysis-frd-generation` → `/analyze-requirements`
- `/similar-examples-finder` → `/research-examples`
- `/user-stories-generator-azure-devops-integration` → `/generate-stories`
- `/requirements-document-generator` → `/export-requirements`

### 4. Update Documentation

Update any references in:
- README.md files
- CLAUDE.md
- Installation scripts
- Other agent definitions

## Alternative Naming Styles to Consider

### Developer-Friendly (CLI-style)

- `req:analyze` (colon separator, namespace-like)
- `req:research`
- `req:stories`
- `req:export`

### Business-Friendly (Natural language)

- `analyze-requirements` ✅ (already in Option 1)
- `research-market`
- `create-stories`
- `export-docs`

### Super-Concise (GitHub Actions style)

- `analyze` (too generic)
- `research` (too generic)
- `stories` (acceptable)
- `export` (too generic)

## Final Recommendation

**Go with Option 1: Action-Verb Pattern**

New skill names:
1. ✅ `analyze-requirements`
2. ✅ `research-examples`
3. ✅ `generate-stories`
4. ✅ `export-requirements`

These names are:
- Professional
- Intuitive
- Action-oriented
- Easy to remember
- Future-proof
