---
name: fe-feasibility
description: >
  Review a design or feature for frontend feasibility in a React + TypeScript codebase.
  Use when the user says "check FE feasibility", "is this feasible to build",
  "review frontend effort", "component check", "estimate frontend work",
  or when the pipeline needs a feasibility gate before development begins.
metadata:
  version: "0.1.0"
---

# FE Feasibility Review

Evaluate whether a proposed design/feature is feasible to implement in the existing React + TypeScript frontend codebase, estimate effort, and identify risks.

## Input

Accept:
- A GitHub issue with design mockup/spec attached
- A design spec or mockup description
- A Figma link with design details

## Process

### 1. Codebase Analysis

Scan the existing codebase to understand:
- **Component inventory**: What UI components already exist? Use `find` or `grep` to locate component directories.
- **Design system**: Are there shared components, tokens, or theme files?
- **State management**: What pattern is used (Redux, Zustand, Context, etc.)?
- **Routing**: How are pages/routes structured?
- **API layer**: How does the frontend communicate with the backend?

### 2. Component Mapping

For each UI element in the design:

| Design Element | Existing Component | Gap | Effort |
|---------------|-------------------|-----|--------|
| Button variant | `<Button>` | New "outline-danger" variant | S |
| Data table | `<DataGrid>` | None — reuse as-is | — |
| Modal dialog | None | Need new `<ConfirmDialog>` | M |

### 3. Effort Estimation

Break down the work into:
- **Component work**: New components, modifications to existing ones
- **State management**: New stores, reducers, or context needed
- **API integration**: New endpoints to consume, data transformations
- **Routing changes**: New pages, route guards, navigation updates
- **Testing**: Unit tests, integration tests, E2E tests needed

Provide total estimate: S (< 1 day), M (1-3 days), L (3-5 days), XL (> 1 week)

### 4. Risk Assessment

Identify:
- **Technical risks**: Performance concerns, browser compatibility, complex animations
- **Dependency risks**: New packages needed, version conflicts
- **Design risks**: Unclear specs, edge cases not covered, responsive gaps
- **Testing risks**: Hard-to-test interactions, flaky test patterns

### 5. Verdict

Issue one of:
- **✅ Approve** — Feasible with the current stack, reasonable effort
- **⚠️ Approve with caveats** — Feasible but flag specific concerns
- **❌ Reject** — Not feasible as designed, suggest design revisions

### 6. Post to GitHub

Post the feasibility report as a GitHub comment:

```markdown
## 🔧 FE Feasibility Review

### Verdict: [Approve / Approve with caveats / Reject]

### Component Analysis
[Component mapping table]

### Effort Estimate: [S/M/L/XL]
[Breakdown]

### Risks
[Risk list]

### Recommendations
[Suggestions for design adjustments or implementation approach]
```

If rejected, clearly explain what needs to change in the design and loop back to the design phase.

## Tech Stack Assumptions

- React 18+ with TypeScript
- Functional components with hooks
- Standard tooling (Vite/Next.js, ESLint, Prettier, Jest/Vitest)
