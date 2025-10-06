// @ts-check

import cloudflare from "@astrojs/cloudflare";
import starlight from "@astrojs/starlight";
import { defineConfig } from "astro/config";
// ROLLDOWN INTEGRATION (DISABLED) - Uncomment when re-enabling (see ROLLDOWN.md)
// import * as vite from "vite";

// https://astro.build/config
export default defineConfig({
  integrations: [
    starlight({
      title: "My Docs",
      prerender: false,
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/withastro/starlight",
        },
      ],
      sidebar: [
        {
          label: "Guides",
          items: [
            // Each item here is one entry in the navigation menu.
            { label: "Example Guide", slug: "guides/example" },
          ],
        },
        {
          label: "Reference",
          autogenerate: { directory: "reference" },
        },
      ],
    }),
  ],

  adapter: cloudflare({
    platformProxy: {
      enabled: true,
    },

    imageService: "cloudflare",
  }),

  /* ROLLDOWN INTEGRATION (DISABLED - Cloudflare Workers Incompatibility)
   *
   * Status: Disabled due to runtime error in Cloudflare Workers
   * Issue: https://github.com/cloudflare/workers-sdk/issues/9415
   * Fix PR: https://github.com/cloudflare/workers-sdk/pull/9891
   *
   * Problem: Rolldown generates createRequire(import.meta.url) which fails
   * in Cloudflare Workers where import.meta.url is undefined.
   *
   * The fix (platform: "neutral") only works with @cloudflare/vite-plugin,
   * not with @astrojs/cloudflare adapter used in this project.
   *
   * TO RE-ENABLE (when compatibility is resolved):
   * 1. Uncomment the vite import above
   * 2. Add to package.json devDependencies:
   *    "vite": "npm:rolldown-vite@latest"
   * 3. Add to package.json root:
   *    "overrides": { "vite": "npm:rolldown-vite@latest" }
   * 4. Run: bun install
   * 5. Uncomment the vite config below
   * 6. Test: bun run build && bun run preview
   *
   * See ROLLDOWN.md for complete documentation and alternative approaches.
   */

  // vite: {
  //   // Attempted fix for rolldown-vite + Cloudflare Workers compatibility
  //   // https://github.com/cloudflare/workers-sdk/pull/9891
  //   ...("rolldownVersion" in vite
  //     ? {
  //         optimizeDeps: {
  //           esbuildOptions: {
  //             platform: "neutral",
  //           },
  //         },
  //       }
  //     : {}),
  // },
});
