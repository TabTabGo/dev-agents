---
name: research-examples
description: Search for and analyze similar applications, competitor products, and reference implementations. Use when the user wants to see competitor analysis, industry best practices, or design inspiration before finalizing requirements.
allowed-tools: WebSearch, WebFetch, Read, Write
---

# Similar Examples Finder

This skill searches for and presents similar application examples, competitor analysis, and reference implementations to help inform requirements and design decisions.

## When to Use This Skill

- After initial project idea is described
- Before finalizing requirements (to learn from existing solutions)
- When user wants to see what competitors are doing
- To identify industry best practices
- For design inspiration and UX patterns

## Workflow Steps

### 1. Extract Search Keywords

From the user's project description, extract:

1. **Domain/Industry:** (e.g., "task management", "e-commerce", "healthcare")
2. **User Type:** (e.g., "remote teams", "small business", "patients")
3. **Core Functionality:** (e.g., "collaboration", "inventory tracking", "appointment scheduling")
4. **Platform:** (e.g., "web app", "mobile app", "SaaS")

### 2. Conduct Multi-Faceted Search

Use `WebSearch` tool to find examples across different categories:

**Search 1: Direct Competitors**

```
Query: "{domain} {platform} for {user type}"
Example: "task management web app for remote teams"
```

**Search 2: Popular Solutions**

```
Query: "best {domain} {platform} 2025"
Example: "best task management software 2025"
```

**Search 3: Open Source Examples**

```
Query: "{domain} open source {platform} github"
Example: "task management open source web app github"
```

**Search 4: Case Studies**

```
Query: "{domain} case study success story"
Example: "remote team collaboration case study"
```

**Search 5: Design Inspiration**

```
Query: "{domain} UI design examples dribbble behance"
Example: "task management UI design dribbble"
```

**Search 6: Technical Implementation**

```
Query: "{domain} {tech stack} architecture"
Example: "task management react .net architecture"
```

### 3. Categorize and Analyze Results

Organize findings into a comprehensive report at `./docs/similar-examples-{project-name}.md`:

## Report Structure

```markdown
# Similar Examples & Reference Implementations
# For Project: {Project Name}

## Search Date: {current date}

---

## 1. Direct Competitors

### Example 1: {Application Name}
- **URL:** {website}
- **Description:** {What it does}
- **Target Users:** {Who uses it}
- **Key Features:**
  - {Feature 1}
  - {Feature 2}
  - {Feature 3}
- **Pricing Model:** {Free / Freemium / Subscription / One-time}
- **Technology Stack:** {If available}
- **Strengths:**
  - {What they do well}
  - {Unique selling points}
- **Weaknesses/Gaps:**
  - {What they're missing}
  - {Opportunities for differentiation}
- **User Reviews Sentiment:** {Positive/Mixed/Negative}

---

## 2. Popular Solutions (Market Leaders)

### Leader 1: {Product Name}
- **URL:** {website}
- **Market Position:** {e.g., "Most popular for enterprise"}
- **Notable Features:**
  - {Feature that stands out}
  - {Innovation they introduced}
- **User Base:** {Size if available: "10M+ users"}
- **Key Differentiator:** {What makes them successful}
- **Lessons for Our Project:**
  - {What we can learn}
  - {What we should avoid}

---

## 3. Open Source Examples

### Project 1: {GitHub Repository Name}
- **URL:** {github link}
- **Stars:** {star count}
- **Language/Framework:** {Tech stack}
- **Description:** {What it does}
- **Notable Implementation Details:**
  - {Architecture pattern used}
  - {Interesting technical approach}
- **Code Quality:** {Based on documentation, tests, structure}
- **Reusable Components/Patterns:**
  - {Pattern 1 we could adopt}
  - {Pattern 2 we could adopt}
- **License:** {MIT / Apache / GPL / etc.}

---

## 4. Case Studies & Success Stories

### Case Study 1: {Company/Product Name}
- **Source:** {URL to article/case study}
- **Summary:** {Brief overview}
- **Challenge:** {Problem they solved}
- **Solution:** {How they solved it}
- **Results:**
  - {Metric 1: e.g., "50% increase in productivity"}
  - {Metric 2: e.g., "Reduced costs by 30%"}
- **Key Takeaways:**
  - {Lesson 1}
  - {Lesson 2}
- **Relevance to Our Project:** {How this applies}

---

## 5. Design Inspiration

### Design Example 1: {Source}
- **URL:** {dribbble/behance link}
- **Designer:** {Name if available}
- **Design Highlights:**
  - {Visual approach}
  - {UI patterns used}
  - {Color scheme}
  - {Layout structure}
- **User Experience Patterns:**
  - {Navigation approach}
  - {Information architecture}
- **Applicable to Our Project:**
  - {What we could adapt}
  - {Inspiration for specific screens}

---

## 6. Technical Implementation Examples

### Architecture Example 1: {Source}
- **URL:** {blog post/documentation}
- **Tech Stack:** {Technologies used}
- **Architecture Pattern:** {Microservices / Monolith / Serverless}
- **Key Technical Decisions:**
  - {Decision 1 and rationale}
  - {Decision 2 and rationale}
- **Performance Characteristics:**
  - {Scalability approach}
  - {Performance optimizations}
- **Lessons Learned:** {What they discovered}
- **Relevance:** {How this applies to our architecture}

---

## 7. Feature Comparison Matrix

| Feature | Competitor 1 | Competitor 2 | Competitor 3 | Our Opportunity |
|---------|-------------|-------------|-------------|-----------------|
| {Feature 1} | ✅ Full | ⚠️ Limited | ❌ None | {How we could excel} |
| {Feature 2} | ✅ Full | ✅ Full | ✅ Full | {Table stakes} |
| {Feature 3} | ❌ None | ❌ None | ❌ None | {Differentiation} |

---

## 8. Industry Best Practices

Based on the examples analyzed:

### User Experience Best Practices
1. {Practice 1 seen across multiple examples}
   - {Explanation}
   - {Examples: App A, App B}

### Technical Best Practices
1. {Technical pattern commonly used}
   - {Why it's used}
   - {Examples: Project X, Project Y}

### Business Model Best Practices
1. {Pricing/monetization pattern}
   - {Why it works}
   - {Examples}

---

## 9. Market Gaps & Opportunities

### Gap 1: {Unmet Need}
- **Current State:** {What exists now}
- **User Pain Point:** {What users complain about}
- **Opportunity:** {How we could address this}
- **Evidence:** {References from search results}

---

## 10. Recommendations for Our Project

### What to Adopt
1. {Feature/pattern from examples}
   - **Rationale:** {Why this works}
   - **Example Source:** {Where we saw this}
   - **Implementation:** {How we'd adapt it}

### What to Avoid
1. {Anti-pattern from examples}
   - **Why it's problematic:** {Issues observed}
   - **Example Source:** {Where we saw this fail}
   - **Alternative:** {What we should do instead}

### Differentiation Strategy
1. {How we'll stand out}
   - **What others do:** {Current market approach}
   - **What we'll do differently:** {Our unique approach}
   - **Expected benefit:** {Why this matters to users}

---

## 11. References & Further Reading

### Articles & Blog Posts
1. [{Title}]({URL}) - {Brief description}

### Documentation
1. [{Title}]({URL}) - {Brief description}

### GitHub Repositories
1. [{Repository Name}]({URL}) - {Brief description}

---

## Search Metadata
- **Total Examples Found:** {count}
- **Direct Competitors:** {count}
- **Open Source Projects:** {count}
- **Case Studies:** {count}
- **Design Examples:** {count}
- **Search Date:** {date}
```

### 4. Present Summary to User

After compiling the research, provide an executive summary:

```text
🔍 Similar Examples Research Complete!

📊 Found {X} relevant examples:
- {Y} direct competitors
- {Z} open source projects
- {W} case studies
- {V} design examples

🎯 Key Insights:
1. {Top insight from market analysis}
2. {Major differentiation opportunity}
3. {Critical best practice to adopt}

📄 Full Report: ./docs/similar-examples-{project-name}.md

💡 Recommendations:
- Adopt: {Top 2-3 patterns to implement}
- Avoid: {Top 1-2 anti-patterns}
- Differentiate: {How to stand out}

Next Steps:
- Review the full report
- Incorporate insights into FRD
- Identify must-have vs. nice-to-have features
```

## Search Strategy

### Query Construction Rules

1. **Be Specific:** Include domain, platform, and user type
2. **Use Current Year:** For latest trends and tools (2025)
3. **Combine Keywords:** Domain + technology + pattern
4. **Search Variations:** Try different phrasings

### Example Queries by Project Type

**Task Management App:**

- "task management software for remote teams"
- "best project management tools 2025"
- "asana trello alternatives comparison"
- "task management react typescript github"
- "kanban board UI design examples"

**E-commerce Platform:**

- "e-commerce platform small business"
- "best online store builders 2025"
- "shopify alternatives open source"
- "e-commerce react .net architecture"
- "checkout flow UI design best practices"

**Healthcare App:**

- "patient portal healthcare software"
- "telemedicine platform comparison"
- "HIPAA compliant healthcare app github"
- "electronic health records system architecture"
- "healthcare mobile app UI design"

## Quality Criteria

Ensure examples are:

- ✅ **Relevant:** Match the project domain and scale
- ✅ **Recent:** Prefer examples from last 2-3 years
- ✅ **Credible:** From reputable sources
- ✅ **Diverse:** Mix of commercial, open source, and case studies
- ✅ **Actionable:** Provide concrete insights, not just listings

## Integration with Requirements Analysis

This skill complements [requirement-analysis-rfd-generation](../requirement-analysis-rfd-generation/SKILL.md):

1. **Run this skill AFTER** getting initial project description
2. **Use findings to enhance** the FRD with:
   - Industry-standard features
   - Best practices
   - Competitive advantages
3. **Reference examples** in FRD assumptions and decisions

## Notes

- Always use `WebSearch` tool for up-to-date information
- Cite sources with URLs for credibility
- Focus on actionable insights, not just descriptions
- Balance breadth (many examples) with depth (detailed analysis)
- Update searches periodically as market evolves
- Use current year (2025) in search queries
