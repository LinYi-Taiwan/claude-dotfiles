---
name: playwright-qa
description: >
  Live UI verification using Playwright MCP browser tools. Use this skill proactively whenever the user wants to
  visually verify, QA, or smoke-test a running web application — NOT for writing test code files. Trigger when
  the user says things like "verify the UI", "check this page", "QA this", "self-QA", "smoke test", "open the
  browser and test", "看看頁面", "驗一下", "驗證 UI", "看看畫面", or after implementing UI changes and wanting
  to confirm they work in a real browser. Also trigger when you finish implementing a UI feature and want to
  self-verify before reporting completion. Do NOT trigger for writing .spec.ts test files — that's the
  playwright-best-practices skill.
---

# Playwright QA — Live Browser Verification

This skill drives a real browser via Playwright MCP tools to verify UI behavior. You interact with the running app the way a QA engineer would — navigate, click, fill forms, read the page — then report what you found.

**This is NOT for writing test code.** You call MCP tools directly to operate the browser.

## Workflow

### 1. Determine the target

Figure out what to verify and where:

- **User provides a URL** → use it directly
- **User describes a feature** → read project config (`package.json` scripts, `vite.config`, `next.config`, `.env`) to infer `baseURL`, then navigate to the relevant route
- **Spec file exists** (`.specify/spec.md` or similar) → read it to understand the expected user journeys

If you can't determine the URL, ask the user.

### 2. Verify the server is running

Call `browser_navigate` to the target URL. If the page fails to load, tell the user to start their dev server and suggest the likely command (e.g., `npm run dev`).

### 3. Understand the page

After navigation, immediately call `browser_snapshot` to get the accessibility tree. This is your primary way to "see" the page — it tells you every interactive element, its role, name, and state.

Use `browser_take_screenshot` when you need visual context (layout, styling, colors) that the accessibility tree can't convey. **Always pass `type: "jpeg"`, `quality: 70`, and keep `fullPage: false`** — the default PNG full-page screenshot can consume 300k+ tokens, while a viewport JPEG at q70 is typically 40–60k. For element-level checks, pass an `element`/`ref` from the latest snapshot instead of shooting the whole viewport.

### 4. Execute verification

Walk through the user journeys. For each step:

1. **Act** — use the appropriate tool (`browser_click`, `browser_type`, `browser_fill_form`, `browser_select_option`, `browser_press_key`, `browser_hover`)
2. **Observe** — call `browser_snapshot` after each action to verify the page state changed as expected
3. **Record** — note PASS/FAIL and any observations

**After completing all interactions**, call `browser_console_messages` to check for JavaScript errors or warnings that appeared during the session.

### 5. Report results

Output a QA results table:

```
## Playwright QA Results

**Target:** [URL]
**Timestamp:** [date/time]

| # | Verification Item | Result | Notes |
|---|------------------|--------|-------|
| 1 | Page renders without errors | PASS | No console errors |
| 2 | [user journey step] | PASS/FAIL | [details] |
| 3 | [user journey step] | PASS/FAIL | [details] |
| ... | ... | ... | ... |

**Console errors:** [none / list them]
**Screenshots:** [list paths if taken]
```

For FAIL items, describe:
- What you expected to see
- What actually happened
- Steps to reproduce

## Tool Reference

These are the Playwright MCP tools available to you. Call them directly — they operate a real browser.

### Navigation
| Tool | What it does |
|------|-------------|
| `browser_navigate` | Go to a URL |
| `browser_navigate_back` | Go back in history |
| `browser_tabs` | List, create, close, or switch tabs |

### Perception
| Tool | What it does |
|------|-------------|
| `browser_snapshot` | Get accessibility tree (primary perception — use this after every action) |
| `browser_take_screenshot` | Capture visual screenshot — **always `type: "jpeg", quality: 70`, viewport-only** (see §3) |
| `browser_console_messages` | Get all console log/warn/error messages |

### Interaction
| Tool | What it does |
|------|-------------|
| `browser_click` | Click an element (by ref from snapshot) |
| `browser_type` | Type text into a focused/editable element |
| `browser_fill_form` | Fill multiple form fields at once |
| `browser_select_option` | Select dropdown option |
| `browser_hover` | Hover over an element |
| `browser_press_key` | Press a keyboard key (Enter, Escape, Tab, etc.) |
| `browser_drag` | Drag and drop between elements |
| `browser_file_upload` | Upload files to a file input |

### Waiting
| Tool | What it does |
|------|-------------|
| `browser_wait_for` | Wait for text to appear/disappear or a timeout |

### Assertion
| Tool | What it does |
|------|-------------|
| `browser_verify_text_visible` | Assert text is visible on page |
| `browser_verify_element_visible` | Assert element is visible |
| `browser_verify_value` | Assert element has expected value |

### Cleanup
| Tool | What it does |
|------|-------------|
| `browser_close` | Close the browser page |

## Principles

- **Snapshot after every action.** The accessibility tree is how you know what happened. Never assume an action succeeded — verify with `browser_snapshot`.
- **Check console errors.** Many UI bugs manifest as JS errors before they show visually. Always call `browser_console_messages` at the end.
- **Be systematic.** Walk through flows in order — don't skip around randomly. Start from the entry point and follow the user journey.
- **Report honestly.** If something looks wrong, report it. If you're unsure, take a screenshot and describe what you see.
- **Don't write test files.** This skill is for live verification. If the user needs repeatable test code, point them to the `playwright-best-practices` skill instead.
