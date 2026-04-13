# ARIA Snapshot Testing Reference

## YAML Syntax

ARIA snapshots describe the accessibility tree using a YAML-like format. Each line represents an accessible node with its role and name.

### Basic Format

```yaml
- role "accessible name"
- role "accessible name":
    - child-role "child name"
```

### Common Roles

```yaml
- heading "Page Title" [level=1]
- navigation:
    - link "Home"
    - link "About"
- main:
    - heading "Content" [level=2]
    - paragraph: "Some text content"
- form:
    - textbox "Email"
    - textbox "Password"
    - button "Sign in"
- list:
    - listitem: "Item one"
    - listitem: "Item two"
- table:
    - rowgroup:
        - row:
            - columnheader "Name"
            - columnheader "Status"
    - rowgroup:
        - row:
            - cell "Alice"
            - cell "Active"
```

## Partial Matching

ARIA snapshots use **partial matching by default** — your template only needs to include the nodes you care about. Extra nodes in the actual tree are ignored.

```ts
// Page has nav, main, footer — but we only assert nav structure
await expect(page.locator('body')).toMatchAriaSnapshot(`
  - navigation:
    - link "Home"
    - link "Products"
`);
// Passes even though main and footer exist but aren't mentioned
```

### Matching Text Content

```yaml
# Exact match
- heading "Dashboard"

# Regex match
- heading: /Dashboard.*/

# Text node (no role)
- text: "Welcome back"
- text: /Hello, .+/
```

### Matching Attributes

```yaml
# Level attribute for headings
- heading "Title" [level=1]

# Checked state
- checkbox "Remember me" [checked]
- checkbox "Newsletter" [checked=false]

# Expanded/collapsed
- button "Menu" [expanded=true]
- button "Details" [expanded=false]

# Disabled state
- button "Submit" [disabled]
```

## Scoping Snapshots

Always scope to a specific locator rather than the full page — it's faster, more stable, and easier to maintain:

```ts
// Good — scoped to a specific region
await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
  - link "Home"
  - link "Products"
`);

// Avoid — full page snapshots are fragile and slow
await expect(page.locator('body')).toMatchAriaSnapshot(`...`);
```

## Generating Snapshots

### Via Codegen

```bash
npx playwright codegen --save-aria-snapshot
```

In the codegen UI, click "Assert snapshot" to capture the accessibility tree of any element. The generated YAML is pasted into your test automatically.

### Via Test Runner (update mode)

```bash
# Generate/update snapshots inline in test files
npx playwright test --update-snapshots
```

This replaces the YAML template in `toMatchAriaSnapshot()` with the actual tree from the running app.

### Via API (programmatic)

```ts
// Get the raw snapshot for debugging
const snapshot = await page.getByRole('main').ariaSnapshot();
console.log(snapshot);
```

## Combining with Visual Regression

ARIA snapshots and visual screenshots test different things — use both:

```ts
test('product card renders correctly', async ({ page }) => {
  await page.goto('/products');
  const card = page.getByRole('article').first();

  // Structure and accessibility
  await expect(card).toMatchAriaSnapshot(`
    - img "Product photo"
    - heading "Product Name" [level=3]
    - text: /\$[\d.]+/
    - button "Add to cart"
  `);

  // Visual appearance
  await expect(card).toHaveScreenshot('product-card.png');
});
```

| Assertion | Catches |
|-----------|---------|
| `toMatchAriaSnapshot()` | Missing elements, broken hierarchy, accessibility regressions, wrong text |
| `toHaveScreenshot()` | Visual regressions, spacing changes, color changes, layout shifts |

## Common Patterns

### Form Validation

```ts
await page.getByRole('button', { name: 'Submit' }).click();

await expect(page.getByRole('form')).toMatchAriaSnapshot(`
  - textbox "Email" [invalid]
  - text: "Email is required"
  - button "Submit"
`);
```

### Dynamic Lists

```ts
await expect(page.getByRole('list')).toMatchAriaSnapshot(`
  - listitem:
    - text: /Item \d+/
    - button "Delete"
`);
```

### Dialog/Modal

```ts
await page.getByRole('button', { name: 'Delete' }).click();

await expect(page.getByRole('dialog')).toMatchAriaSnapshot(`
  - heading "Confirm Delete" [level=2]
  - text: "Are you sure?"
  - button "Cancel"
  - button "Delete"
`);
```
