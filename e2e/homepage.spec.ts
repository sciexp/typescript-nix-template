import { expect, test } from "@playwright/test";

test.describe("Homepage", () => {
  test("has correct title and heading", async ({ page }) => {
    await page.goto("/");

    // Verify page title
    await expect(page).toHaveTitle(/My Docs/);

    // Verify main heading
    const heading = page.locator("h1").first();
    await expect(heading).toBeVisible();
  });

  test("has navigation sidebar", async ({ page }) => {
    await page.goto("/");

    // Verify sidebar navigation exists
    const sidebar = page.locator("nav").first();
    await expect(sidebar).toBeVisible();
  });

  test("has accessible links", async ({ page }) => {
    await page.goto("/");

    // Verify GitHub link exists and is accessible
    const githubLink = page.getByRole("link", { name: /github/i });
    await expect(githubLink).toBeVisible();
    await expect(githubLink).toHaveAttribute("href", /.+/);
  });

  test("navigates to example guide", async ({ page }) => {
    await page.goto("/");

    // Find and click the Example Guide link
    const guideLink = page.getByRole("link", { name: /example guide/i });
    await guideLink.click();

    // Verify navigation occurred
    await expect(page).toHaveURL(/\/guides\/example/);
  });

  test("is responsive on mobile", async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto("/");

    // Page should still be functional
    await expect(page.locator("h1").first()).toBeVisible();
  });

  test("loads without console errors", async ({ page }) => {
    const errors: string[] = [];

    page.on("console", (msg) => {
      if (msg.type() === "error") {
        errors.push(msg.text());
      }
    });

    await page.goto("/");

    // Wait for page to fully load
    await page.waitForLoadState("networkidle");

    // Check for console errors
    expect(errors).toHaveLength(0);
  });
});
