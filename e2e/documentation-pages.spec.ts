import { expect, test } from "@playwright/test";

test.describe("Documentation Pages", () => {
  test("has sidebar navigation on example guide page", async ({ page }) => {
    await page.goto("/guides/example/");

    // Verify sidebar navigation exists
    const sidebar = page.locator('nav[aria-label="Main"]');
    await expect(sidebar).toBeVisible();
  });

  test("sidebar contains configured navigation items", async ({ page }) => {
    await page.goto("/guides/example/");

    // Verify sidebar contains the Guides section
    const sidebar = page.locator('nav[aria-label="Main"]');
    await expect(sidebar.getByText("Guides")).toBeVisible();
    await expect(sidebar.getByText("Example Guide")).toBeVisible();
  });

  test("has table of contents on desktop", async ({ page }) => {
    await page.goto("/guides/example/");

    // Verify right sidebar with table of contents exists
    const toc = page.getByRole("navigation", { name: /on this page/i });
    await expect(toc).toBeVisible();
  });
});
