---
name: export-requirements
description: Generate professional requirements documents in Microsoft Word (.docx) and PDF formats from FRD. Use when formal documentation is required for stakeholders, regulatory compliance, or external vendor communication.
allowed-tools: Read, Write, Bash, Skill
---

# Requirements Document Generator (Word & PDF)

This skill generates professional requirements documents in Microsoft Word (.docx) and PDF formats based on a specific structure suitable for formal documentation and stakeholder review.

## When to Use This Skill

- After FRD is complete
- When formal documentation is required for stakeholders
- For regulatory compliance documentation
- When project needs to be archived
- For external vendor communication

## Prerequisites

Before using this skill, ensure:
1. FRD document exists (created by [requirement-analysis-rfd-generation](../requirement-analysis-rfd-generation/SKILL.md))
2. The `docx` and `pdf` skills are available (check `/mnt/skills/public/`)

## Required Document Structure

Each requirements document must follow this exact structure:

1. Title/Feature Name
2. Scope
3. Business Requirements
4. Preconditions
5. Functional Requirements
6. Non-Functional Requirements
7. Assumptions

## Workflow Steps

### 1. Read FRD and Extract Information

Load the FRD and extract:

- Project/Feature name
- Scope and objectives
- Business requirements
- Preconditions
- All functional requirements
- All non-functional requirements
- Assumptions and constraints

### 2. Generate Word Document

Use the `docx` skill to create a professionally formatted Word document.

**File Location:** `./docs/requirements-{project-name}.docx`

**Document Components:**

**Title Page:**
- Document title
- Project name
- Version information table (Version, Date, Author, Status, Confidentiality)

**Table of Contents:**
- Auto-generated from headings
- Include all major sections

**Sections:**

1. **Title/Feature Name**
   - Feature overview
   - Document purpose

2. **Scope**
   - In scope items (bulleted list)
   - Out of scope items (bulleted list)
   - Target users
   - Success criteria

3. **Business Requirements**
   - Business objectives (numbered list)
   - Business value (bulleted list)
   - Key stakeholders (table format)

4. **Preconditions**
   - Required conditions (checklist)
   - Technical prerequisites

5. **Functional Requirements**
   - Grouped by category
   - Each requirement includes:
     - ID and title (heading)
     - Priority (color-coded)
     - Description
     - Acceptance criteria (numbered)
     - Dependencies (if any)

6. **Non-Functional Requirements**
   - Performance (table format)
   - Scalability
   - Security
   - Availability
   - Usability
   - Compliance

7. **Assumptions**
   - Technical assumptions
   - Business assumptions
   - User assumptions

**Appendices:**
- A. Glossary
- B. References
- C. Revision History

### 3. Generate PDF from Word Document

Use the `pdf` skill or system tools to convert the Word document to PDF.

**Options:**

1. **Using pdf skill:** Follow the pdf skill documentation for proper conversion
2. **Using LibreOffice:** If available on the system

```bash
libreoffice --headless --convert-to pdf --outdir ./docs ./docs/requirements-{project-name}.docx
```

### 4. Validate Documents

Check that both documents were created successfully and verify file sizes.

### 5. Present Documents to User

Provide download links or file paths for both documents.

## Document Formatting Standards

### Typography

- **Title:** 28pt, Bold, Dark Blue
- **Heading 1:** 24pt, Bold, Dark Blue
- **Heading 2:** 18pt, Bold, Blue
- **Heading 3:** 14pt, Bold, Black
- **Body Text:** 11pt, Calibri or Arial
- **Table Headers:** Bold, White text on Blue background

### Color Scheme

- **Primary:** RGB(0, 51, 102) - Dark Blue
- **Secondary:** RGB(0, 102, 204) - Blue
- **Accent:** RGB(255, 165, 0) - Orange
- **Priority High:** RGB(255, 0, 0) - Red
- **Priority Low:** RGB(0, 128, 0) - Green

### Tables

- Use "Light Grid Accent 1" style
- Header row with bold text
- Alternating row colors for readability

### Lists

- Use bullet points for unordered lists
- Use numbered lists for steps or ordered items
- Indent sub-items appropriately

### Page Setup

- **Margins:** 1 inch all sides
- **Page Size:** Letter (8.5" x 11")
- **Orientation:** Portrait
- **Footer:** Page numbers centered
- **Header:** Document title and version

## Output Summary

After generating documents:

```
✅ Requirements Documents Generated Successfully!

📄 Documents Created:
- Word Document: requirements-{project-name}.docx ({size} KB)
- PDF Document: requirements-{project-name}.pdf ({size} KB)

📋 Document Structure:
1. Title/Feature Name
2. Scope
3. Business Requirements
4. Preconditions
5. Functional Requirements ({count} requirements)
6. Non-Functional Requirements ({count} requirements)
7. Assumptions ({count} items)

📊 Content Summary:
- Total Pages: {page_count}
- Functional Requirements: {fr_count}
- Non-Functional Requirements: {nfr_count}
- Actors/Stakeholders: {actor_count}

💼 Use Cases:
- Stakeholder review and approval
- Regulatory compliance documentation
- Vendor/contractor communication
- Project archival

Next Steps:
1. Review documents for accuracy
2. Share with stakeholders for approval
3. Store in document management system
4. Proceed to design phase after approval
```

## Quality Checklist

Before finalizing documents:

- [ ] All 7 sections present and complete
- [ ] Table of contents accurate
- [ ] Professional formatting applied
- [ ] Tables properly formatted
- [ ] Page numbers present
- [ ] No formatting errors
- [ ] PDF renders correctly
- [ ] All content from FRD included
- [ ] Spelling and grammar checked
- [ ] Company branding applied (if applicable)

## Integration with Other Skills

- **Requires:** [requirement-analysis-rfd-generation](../requirement-analysis-rfd-generation/SKILL.md) (FRD must exist)
- **Uses:** `docx` skill, `pdf` skill
- **Output:** Formal documents for stakeholder review
- **Feeds into:** Project approval process

## Notes

- Always read the `docx` and `pdf` skill documentation first
- Use proper Word styling (not manual formatting)
- Ensure PDF conversion preserves all formatting
- Include page numbers and headers/footers
- Add company logo if available
- Follow organizational document templates if provided
- Version documents properly (1.0, 1.1, 2.0, etc.)
- Keep documents in sync with FRD
- Archive previous versions when updating
