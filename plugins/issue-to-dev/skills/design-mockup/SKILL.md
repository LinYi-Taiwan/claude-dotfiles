---
name: design-mockup
description: >
  Create or reference design mockups for a GitHub issue using Figma MCP.
  Use when the user says "create a design for this issue", "make a mockup",
  "design the UI for this feature", "generate design mockup", or when
  the multi-angle review determines that design work is needed.
metadata:
  version: "0.1.0"
---

# Design Mockup

Create UI design mockups for a feature request or bug fix using Figma MCP tools.

## Input

Accept:
- A GitHub issue (URL or number) with the review conclusions
- A feature description with UX requirements
- Specific design requirements from the UX reviewer

## Process

### 1. Gather Design Context

- Read the issue description and review conclusions.
- Identify the screens/components that need design.
- Check the existing Figma design system for reusable components using Figma MCP's `get_design_context` and `get_variable_defs`.

### 2. Create Design

Using Figma MCP tools:

1. **Check existing designs**: Use `get_code_connect_map` and `get_code_connect_suggestions` to see what design-to-code mappings already exist.
2. **Get design system context**: Use `get_design_context` to understand the current design system tokens, components, and patterns.
3. **Reference existing mockups**: Use `get_screenshot` to capture relevant existing screens for reference.
4. **Document design decisions**: Create a design brief that includes:
   - Affected screens/pages
   - New components needed
   - Existing components to reuse
   - Interaction patterns
   - Responsive breakpoints
   - Accessibility requirements

### 3. Design Deliverables

Produce:
- A written design spec with component breakdown
- References to existing Figma components where applicable
- Screenshots of relevant existing designs for context
- Wireframe descriptions for new UI elements
- Notes on animations/transitions if applicable

### 4. Post to GitHub

Post the design summary as a GitHub comment on the issue:

```markdown
## 🎨 Design Phase

### Affected Screens
- [list of screens]

### Component Breakdown
| Component | Status | Notes |
|-----------|--------|-------|
| ... | New / Existing | ... |

### Design Decisions
[Key decisions and rationale]

### Figma References
[Links to relevant Figma frames/pages]

### Accessibility Notes
[A11y considerations]
```

## Notes

- Always check for existing components before designing new ones.
- Follow the team's design system tokens and patterns.
- Consider both desktop and mobile layouts for responsive designs.
- Flag any design system gaps that should be addressed.
