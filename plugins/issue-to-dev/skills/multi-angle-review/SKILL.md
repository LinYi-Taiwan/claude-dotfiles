---
name: multi-angle-review
description: >
  Run a multi-angle review on a GitHub issue from PM, Tech Lead, and UX perspectives.
  Use when the user says "review this issue", "analyze this feature request",
  "run multi-angle review", "get PM/tech/UX feedback on this issue", or wants
  to evaluate an issue's business value, technical feasibility, and user experience impact.
metadata:
  version: "0.1.0"
---

# Multi-Angle Review

Analyze a GitHub issue from three perspectives — PM (business value), Tech Lead (feasibility/scope), and UX/Design (user experience) — and synthesize a conclusion.

## Input

Accept one of:

- A GitHub issue URL
- A repo + issue number
- Issue content already in context

Fetch the full issue details if not already available.

## Execution

Launch three agents **in sequence** to review the issue. Each agent receives the full issue context and produces a structured assessment.

### 1. PM Reviewer (pm-reviewer agent)

Focus areas:

- Business value and ROI
- Alignment with product strategy
- User demand signals (upvotes, related issues, customer requests)
- Priority recommendation
- Success metrics

### 2. Tech Lead Reviewer (tech-lead-reviewer agent)

Focus areas:

- Technical feasibility
- Architecture impact
- Scope estimation (S/M/L/XL)
- Dependencies and risks
- Suggested implementation approach
- Breaking changes or migration concerns

### 3. UX/Design Reviewer (ux-reviewer agent)

Focus areas:

- User experience impact
- Accessibility considerations
- Consistency with existing UI patterns
- Whether new designs/mockups are needed
- Edge cases and error states

## Synthesis

After all three reviews complete, synthesize a consolidated conclusion:

1. **Recommendation**: Approve / Needs Discussion / Reject
2. **Priority**: P0 (critical) through P3 (nice-to-have)
3. **Estimated Effort**: S (< 1 day), M (1-3 days), L (3-5 days), XL (> 1 week)
4. **Key Risks**: top 3 risks identified across all reviews
5. **Design Required**: Yes / No
6. **Next Step**: proceed to design, proceed to development, or request more information

## Output

Post the full review as a GitHub comment on the issue using the GitHub MCP.

Format the comment using the template in `references/review-template.md`.

Also add appropriate labels to the issue:

- Priority label (e.g., `priority:P1`)
- Status label (e.g., `status:reviewed`)
- Effort label (e.g., `effort:M`)
