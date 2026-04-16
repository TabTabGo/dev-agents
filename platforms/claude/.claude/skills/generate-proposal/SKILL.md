---
name: generate-proposal
description: Generate a professional client Proposal as a Word (.docx) file from a BRD, RFP, or brief combined with an Excel estimate spreadsheet. Use this skill when the user needs a client-facing commercial proposal that bundles understanding of requirements, proposed solution, timeline, and priced commercials pulled from an estimate sheet. Trigger when the user mentions proposal, client proposal, commercial proposal, quote, SOW draft, or asks to turn a BRD/RFP/brief plus an estimate into a formal document. The output filename follows the pattern {client}_{project}_Proposal_{version}.docx.
allowed-tools: Read, Write, Bash, Skill
---

# Generate Proposal Document

Create a professional, client-facing Proposal as a Word (.docx) file. The proposal synthesizes a requirements source (BRD, RFP, or brief) with a priced estimate spreadsheet into a single document suitable for sending to a client for review and sign-off. The document is branded for **TabTabGo FZCO** and uses AED as the default currency.

## When to Use

- When a client has shared an RFP or brief and needs a formal written response
- When a BRD has been finalized internally and needs to be turned into a client-facing commercial proposal
- When an estimate has been produced and needs to be wrapped in narrative context (understanding, approach, timeline, terms)
- When a Statement of Work draft is needed as a precursor to a signed contract
- After `generate-business-requirements` has produced a BRD and commercials are ready

## Input Sources

The proposal content comes from **two required inputs**:

### 1. Requirements Source (one of)

- **BRD** — an existing `./docs/{project}_{feature}_{version}.docx` produced by the `generate-business-requirements` skill
- **RFP** — a client-provided PDF, DOCX, or Markdown file containing the client's request for proposal
- **Brief** — a shorter client brief in any of the above formats, or pasted directly into the conversation

Ask the user which source applies. If the source is a BRD, read it via the `docx` skill. If PDF, use a PDF reader tool. Extract: client needs, business context, scope, constraints, success criteria.

### 2. Estimate Spreadsheet

An Excel file (`.xlsx`) with **multiple sheets**. Parse using `openpyxl` via Bash. Iterate all sheets — do not assume the estimate is on the active sheet.

**Expected sheets:**

| Sheet (fuzzy match) | Purpose |
|---------------------|---------|
| `Phase Estimation` / `Estimate` / `Estimates` | Main priced task breakdown (see columns below) |
| `Open Questions` / `Questions` / `Clarifications` | Items requiring client clarification before scope is final |
| `Assumptions` / `Assumption` | Assumptions underpinning the estimate |
| `Variables` (optional, reference only) | Rates and inputs used to compute costs — **do not include in proposal** |

Match sheet names case-insensitively and allow minor variations (`Open Questions`, `Open_Questions`, `OpenQuestions`, `Q&A`). If a sheet is missing, proceed without it but warn the user. The `Variables` sheet is internal — never surface it in the client-facing document.

#### 2a. Estimate sheet — columns (row 1 headers)

| Column | Purpose |
|--------|---------|
| Phase | Phase name — appears as a blue banded header row (e.g. `Phase 0 — Design & Setup`) |
| Task ID | Hierarchical ID: `N.N` for feature-level (green band), `N.Na` / `N.Nb` for sub-tasks |
| Task | Short task name |
| Description | Detailed description of the work |
| Assign to | Team member or role (exclude from client-facing output unless asked) |
| Est. Days | Base estimate in days |
| Buffer 20% | Buffer days |
| Total Days | Est. Days + Buffer |
| Est. Weeks | Total Days converted to weeks |
| Cost | AED cost, populated on Phase Subtotal rows (blank for retainer phases) |
| Comments | Internal notes — **omit from client-facing output** |
| Billing Type / Notes (rightmost col) | Retainer indicator on Phase Subtotal rows. When populated with text like `Retainer Based. Monthly 5000`, the phase is billed as a monthly retainer instead of a fixed phase cost. Parse the monthly amount from the string (e.g. `5000` → `AED 5,000 / month`). |

**Row types to recognize:**
- **Phase header row** — Phase column populated, Task ID empty. Starts a new phase block.
- **Feature header row** — Task ID is `N.N` (e.g. `1.1`), Task column holds the feature name (e.g. `Creator Feature`).
- **Sub-task row** — Task ID is `N.Na`, `N.Nb`, etc.
- **Phase Subtotal row** — Task column = `Phase N Subtotal`. Contains aggregated Total Days, Est. Weeks, and AED Cost.

The skill must aggregate from the estimate sheet:
- **Total project days** (sum of all Phase Subtotal Total Days across all phases, fixed and retainer)
- **Total project weeks**
- **Total fixed cost in AED** (sum of Phase Subtotal Costs for non-retainer phases only)
- **Total monthly retainer in AED** (sum of monthly amounts for retainer phases — surfaced separately, never added to the fixed total)
- **Per-phase breakdown** — each phase carries:
  - `name`
  - `total_days`, `total_weeks`
  - `billing_type` — `"fixed"` or `"retainer"`
  - `cost_aed` — fixed price (for `fixed` phases) OR `null` (for `retainer` phases)
  - `monthly_retainer_aed` — monthly amount (for `retainer` phases) OR `null` (for `fixed` phases)
  - `retainer_raw_note` — original note text (e.g. `"Retainer Based. Monthly 5000"`) for traceability

**Retainer detection:** if a Phase Subtotal row has the rightmost Billing Type / Notes cell matching `/retainer/i`, mark the phase `billing_type = "retainer"`. Extract the monthly amount with a number regex (e.g. `/(\d[\d,]*(\.\d+)?)/`). If extraction fails, warn the user and set `monthly_retainer_aed = null` with a `{{monthly retainer TBD}}` placeholder.

#### Duration rounding (client-facing only)

All **day** and **week** values shown in the proposal must be rounded to the **nearest whole number** using standard half-up rounding:
- `2.8 weeks` → `3 weeks`
- `6.1 weeks` → `6 weeks`
- `14.0 days` → `14 days`
- `11.7 days` → `12 days`

Rules:
- **Rounding applies to display only.** Never round the underlying values before using them in other calculations — compute totals from raw values, then round the final displayed number.
- **Never round costs.** AED amounts always preserve their exact cents (e.g. `AED 17,199.00`).
- Apply rounding consistently everywhere a duration appears: Executive Summary headline numbers, Deliverables & Milestones table, Timeline table, Commercials Pricing Summary table, and any narrative prose.
- When summing rounded per-phase durations, the sum must match the rounded grand total derived from the raw grand total — not the sum of the rounded phase values. If a minor discrepancy occurs, trust the rounded grand total computed from the raw sum and adjust the largest phase's displayed value by ±1 to reconcile.

#### 2b. Open Questions sheet — columns

Header row 1 columns (exact):

| Column | Purpose |
|--------|---------|
| `#` | Sequential number |
| `Question` | The open question text |
| `Owner` | Who is responsible to answer (e.g. `Comms Visioneers`, `Ghassan`) |
| `Status` | `Open`, `Closed`, `Confirmed`, etc. |
| `Priority` | `High`, `Medium`, `Low` |
| `Target Phase` | Phase by which the answer is needed (e.g. `Phase 1`, `Phase 1/3`) |
| `Notes` | Optional extra context or confirmations (e.g. `Confirmed: ProjectLine.Cost`) |

Read every non-empty data row. Normalize to:

```
open_questions = [
  { "num": 1, "question": "...", "owner": "...", "status": "Open",
    "priority": "High", "target_phase": "Phase 1", "notes": "..." },
  ...
]
```

Skip rows where `Status` is `Closed` / `Resolved` / `Confirmed` **unless the user explicitly asks to include them** — these have been answered and don't belong in a client-facing open questions list.

#### 2c. Assumptions sheet — columns

Header row 1 columns (exact):

| Column | Purpose |
|--------|---------|
| `#` | Sequential number |
| `Assumption` | The assumption statement |
| `Impact if Wrong` | Consequence if the assumption doesn't hold |
| `Phase` | Phase the assumption applies to (`Phase 0`, `Phase 1`, `All`) |
| `Status` | `Assumed`, `Confirmed`, `To Verify` |

Read every non-empty data row. Normalize to:

```
assumptions = [
  { "num": 1, "assumption": "...", "impact": "...",
    "phase": "Phase 1", "status": "Assumed" },
  ...
]
```

Include all statuses in the proposal — `Confirmed` assumptions reassure the client, `Assumed` / `To Verify` flag items that may affect scope. Use the `Status` to drive a subtle cell color in the output table:
- `Confirmed` — `#E2EFDA` (light green)
- `Assumed` — `#FFF2CC` (light yellow)
- `To Verify` — `#FCE4D6` (light orange)

## Output

**Filename:** `./docs/{client}_{project}_Proposal_{version}.docx`

- `{client}` — Client company name (e.g. `AcmeCorp`)
- `{project}` — Project name (e.g. `VCIPlatform`)
- `{version}` — Document version (e.g. `v1.0`)
- PascalCase, underscores between parts, no spaces.
- Example: `./docs/AcmeCorp_VCIPlatform_Proposal_v1.0.docx`

Ask for client, project, and version if not clear. Default version to `v1.0`.

## Document Structure

The proposal follows this structure, but sections should be **adapted to what the client is asking for**. If the RFP requests specific sections (e.g. security compliance, SLA commitments), add them. If sections don't apply, drop them. Sections marked **required** must always appear.

### Cover Page (Required)

- **TabTabGo FZCO logo** (centered at top, from `assets/tabtabgo-logo.png`, max width ~3 inches)
- **Client name** (28pt, bold, centered)
- **Project name** (18pt, centered)
- **"Commercial Proposal"** (14pt, centered)
- **Metadata table** (2 cols, no header):

| Field | Description |
|-------|-------------|
| Prepared for | Client name |
| Prepared by | TabTabGo FZCO |
| Version | e.g. `1.0` |
| Date | Current date, `1 April 2026` format |
| Status | `Draft — Pending Client Review` (default) |
| Validity | Default `30 days from issue date` |
| Currency | `AED (United Arab Emirates Dirham)` |

### Header and Footer (Required)

- **Header**: `TabTabGo FZCO  |  {Client Name} — {Project Name}  PROPOSAL` with small logo on the right. Appears on all pages after cover.
- **Footer**: `Confidential — Prepared for {Client Name}` on the left, `Page X of Y` on the right.

### Numbered Sections

**1. Executive Summary** (Required)
- 1–2 paragraphs: who we are, what the client needs, what we propose, total investment, total timeline
- Headline numbers block: total fixed cost in AED, total monthly retainer in AED (if any), total weeks, number of phases
- **Per-phase cost breakdown table** summarizing the commercials at a glance:

  | Phase | Duration | Billing | Cost |
  |-------|----------|---------|------|
  | Phase 0 — Design & Setup | 3 weeks | Fixed | AED 17,199.00 |
  | Phase 1 — Core Platform | 5 weeks | Fixed | AED 3,528.00 |
  | Phase 2 — Retainer Support | 9 weeks | Retainer | AED 5,000.00 / month |
  | **Total** | **17 weeks** | — | **AED 20,727.00 fixed + AED 5,000.00 / month** |

  - Use rounded weeks (see Duration rounding rules)
  - For retainer phases, show `Retainer` in Billing column and `AED N,NNN.NN / month` in Cost column — **never a fixed price**
  - Total row: sum fixed costs and monthly retainers separately. If there are no retainer phases, drop the retainer portion of the total. If every phase is retainer, drop the fixed portion.

**2. Understanding of Requirements**
- Summarize what the client is asking for, derived from the BRD/RFP/brief
- Demonstrate comprehension — this is where we earn credibility
- Call out any ambiguities or clarifications needed

**3. Proposed Solution / Approach**
- High-level solution narrative
- Architecture or methodology summary (non-technical)
- Why this approach fits the client's needs

**4. Scope**
- **4.1 In Scope** — bulleted list derived from estimate phases and features
- **4.2 Out of Scope** — explicit exclusions

**5. Deliverables & Milestones**
- Table: `Phase` | `Deliverables` | `Duration (weeks)` | `Milestone`
- Derived from the estimate spreadsheet's Phase and Feature rows

**6. Team & Roles**
- Roles proposed for the project (PM, Solution Architect, Full-stack Dev, QA, etc.)
- Brief bios or role descriptions
- Omit specific names unless the client expects them

**7. Timeline**
- Summary table: `Phase` | `Start Week` | `End Week` | `Duration` | `Key Activities`
- Derived from estimate — cumulative weeks from phase to phase
- Optional Gantt-style visual (ASCII or narrative if chart generation is complex)

**8. Commercials** (Required)
- **8.1 Pricing Summary** table: `Phase` | `Description` | `Duration (days)` | `Duration (weeks)` | `Cost (AED)`
  - One row per phase, totals at bottom
  - Values pulled from Phase Subtotal rows in the estimate
- **8.2 Detailed Breakdown** — bulleted or table listing of tasks per phase with Est. Days and Total Days (exclude internal columns: Assign to, Comments)
- **8.3 Payment Schedule** — use the following fixed template verbatim:

  > Each phase is invoiced independently on the following milestone schedule:
  > - 30% on phase kick-off (signed SOW and access provisioning complete)
  > - 40% at phase submission (typically on start of UAT phase)
  > - 30% on phase final delivery and written acceptance by Visioneers
  >
  > Payment terms: Net 30 days from invoice date.

  Render the bullet items as a proper bulleted list. Replace `Visioneers` only if the user explicitly specifies a different accepting party; otherwise keep it as-is.
- **8.4 Currency** — AED. All figures formatted as `AED 1,234.56`
- **8.5 Taxes** — statement on VAT (default: `All amounts are exclusive of applicable VAT`)

**9. Assumptions & Dependencies**
- Populated directly from the `Assumptions` sheet — one row per assumption
- Table columns: `#` | `Assumption` | `Impact if Wrong` | `Phase` | `Status`
- Apply the status-based cell background shading defined in §2c
- Add client-side dependencies (access, approvals, third-party systems) as a sub-section below the table
- Heading note: "The pricing in Section 8 is predicated on the following assumptions. Any deviation may trigger a change request."

**10. Open Questions & Clarifications**
- Populated directly from the `Open Questions` sheet — filtered to rows where `Status` is `Open` (exclude `Closed` / `Confirmed` unless the user overrides)
- Table columns: `#` | `Question` | `Owner` | `Priority` | `Target Phase` | `Notes`
- Order rows by `Priority` (High → Medium → Low), then by `#`
- Heading note: "The following items require confirmation prior to finalizing scope and commercials. Responses may adjust the estimate in Section 8."
- If the sheet is absent or no `Open` rows remain, omit this section entirely

**11. Risks & Mitigations**
- Table: `Risk` | `Likelihood` | `Impact` | `Mitigation`

**12. Terms & Conditions**
- Proposal validity period (default 30 days)
- Change request process
- IP ownership statement
- Confidentiality clause
- Warranty period (default 30 days post go-live)
- Governing law (default `Laws of the United Arab Emirates`)

**13. Acceptance & Sign-off** (Required)
- Signature block for client and TabTabGo FZCO
- Fields: Name, Title, Signature, Date (one block for each party)

**14. Appendix** (Optional)
- A. Detailed estimate breakdown (full task list from Excel)
- B. Glossary of terms
- C. Referenced documents (BRD, RFP filename, etc.)

**Flexibility:** Adapt sections 2–12 to what the RFP or brief asks for. Always include 1, 8, 9, 10 (when data exists), and 13.

When content isn't yet known, insert `{{to be confirmed}}` as a placeholder.

## Formatting Standards

Match the TabTabGo BRD styling exactly.

### Page Setup
- **Page Size:** US Letter (12240 x 15840 DXA / 8.5" x 11")
- **Margins:** 0.75 inches all sides (1080 DXA)
- **Orientation:** Portrait

### Typography
- **Title (client name):** 28pt, Bold
- **Subtitle (project name):** 18pt
- **Document type label:** 14pt
- **Heading 1:** 16pt, Bold, `#1F4E79` (Dark Blue)
- **Heading 2:** 13pt, Bold, `#2E75B6` (Blue)
- **Heading 3:** 12pt, Bold, `#404040` (Dark Gray)
- **Body Text:** 11pt, Calibri
- **Table text:** 10pt

### Color Scheme
- **Primary (Heading 1):** `#1F4E79` — Dark Blue
- **Secondary (Heading 2):** `#2E75B6` — Blue
- **Tertiary (Heading 3):** `#404040` — Dark Gray
- **Table header background:** `#2E75B6` with white text
- **Phase row band (pricing table):** `#1F4E79` with white text (matches estimate spreadsheet)
- **Feature row band (pricing table):** `#E2EFDA` (light green, matches estimate)

### Logo
- **File:** `assets/tabtabgo-logo.png` (must be present)
- **Cover page:** centered, max width 3 inches
- **Header (after cover):** right-aligned, max height 0.4 inches

### Currency Formatting
- Always format monetary values as `AED 1,234.56` with thousands separator
- Totals row in pricing table: bold, `#1F4E79` text

### Tables
- Metadata, pricing, timeline, and risk tables use clean borders
- Header row with bold white text on `#2E75B6` background
- Alternating row shading on long tables (`#F2F2F2` on even rows)
- Use `WidthType.DXA` for all table widths (never PERCENTAGE — breaks in Google Docs)
- Set both `columnWidths` on table AND `width` on each cell

### Lists
- Bullet points for unordered items, numbered lists for ordered/prioritized items
- Never use unicode bullets — use numbering config with `LevelFormat.BULLET`

## Workflow

### Step 1: Gather Inputs

Ask the user for:
1. Client name, project name, version
2. Path to requirements source (BRD / RFP / brief)
3. Path to estimate `.xlsx` file
4. Any RFP-specific sections to add beyond the default structure

Confirm the logo exists at `assets/tabtabgo-logo.png`. If missing, warn the user.

### Step 2: Parse the Estimate

Use Bash with Python + `openpyxl` to read the Excel file:

```python
from openpyxl import load_workbook
wb = load_workbook(path, data_only=True)

# Find each target sheet by fuzzy name match (case-insensitive, ignoring spaces/underscores)
def find_sheet(wb, *candidates):
    norm = lambda s: s.lower().replace(" ", "").replace("_", "")
    wanted = {norm(c) for c in candidates}
    for name in wb.sheetnames:
        if norm(name) in wanted or any(w in norm(name) for w in wanted):
            return wb[name]
    return None

estimate_ws    = find_sheet(wb, "Phase Estimation", "Estimate", "Estimates")
questions_ws   = find_sheet(wb, "Open Questions", "Questions", "Clarifications", "Q&A")
assumptions_ws = find_sheet(wb, "Assumptions", "Assumption")
# Note: "Variables" sheet exists in some workbooks — it holds rates/inputs and must NOT
# be surfaced in the proposal. Do not read it.

# For estimate: iterate rows, classify as Phase header / Feature header / Task / Subtotal
# For questions & assumptions: detect header row, map columns dynamically, read all data rows
```

Produce a normalized structure:

```
phases = [
  {
    "name": "Phase 0 — Design & Setup",
    "total_days": 14.0,
    "total_weeks": 2.8,
    "cost_aed": 17199.00,
    "features": [...],
    "tasks": [...]
  },
  ...
]
grand_total = { "days": ..., "weeks": ..., "cost_aed": ... }

open_questions = [
  { "num": 1, "question": "...", "owner": "Comms Visioneers", "status": "Open",
    "priority": "High", "target_phase": "Phase 1", "notes": "" },
  ...
]

assumptions = [
  { "num": 1, "assumption": "...", "impact": "...",
    "phase": "Phase 1", "status": "Assumed" },
  ...
]
```

If `open_questions` is empty, skip Section 10 in the final document. If `assumptions` is empty, keep Section 9 but mark it `{{to be confirmed}}`.

### Step 3: Extract Requirements Content

- If BRD: read via `docx` skill, pull sections 1 (Purpose & Scope), 3 (Business Context), 4 (Requirements Overview) to populate "Understanding of Requirements"
- If RFP PDF: read the PDF and summarize the client ask into the "Understanding" section
- If brief: use the text provided directly

### Step 4: Generate the Word Document

Invoke the `docx` skill. Critical rules:
- Always set page size explicitly to US Letter
- Use `WidthType.DXA` for all table widths
- Set both `columnWidths` on table AND `width` on each cell
- Never use unicode bullets — use `LevelFormat.BULLET` numbering config
- `type` parameter is REQUIRED for `ImageRun` (for logo)
- Embed logo via `ImageRun` with `type: "png"`

Build cover → headers/footers → numbered sections → pricing tables → sign-off page.

### Step 5: Validate

- File created at `./docs/{client}_{project}_Proposal_{version}.docx`
- File size > 10KB (proposals with tables and logo should exceed this)
- Grand total in document matches sum of phase subtotals from Excel
- Logo renders on cover and header

### Step 6: Present to User

```
Proposal Generated:

Document: ./docs/{client}_{project}_Proposal_{version}.docx
Client:   {client}
Project:  {project}
Status:   Draft — Pending Client Review
Version:  {version}
Validity: 30 days from {issue_date}

Commercials Summary:
  Total Phases:   {n}
  Total Duration: {total_days} days ({total_weeks} weeks)
  Total Cost:     AED {total_cost}

Sections Included:
1. Executive Summary
2. Understanding of Requirements
3. Proposed Solution
4. Scope (In / Out)
5. Deliverables & Milestones
6. Team & Roles
7. Timeline
8. Commercials
9. Assumptions & Dependencies ({n_assumptions} items from estimate)
10. Open Questions & Clarifications ({n_questions} items from estimate)
11. Risks & Mitigations
12. Terms & Conditions
13. Acceptance & Sign-off
14. Appendix

Next Steps:
1. Review the document and fill in any {{to be confirmed}} placeholders
2. Have an internal reviewer validate commercials against the estimate
3. Share with the client for feedback
4. Update status to "Approved" after client sign-off
```

## Relationship to Other Skills

- **generate-business-requirements** produces the BRD that can feed the "Understanding of Requirements" section
- **analyze-requirements** produces the FRD — the proposal can reference it in the Appendix but the FRD itself is not sent to the client
- **export-requirements** is for requirements docs, not commercial proposals — use *this* skill for proposals
- **research-examples** can inform the "Proposed Solution" section with industry context

## Key Reminders

- This document is **client-facing** — polish, clarity, and confidence matter
- Always verify the grand total in the document matches the Excel estimate exactly before presenting
- Never expose internal columns from the estimate (Assign to, Comments) to the client
- The logo must render — if missing, the proposal looks unprofessional. Block generation until it's in place.
- Default currency is AED; do not convert to USD unless explicitly asked
- Adapt sections to what the client is asking for — the default structure is a starting point, not a rigid template
- Keep tone professional, confident, and partnership-oriented — avoid hedging language
