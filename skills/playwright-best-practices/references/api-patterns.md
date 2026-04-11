# Playwright API Patterns Reference

## Locator Methods

### By Role (preferred)
```ts
page.getByRole('button', { name: 'Submit' })
page.getByRole('link', { name: /learn more/i })
page.getByRole('heading', { level: 2 })
page.getByRole('textbox', { name: 'Email' })
page.getByRole('checkbox', { name: 'Agree', checked: true })
page.getByRole('combobox', { name: 'Country' })
page.getByRole('tab', { name: 'Settings', selected: true })
page.getByRole('row', { name: 'Alice' })
page.getByRole('cell', { name: '$100' })
page.getByRole('dialog')
page.getByRole('alert')
page.getByRole('navigation')
```

### By Text / Label
```ts
page.getByText('Welcome')
page.getByText(/total: \$\d+/i)
page.getByLabel('Email address')
page.getByPlaceholder('Search...')
page.getByAltText('Company logo')
page.getByTitle('Close dialog')
page.getByTestId('sidebar-nav')
```

### Chaining and Filtering
```ts
// Filter by text content
page.getByRole('listitem').filter({ hasText: 'Apple' })

// Filter by child locator
page.getByRole('listitem').filter({
  has: page.getByRole('button', { name: 'Buy' })
})

// Filter by NOT having something
page.getByRole('listitem').filter({
  hasNot: page.getByText('Out of stock')
})

// Chain into children
page.getByRole('article')
  .filter({ hasText: 'Playwright' })
  .getByRole('link', { name: 'Read more' })

// nth element (0-indexed)
page.getByRole('listitem').nth(2)
page.getByRole('listitem').first()
page.getByRole('listitem').last()
```

## Assertions

### Page assertions
```ts
await expect(page).toHaveTitle('Dashboard')
await expect(page).toHaveTitle(/dashboard/i)
await expect(page).toHaveURL('https://example.com/dashboard')
await expect(page).toHaveURL(/\/dashboard/)
```

### Element assertions
```ts
await expect(locator).toBeVisible()
await expect(locator).toBeHidden()
await expect(locator).toBeEnabled()
await expect(locator).toBeDisabled()
await expect(locator).toBeChecked()
await expect(locator).toBeEditable()
await expect(locator).toBeFocused()
await expect(locator).toBeEmpty()
await expect(locator).toBeAttached()

await expect(locator).toHaveText('Hello')
await expect(locator).toHaveText(/hello/i)
await expect(locator).toContainText('partial')
await expect(locator).toHaveValue('test@example.com')
await expect(locator).toHaveAttribute('href', '/about')
await expect(locator).toHaveClass(/active/)
await expect(locator).toHaveCSS('color', 'rgb(0, 0, 0)')
await expect(locator).toHaveCount(5)
await expect(locator).toHaveId('main-content')
```

### Negation
```ts
await expect(locator).not.toBeVisible()
await expect(locator).not.toHaveText('Error')
```

### Snapshot assertions
```ts
await expect(locator).toHaveScreenshot('card.png')
await expect(page).toHaveScreenshot('full-page.png', { fullPage: true })
```

## Actions

### Click
```ts
await locator.click()
await locator.click({ button: 'right' })
await locator.click({ modifiers: ['Meta'] })  // Cmd+click
await locator.click({ position: { x: 10, y: 10 } })
await locator.dblclick()
await locator.click({ force: true })  // Skip actionability checks
```

### Type / Fill
```ts
await locator.fill('Hello')        // Clear + set value (fast)
await locator.pressSequentially('Hello', { delay: 50 })  // Key-by-key
await locator.clear()
await locator.press('Enter')
await locator.press('Control+a')
```

### Select
```ts
await locator.selectOption('blue')
await locator.selectOption({ label: 'Blue' })
await locator.selectOption(['red', 'green'])
```

### Check / Uncheck
```ts
await locator.check()
await locator.uncheck()
await locator.setChecked(true)
```

### File upload
```ts
await locator.setInputFiles('file.pdf')
await locator.setInputFiles(['file1.pdf', 'file2.pdf'])
await locator.setInputFiles([])  // Clear
```

### Drag and drop
```ts
await source.dragTo(target)
```

### Hover
```ts
await locator.hover()
```

## Network

### Intercept and mock
```ts
await page.route('**/api/users', route =>
  route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify([{ id: 1, name: 'Alice' }]),
  })
);
```

### Modify request
```ts
await page.route('**/api/data', route =>
  route.continue({
    headers: { ...route.request().headers(), 'X-Custom': 'value' },
  })
);
```

### Wait for response
```ts
const responsePromise = page.waitForResponse('**/api/submit');
await page.getByRole('button', { name: 'Submit' }).click();
const response = await responsePromise;
expect(response.status()).toBe(200);
```

### Abort requests
```ts
// Block images and fonts for faster tests
await page.route('**/*.{png,jpg,jpeg,gif,svg,woff2}', route => route.abort());
```

## Frame handling
```ts
const frame = page.frameLocator('#my-iframe');
await frame.getByRole('button', { name: 'Click me' }).click();
```

## Dialog handling
```ts
page.on('dialog', dialog => dialog.accept('confirmed'));
await page.getByRole('button', { name: 'Delete' }).click();
```

## Multiple pages / tabs
```ts
const pagePromise = context.waitForEvent('page');
await page.getByRole('link', { name: 'Open in new tab' }).click();
const newPage = await pagePromise;
await newPage.waitForLoadState();
```
