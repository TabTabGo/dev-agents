---
name: requirement-analysis-rfd-generation
description: Analyze project requirements and generate comprehensive Functional Requirements Documents (FRD). Use when the user describes a project idea and needs structured requirements analysis with actors, functionalities, and NFRs documented.
allowed-tools: Read, Write, Grep, Glob
---

# Requirements Analysis & FRD Generation

This skill analyzes project requirements, identifies actors and functionalities, and generates a comprehensive Functional Requirements Document (FRD) that serves as the knowledge base for all other development phases.

## When to Use This Skill

- User has described their project idea
- Need to analyze and structure requirements systematically
- Creating foundational documentation for the development workflow
- Before design and architecture phases

## Workflow Steps

### 1. Analyze User Input

Extract and analyze the following from the user's project description:

**Project Overview:**
- Core problem being solved
- Target users/audience
- Business objectives
- Success criteria

**Identify Actors:**
- Primary actors (main users)
- Secondary actors (administrators, support staff)
- External systems/integrations
- Stakeholders

**Functional Requirements:**
- Core features
- User workflows
- System behaviors
- Business rules
- Data requirements

**Non-Functional Requirements:**
- Performance (response time, throughput)
- Scalability (concurrent users, data volume)
- Security (authentication, authorization, encryption)
- Availability (uptime, disaster recovery)
- Usability (accessibility, responsiveness)
- Compliance (GDPR, HIPAA, SOC2, etc.)

### 2. Ask Clarifying Questions

If any area is unclear, ask targeted questions:

**Unclear Project Scope:**
- "What is the primary problem this application solves?"
- "Who are the main users of this system?"
- "What existing solutions are you replacing or competing with?"

**Unclear Actors:**
- "What roles will users have in the system?"
- "Will there be different permission levels?"
- "Are there any external systems that need to integrate?"

**Unclear Functionalities:**
- "What are the must-have features for launch?"
- "What features can be deferred to future releases?"
- "Describe the typical user workflow from start to finish"

**Unclear Non-Functionals:**
- "How many concurrent users do you expect?"
- "What are your performance requirements (response time, uptime)?"
- "Are there any compliance requirements (GDPR, HIPAA, etc.)?"
- "What is your target launch timeline?"

### 3. Generate FRD Markdown Document

Generate a comprehensive FRD markdown file at `./docs/frd-{functionality-name}.md` that will be consumed by other agents in the workflow.

The filename should reflect the specific functionality or module being documented (e.g., `frd-user-authentication.md`, `frd-payment-processing.md`).

Use the Write tool to create the file with the following structure:

```markdown
# Functional Requirements Document (FRD)
# {Functionality/Module Name}

## Document Information
- **Project ID:** {auto-generated or user-provided}
- **Version:** 1.0
- **Date:** {current date}
- **Author:** Business Analyst Agent
- **Status:** Draft

---

## 1. Executive Summary

### 1.1 Project Overview
{2-3 paragraph description of the project, the problem it solves, and the proposed solution}

### 1.2 Business Objectives
- {Objective 1}
- {Objective 2}

### 1.3 Success Criteria
- {Metric 1: e.g., Achieve 1000 active users in first month}
- {Metric 2: e.g., Reduce processing time by 50%}

---

## 2. Actors

### 2.1 Primary Actors

#### Actor: {Actor Name}
- **Description:** {Who they are}
- **Goals:** {What they want to accomplish}
- **Responsibilities:** {What they can do in the system}
- **Access Level:** {Permissions}

### 2.2 Secondary Actors
{Administrator, support staff, etc.}

### 2.3 External Systems
- **System Name:** {External API/Service}
  - **Purpose:** {Why integration is needed}
  - **Integration Type:** {REST API / GraphQL / Webhook}
  - **Data Exchange:** {What data is shared}

---

## 3. Functional Requirements

### 3.1 {Feature Category}

#### FR-{CATEGORY}-{NUMBER}: {Feature Name}
- **Priority:** {Must Have / Should Have / Could Have / Won't Have}
- **Description:** {Detailed description}
- **Acceptance Criteria:**
  - {Criterion 1}
  - {Criterion 2}
- **Dependencies:** {List dependent requirements}

---

## 4. Non-Functional Requirements

### 4.1 Performance Requirements

#### NFR-PERF-{NUMBER}: {Requirement Name}
- **Requirement:** {Specific measurable requirement}
- **Measurement:** {How it will be measured}
- **Target Environment:** {Where it applies}

### 4.2 Scalability Requirements
### 4.3 Security Requirements
### 4.4 Availability Requirements
### 4.5 Usability Requirements
### 4.6 Compliance Requirements

---

## 5. Business Rules

### BR-{NUMBER}: {Rule Name}
- **Description:** {Detailed rule description}
- **Example:** {Concrete example}
- **Enforcement:** {How this is enforced in the system}

---

## 6. Data Requirements

### 6.1 Data Entities

#### Entity: {Entity Name}
- **Attributes:**
  - {Attribute 1} ({type, constraints})
  - {Attribute 2} ({type, constraints})
- **Relationships:**
  - {Relationship description}

### 6.2 Data Retention
{Retention policies}

---

## 7. Integration Requirements

### 7.1 Third-Party Integrations

#### Integration: {Service Name}
- **Purpose:** {Why this integration is needed}
- **Type:** {REST API / GraphQL / SDK / Webhook}
- **Authentication:** {API Key / OAuth 2.0 / JWT}
- **Data Flow:** {What data is exchanged}
- **Frequency:** {Real-time / Batch / Scheduled}

---

## 8. Assumptions and Constraints

### 8.1 Assumptions
- {Assumption 1}
- {Assumption 2}

### 8.2 Constraints
- **Budget:** {Amount}
- **Timeline:** {Duration}
- **Technology Stack:** {Required technologies}

---

## 9. Out of Scope

The following items are explicitly out of scope for this release:
- {Feature 1 deferred to future release}
- {Feature 2 not included}

---

## 10. Success Metrics

### 10.1 Key Performance Indicators (KPIs)

#### Technical KPIs
- API response time < 200ms (95th percentile)
- Code coverage > 80%

#### Business KPIs
- User acquisition: {Target}
- Revenue: {Target}

### 10.2 Acceptance Criteria for Launch
- [ ] All "Must Have" features implemented and tested
- [ ] Performance benchmarks met
- [ ] Security audit passed

---

## 11. Glossary
- **Term:** Definition

---

## 12. Document Change History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | {date} | BA Agent | Initial document creation |
```

### 4. Save and Confirm

After generating the FRD content, use the Write tool to save it to `./docs/frd-{functionality-name}.md`.

Then present a summary to the user:

```text
✅ FRD Created Successfully!

📄 File: ./docs/frd-{functionality-name}.md

📊 Summary:
- Actors Identified: {count}
- Functional Requirements: {count}
- Non-Functional Requirements: {count}
- Business Rules: {count}

This FRD markdown file will be used by:
- Design Agent (to create UI/UX specifications)
- Architect Agent (to design technical architecture)
- QA Agent (to generate test cases)
- Development Agents (to implement features)
- Other BA skills (to generate documents and user stories)
```

## Quality Checklist

Before finalizing the FRD:
- [ ] All actors identified with clear roles
- [ ] Functional requirements numbered and categorized
- [ ] Each FR has priority and acceptance criteria
- [ ] Non-functional requirements are measurable
- [ ] Business rules are clearly defined
- [ ] Success metrics are specific and measurable
- [ ] Assumptions and constraints documented
- [ ] Out of scope items listed
- [ ] Glossary includes all technical terms

## Integration with Other Agents

The FRD will be used by:
- **Design Agent:** References actors and functional requirements for UI design
- **Architect Agent:** Uses NFRs to make technology stack decisions
- **QA Agent:** Creates test cases based on acceptance criteria
- **Frontend/Backend Agents:** Implement features per FRD specifications

## Notes

- The FRD is a **markdown file only** - no Word/PDF generation in this skill
- Other skills will consume this FRD markdown file to generate their outputs
- Filename format: `./docs/frd-{functionality-name}.md` (e.g., `frd-user-authentication.md`)
- The FRD can document an entire project OR a specific functionality/module
- Always create FRD before proceeding to design phase
- FRD serves as single source of truth for requirements
- Update FRD when requirements change using Edit tool
- Use semantic versioning for FRD updates
- Enforce >80% code coverage requirement per CLAUDE.md in Technical KPIs section
- Save the file using the Write tool with appropriate functionality/module name
