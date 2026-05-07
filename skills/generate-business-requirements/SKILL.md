---
name: generate-business-requirements
description: Generate a Business Requirement Document (BRD) as a professionally formatted Word (.docx) file. Use this skill when the user needs a business-oriented requirements document to share with stakeholders, business teams, or decision-makers. This is different from the FRD — the BRD is high-level, business-scoped, and avoids technical implementation details. Trigger when the user mentions BRD, business requirements document, business requirements, stakeholder document, or needs a document for business review. The output filename follows the pattern {project}_{feature}_{version}.docx.
allowed-tools: Read, Write, Bash, Skill
---

# Generate Business Requirements Document (BRD)

Create a professional Business Requirement Document as a Word (.docx) file that is suitable for sharing with business stakeholders. The BRD is intentionally high-level and business-oriented — it describes *what* the business needs and *why*, not *how* it will be built technically. This distinguishes it from the FRD which contains detailed functional specifications.

## When to Use

- When business stakeholders need a document to review and approve requirements
- When scoping a new feature or project for business sign-off
- When communicating requirements to non-technical audiences
- When a formal business-level document is needed before diving into detailed FRD/technical specs
- After an FRD exists and you need to extract the business-facing view of it

## Input Sources

The BRD content can come from:

1. **An existing FRD** — Read `./docs/frd-{name}.md` and extract business-level information, stripping technical details
2. **Direct conversation** — Gather requirements interactively from the user
3. **Both** — Use FRD as a base and supplement with user input

When reading from an FRD, translate technical language into business language. For example, "TIMESTAMPTZ column type" becomes a glossary entry; "MediatR pipeline" is omitted entirely.

## Output

**Filename:** `./docs/{project}_{feature}_{version}.docx`

- `{project}` — Project or product name (e.g., `BookingCentral`)
- `{feature}` — Feature or sub-project name (e.g., `TimezoneHandling`)
- `{version}` — Document version (e.g., `v1.0`)
- Use PascalCase with no spaces. Separate parts with underscore.
- Example: `./docs/BookingCentral_TimezoneHandling_v1.0.docx`

Ask the user for project name, feature name, and version if not already clear from context. Default version to `v1.0` for new documents.

## Document Structure

The BRD follows this exact structure, matching the template in `assets/template-example.docx`. Use the `docx` skill to generate the Word document.

### Title Page (First Page)

Three centered lines followed by a metadata table:

1. **Project Name** — Large title text (28pt, bold)
2. **Feature Name** — Subtitle text (18pt)  
3. **"Business Requirement Document"** — Document type label (14pt)

**Metadata Table** (2 columns, no header row, left-aligned):

| Field | Description |
|-------|-------------|
| Status | `Draft — Pending Review` (default for new docs) |
| Version | e.g., `1.0` |
| Date | Current date, formatted as `1 April 2026` |
| Product | Project/product name |
| Domain | Business domain this feature belongs to |
| Affected Systems | Comma-separated list of systems impacted |

### Header and Footer

- **Header**: `{Project Name}  |  {Feature Name}  DRAFT` — appears on all pages after the title page
- **Footer**: `Confidential — Internal Use Only` on the left, `Page X` on the right — all pages

### Numbered Sections

The body contains numbered Heading1 sections. The exact sections depend on the feature, but the standard BRD structure is:

**1. Purpose & Scope**
- Why this document exists and what business problem it addresses
- What is in scope and out of scope
- Target audience for this document
- Business objectives and expected outcomes

**2. Core Principles**
- Guiding principles and constraints that shape the requirements
- Business rules that must be respected
- Compliance or regulatory considerations

**3. Business Context**
- Current state / pain points
- Desired future state
- Key stakeholders and their interests
- Business value and ROI justification

**4. Requirements Overview**
- High-level business requirements (not technical specs)
- Each requirement should state the business need, not the implementation
- Use clear, numbered sub-sections (4.1, 4.2, etc.)
- Include priority (Must Have / Should Have / Nice to Have)
- Include success criteria for each requirement

**5. Source System Behaviour** *(if applicable)*
- How existing systems currently behave
- What data flows exist
- What changes are expected from a business perspective

**6. Impact Analysis**
- Systems affected
- Teams affected
- Process changes required
- Training needs
- Rollout considerations

**7. Assumptions & Constraints**
- Business assumptions made
- Known constraints (budget, timeline, resources)
- Dependencies on other projects or decisions

**8. Risks & Mitigations**
- Business risks identified
- Proposed mitigations
- Risk owners

**9. Acceptance Criteria**
- How the business will validate the feature meets requirements
- Sign-off process
- Key milestones

**10. Glossary**
- Table with columns: `Term` | `Definition`
- Define all domain-specific terms, acronyms, and system names
- Keep definitions business-friendly — avoid technical jargon

Sections 3-9 are flexible — adapt them to the specific feature. Some features may not need "Source System Behaviour" but might need a "User Journey" section instead. Use judgment, but always include sections 1, 2, and 10 (Glossary).

When the content for a section isn't yet available, insert a placeholder: `{{add business requirement details}}` — this signals to reviewers that the section needs input.

## Formatting Standards

These match the example template and must be followed exactly:

### Page Setup
- **Page Size:** US Letter (12240 x 15840 DXA / 8.5" x 11")
- **Margins:** 0.75 inches all sides (1080 DXA)
- **Orientation:** Portrait

### Typography
- **Title (project name):** 28pt, Bold
- **Subtitle (feature name):** 18pt
- **Document type label:** 14pt
- **Heading 1:** 16pt, Bold, color `#1F4E79` (dark blue)
- **Heading 2:** 13pt, Bold, color `#2E75B6` (blue)
- **Heading 3:** 12pt, Bold, color `#404040` (dark gray)
- **Body Text:** 11pt, Calibri
- **Table text:** 10pt

### Color Scheme
- **Primary (Heading 1):** `#1F4E79` — Dark Blue
- **Secondary (Heading 2):** `#2E75B6` — Blue
- **Tertiary (Heading 3):** `#404040` — Dark Gray
- **Table header background:** `#2E75B6` with white text

### Tables
- Glossary table and metadata table use clean borders
- Header row with bold text and blue background (`#2E75B6`) with white text
- Alternating row shading for readability (light gray `#F2F2F2` on even rows)
- Use `WidthType.DXA` for table widths (not PERCENTAGE — breaks in Google Docs)
- Set both `columnWidths` on table AND `width` on each cell

### Lists
- Use bullet points for unordered items
- Use numbered lists for ordered/prioritized items
- Do not use unicode bullets directly — use numbering config with `LevelFormat.BULLET`

## Workflow

### Step 1: Gather Information

Determine the source of requirements:

- If an FRD exists at `./docs/frd-*.md`, read it and extract business-level content
- If no FRD exists, ask the user for: project name, feature name, domain, affected systems, purpose, key requirements, and glossary terms
- Confirm the filename components: project, feature, version

### Step 2: Generate the Word Document

Invoke the `docx` skill to create the document. Follow these critical rules from the docx skill:

- Always set page size explicitly to US Letter (not A4 default)
- Use `WidthType.DXA` for all table widths
- Set both `columnWidths` on table AND `width` on each cell
- Never use unicode bullets — use numbering config with `LevelFormat.BULLET`
- Type parameter is REQUIRED for ImageRun

Build the document with all sections, metadata table, header, footer, and glossary table.

### Step 3: Validate

After generating, verify:
- File was created at the correct path
- File size is reasonable (> 5KB)
- Filename matches the `{project}_{feature}_{version}.docx` pattern

### Step 4: Present to User

```
Business Requirement Document Generated:

Document: ./docs/{project}_{feature}_{version}.docx
Status:   Draft — Pending Review
Version:  {version}

Sections:
1. Purpose & Scope
2. Core Principles
3-9. [Feature-specific sections]
10. Glossary ({count} terms)

Next Steps:
1. Review the document and fill in any {{placeholder}} sections
2. Share with stakeholders for feedback
3. Update status to "Approved" after sign-off
4. Proceed to detailed FRD if not already created
```

## Relationship to Other Skills

- **analyze-requirements** generates the detailed FRD — the BRD can be created *from* an FRD by extracting business-level content
- **export-requirements** generates a formal document from FRD with full technical detail — the BRD is deliberately less detailed
- **generate-stories** creates user stories from FRD — typically happens after BRD approval
- **research-examples** can inform the BRD's business context section

## Key Reminders

- This document is for business audiences — avoid technical jargon
- Keep language clear, direct, and accessible to non-technical stakeholders
- Focus on *what* and *why*, not *how*
- Every requirement should tie back to a business objective
- The glossary bridges the gap — define technical terms there so they can be used sparingly in the body
