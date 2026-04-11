---
name: playwright-best-practices
description: >
  Playwright testing best practices and patterns for writing reliable, maintainable E2E and component tests.
  Use this skill whenever the user is writing, reviewing, or refactoring Playwright tests, setting up Playwright
  configuration, debugging flaky tests, or asking about test patterns with Playwright. Also trigger when you see
  imports from @playwright/test, playwright.config.ts files, or .spec.ts/.test.ts files that use Playwright APIs.
---

# Playwright Best Practices

This skill guides you to write production-grade Playwright tests that are reliable, fast, and maintainable. The principles here reflect Playwright's official recommendations and real-world patterns from large test suites.

## Core Philosophy

Playwright tests should mirror how real users interact with your application. Every test should answer: "Does this user journey work?" — not "Does this implementation detail exist?"

## Locator Strategy

Locators are the foundation of reliable tests. Use them in this priority order:

**Tier 1 — Role-based (strongly preferred)**
```ts
page.getByRole('button', { name: 'Submit' })
page.getByRole('heading', { name: 'Dashboard' })
page.getByRole('link', { name: 'Sign out' })
page.getByRole('textbox', { name: 'Email' })
page.getByRole('checkbox', { name: 'Remember me' })
```
Role locators reflect how assistive technologies and users perceive the page. They naturally break when accessibility regresses — a useful side effect.

**Tier 2 — Text and label**
```ts
page.getByLabel('Password')
page.getByPlaceholder('Search...')
page.getByText('Welcome back')
```

**Tier 3 — Test ID (when semantic locators aren't feasible)**
```ts
page.getByTestId('nav-sidebar')
```
Use `data-testid` only for elements with no accessible role or unique text (complex widgets, canvas containers, dynamic lists).

**Never use these in tests:**
```ts
// Fragile — breaks on any markup or styling change
page.locator('.btn-primary')
page.locator('#submit-form')
page.locator('div > span:nth-child(2)')
page.locator('[class*="header"]')
```

**Chaining and filtering** — narrow scope instead of writing complex selectors:
```ts
const product = page.getByRole('listitem').filter({ hasText: 'Product 2' });
await product.getByRole('button', { name: 'Add to cart' }).click();
```

## Assertions

Use web-first assertions — they auto-retry until the condition is met or timeout expires.

```ts
// Correct — auto-retries
await expect(page.getByText('Order confirmed')).toBeVisible();
await expect(page.getByRole('heading')).toHaveText('Dashboard');
await expect(page).toHaveURL(/\/dashboard/);
await expect(page).toHaveTitle('My App');

// Wrong — evaluates once, race condition
expect(await page.getByText('Order confirmed').isVisible()).toBe(true);
```

**Soft assertions** — continue after failure to collect multiple issues:
```ts
await expect.soft(page.getByTestId('status')).toHaveText('Success');
await expect.soft(page.getByTestId('count')).toHaveText('3');
// Test continues; all failures reported at the end
```

**Negative assertions:**
```ts
await expect(page.getByRole('dialog')).not.toBeVisible();
await expect(page.getByText('Error')).toBeHidden();
```

## Waiting Strategy

Playwright auto-waits for elements to be actionable before interacting. Trust it.

```ts
// Never do this
await page.waitForTimeout(2000);
await page.click('.btn');

// Just do this — Playwright waits automatically
await page.getByRole('button', { name: 'Save' }).click();
```

For network-dependent UI, wait for the specific condition:
```ts
// Wait for API response before asserting
await page.getByRole('button', { name: 'Load' }).click();
await expect(page.getByRole('table')).toBeVisible();

// Or wait for a specific network request
const responsePromise = page.waitForResponse('**/api/data');
await page.getByRole('button', { name: 'Load' }).click();
await responsePromise;
```

**Never use arbitrary sleeps.** If you think you need `waitForTimeout`, you're missing a proper wait condition.

## Test Structure

### Isolation

Each test runs independently — no shared state, no execution order dependencies.

```ts
test.describe('checkout flow', () => {
  test.beforeEach(async ({ page }) => {
    // Set up fresh state for each test
    await page.goto('/shop');
  });

  test('add item to cart', async ({ page }) => {
    await page.getByRole('button', { name: 'Add to cart' }).click();
    await expect(page.getByTestId('cart-count')).toHaveText('1');
  });

  test('remove item from cart', async ({ page }) => {
    // Don't depend on the previous test — set up your own state
    await page.getByRole('button', { name: 'Add to cart' }).click();
    await page.getByRole('button', { name: 'Remove' }).click();
    await expect(page.getByTestId('cart-count')).toHaveText('0');
  });
});
```

### Naming

Test names should describe the user's intent and expected outcome:
```ts
// Good
test('user can reset password via email link', ...)
test('displays validation error for invalid email format', ...)

// Bad
test('test1', ...)
test('password reset', ...)
test('should work', ...)
```

### Grouping

Use `test.describe` to group related scenarios. Keep test files focused on a single feature or page.

```
tests/
  auth/
    login.spec.ts
    signup.spec.ts
    password-reset.spec.ts
  checkout/
    cart.spec.ts
    payment.spec.ts
```

## Authentication

Don't log in via the UI in every test — it's slow and fragile. Use `storageState` to reuse authentication:

```ts
// auth.setup.ts — runs once before all tests
import { test as setup } from '@playwright/test';

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('/dashboard');
  await page.context().storageState({ path: '.auth/user.json' });
});
```

```ts
// playwright.config.ts
export default defineConfig({
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'chromium',
      dependencies: ['setup'],
      use: { storageState: '.auth/user.json' },
    },
  ],
});
```

## Network Mocking

Test your app's integration behavior, not third-party services:

```ts
await page.route('**/api/external-service', route =>
  route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ data: 'mocked' }),
  })
);
```

Mock at the network boundary to test error handling:
```ts
test('shows error state on API failure', async ({ page }) => {
  await page.route('**/api/data', route =>
    route.fulfill({ status: 500, body: 'Internal Server Error' })
  );
  await page.goto('/dashboard');
  await expect(page.getByText('Something went wrong')).toBeVisible();
});
```

## Fixtures and Page Objects

For complex pages, extract interactions into fixtures or page object-style helpers:

```ts
// fixtures.ts
import { test as base } from '@playwright/test';

type Fixtures = {
  dashboardPage: DashboardPage;
};

class DashboardPage {
  constructor(private page: Page) {}

  async navigate() {
    await this.page.goto('/dashboard');
  }

  async createWidget(name: string) {
    await this.page.getByRole('button', { name: 'New Widget' }).click();
    await this.page.getByLabel('Name').fill(name);
    await this.page.getByRole('button', { name: 'Create' }).click();
  }

  widgetCard(name: string) {
    return this.page.getByRole('article').filter({ hasText: name });
  }
}

export const test = base.extend<Fixtures>({
  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page));
  },
});
```

Use fixtures when the same setup or page interactions repeat across 3+ tests. Don't create them preemptively for single-use flows.

## Configuration

A solid `playwright.config.ts` baseline:

```ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? 'html' : 'list',

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

**Key settings explained:**
- `fullyParallel` — run tests across files and within files in parallel
- `forbidOnly` — fail CI if `test.only` is left in code
- `retries: 2` on CI — catch genuine flakes without masking real failures
- `trace: 'on-first-retry'` — capture trace only when a test fails and retries, keeping CI fast
- `webServer` — auto-start your dev server before tests

## Debugging

**Local:**
```bash
# Debug a specific test with inspector
npx playwright test login.spec.ts --debug

# Run with UI mode for time-travel debugging
npx playwright test --ui
```

**CI — use traces, not screenshots:**
```bash
npx playwright test --trace on
npx playwright show-report
```

Trace viewer shows DOM snapshots, network requests, and console logs at each step — far more useful than a static screenshot.

## Flaky Test Prevention

Flaky tests erode trust. Common causes and fixes:

| Symptom | Cause | Fix |
|---------|-------|-----|
| Element not found | Race condition | Use auto-waiting locators, not `waitForTimeout` |
| Wrong element clicked | Ambiguous locator | Make locator more specific with chaining/filtering |
| Intermittent timeout | Slow API/render | Wait for specific condition, not arbitrary time |
| State leaks between tests | Shared data | Ensure test isolation via `beforeEach` setup |
| Different results per browser | Browser quirks | Use `test.skip` with condition for known issues |

## Anti-Patterns to Avoid

1. **Arbitrary waits** — `waitForTimeout(3000)` is never the answer
2. **CSS/XPath selectors** — fragile, break on refactors, convey no semantic meaning
3. **Test interdependence** — test B should never rely on test A running first
4. **Testing third-party services** — mock external APIs at the network level
5. **Manual assertions** — use `expect()` with auto-retry, not boolean checks
6. **Over-mocking** — mock at boundaries, not internal app logic
7. **Ignoring trace viewer** — always use traces over screenshots for debugging CI failures
8. **Giant test files** — split by feature, keep each file focused
9. **Hardcoded waits for animations** — use `page.getByRole(...).click({ force: true })` or disable animations in test config

## CI Integration

For GitHub Actions, see `references/ci-config.md` for a production-ready workflow configuration.

## Further Reading

- For the full Playwright API locator and assertion reference, see `references/api-patterns.md`
- For mobile and responsive testing patterns, see `references/mobile-testing.md`
