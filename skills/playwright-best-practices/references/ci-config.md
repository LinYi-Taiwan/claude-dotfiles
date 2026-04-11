# CI Configuration for Playwright

## GitHub Actions

```yaml
name: Playwright Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    timeout-minutes: 15
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install chromium --with-deps

      - name: Run Playwright tests
        run: npx playwright test
        env:
          CI: true

      - uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 14

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-traces
          path: test-results/
          retention-days: 7
```

### Optimization tips

**Install only needed browsers** — don't install all three on CI unless you actually test cross-browser:
```bash
npx playwright install chromium --with-deps
```

**Shard across machines** for large suites:
```yaml
strategy:
  matrix:
    shard: [1/3, 2/3, 3/3]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}
```

**Cache browser binaries** to speed up installs:
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/ms-playwright
    key: playwright-${{ hashFiles('package-lock.json') }}
```

**Merge shard reports** into a single HTML report:
```yaml
# After all shards complete
- run: npx playwright merge-reports --reporter html ./all-blob-reports
```

## Container-based CI

If using Docker or other container runtimes:

```dockerfile
FROM mcr.microsoft.com/playwright:v1.52.0-noble
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
CMD ["npx", "playwright", "test"]
```

The official Playwright Docker image includes all browsers and system dependencies pre-installed.
