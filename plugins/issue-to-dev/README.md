# Issue-to-Dev Pipeline

Automate the full lifecycle from GitHub issue to pull request, with multi-perspective review, design generation, feasibility checks, and two human approval gates.

## Overview

```
GitHub Issue
     │
     ▼
Multi-Angle Review (PM + Tech Lead + UX)
     │
     ▼
Design Phase (Figma) ◄── optional
     │
     ▼
FE Feasibility Review
     │
     ▼
🚦 APPROVAL GATE 1 ── team approves via /approve on GitHub
     │
     ▼
Development (FE + BE) → Code Review
     │
     ▼
Auto PR + Summary
     │
     ▼
🚦 APPROVAL GATE 2 ── team reviews PR and merges manually
```

## Two Approval Gates

### Gate 1: Implementation Plan (GitHub Issue)
After all reviews complete, the pipeline posts a consolidated implementation plan on the issue and waits. Team members comment `/approve` to greenlight development. You can require multiple approvers.

### Gate 2: PR Merge (GitHub PR)
After the PR is created, it includes a detailed change summary, testing instructions, and deployment notes. The team reviews and merges at their discretion — no automation needed.

## Components

### Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `issue-pipeline` | "process this issue", "run the pipeline" | Full end-to-end orchestration |
| `multi-angle-review` | "review this issue", "analyze this feature" | PM + Tech Lead + UX review |
| `design-mockup` | "create a design", "make a mockup" | Figma-based design generation |
| `fe-feasibility` | "check FE feasibility", "estimate frontend work" | Component check + effort estimate |
| `check-approvals` | "check approvals", "any approved issues" | Detect /approve comments on GitHub |
| `development` | "start development", "implement this" | Implementation + code review + PR |

### Agents

| Agent | Role | Focus |
|-------|------|-------|
| `pm-reviewer` | Product Manager | Business value, priority, success metrics |
| `tech-lead-reviewer` | Tech Lead | Feasibility, architecture, scope estimation |
| `ux-reviewer` | UX/Design | User experience, accessibility, design needs |
| `code-reviewer` | Code Reviewer | Quality, performance, security, test coverage |

### MCP Servers

| Server | Purpose |
|--------|---------|
| GitHub | Issue reading, PR creation, comment posting |

## Label Convention

| Label | Meaning |
|-------|---------|
| `status:triaging` | Pipeline is analyzing the issue |
| `status:reviewed` | Review complete |
| `status:awaiting-approval` | Waiting for `/approve` comments |
| `status:approved` | Approved, development starting |
| `status:in-development` | Currently being implemented |
| `status:pending-merge` | PR created, waiting for human merge |

## Usage

### Full Pipeline
> "Run the pipeline for https://github.com/org/repo/issues/42"

### Check Approvals
> "Check if any issues have been approved"

### Individual Skills
> "Review issue #42 from all angles"
> "Create a design mockup for issue #42"
> "Start development on issue #42"

## Tech Stack

- **Frontend**: React + TypeScript
- **Design**: Figma (via Figma MCP)
- **Source Control**: GitHub (via GitHub MCP)

## Setup

1. Install the plugin in Claude
2. Ensure GitHub MCP is connected
3. Ensure Figma MCP is connected for design features
4. Create the status labels in your GitHub repo (optional but recommended)
