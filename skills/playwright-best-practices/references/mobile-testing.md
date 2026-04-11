# Mobile and Responsive Testing

## Device Emulation

Playwright ships with a device registry. Use it in config or per-test:

```ts
// playwright.config.ts — test on multiple devices
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  projects: [
    { name: 'Desktop Chrome', use: { ...devices['Desktop Chrome'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 7'] } },
    { name: 'Mobile Safari', use: { ...devices['iPhone 14'] } },
    { name: 'Tablet', use: { ...devices['iPad Pro 11'] } },
  ],
});
```

## Per-Test Viewport Override

```ts
test('responsive sidebar collapses on mobile', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto('/dashboard');
  await expect(page.getByRole('navigation')).toBeHidden();
  await page.getByRole('button', { name: 'Menu' }).click();
  await expect(page.getByRole('navigation')).toBeVisible();
});
```

## Touch Events

Device emulation automatically enables touch. For explicit touch:

```ts
test('swipe to delete', async ({ page }) => {
  const item = page.getByRole('listitem').first();
  await item.dispatchEvent('touchstart', { touches: [{ clientX: 300, clientY: 200 }] });
  await item.dispatchEvent('touchend', { touches: [{ clientX: 50, clientY: 200 }] });
});
```

## Geolocation and Permissions

```ts
// playwright.config.ts
use: {
  geolocation: { latitude: 25.033, longitude: 121.565 },
  permissions: ['geolocation'],
}
```

```ts
// Per-test override
test('shows nearby stores', async ({ context, page }) => {
  await context.grantPermissions(['geolocation']);
  await context.setGeolocation({ latitude: 25.033, longitude: 121.565 });
  await page.goto('/stores');
  await expect(page.getByText('Taipei 101 Store')).toBeVisible();
});
```

## Color Scheme

```ts
// Dark mode testing
use: {
  colorScheme: 'dark',
}

// Per-test
test('dark mode renders correctly', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'dark' });
  await page.goto('/settings');
  await expect(page.locator('body')).toHaveCSS('background-color', 'rgb(18, 18, 18)');
});
```

## Offline Mode

```ts
test('shows offline banner', async ({ context, page }) => {
  await page.goto('/dashboard');
  await context.setOffline(true);
  await expect(page.getByText('You are offline')).toBeVisible();
  await context.setOffline(false);
  await expect(page.getByText('You are offline')).toBeHidden();
});
```

## Visual Regression on Multiple Viewports

```ts
const viewports = [
  { width: 375, height: 812, name: 'mobile' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 1440, height: 900, name: 'desktop' },
];

for (const vp of viewports) {
  test(`homepage renders correctly on ${vp.name}`, async ({ page }) => {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto('/');
    await expect(page).toHaveScreenshot(`homepage-${vp.name}.png`);
  });
}
```
