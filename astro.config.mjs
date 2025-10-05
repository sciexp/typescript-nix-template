// @ts-check

import cloudflare from "@astrojs/cloudflare";
import starlight from "@astrojs/starlight";
import { defineConfig } from "astro/config";
import * as vite from "vite";

// https://astro.build/config
export default defineConfig({
  integrations: [
    starlight({
      title: "My Docs",
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

  vite: {
    // Fix for rolldown-vite compatibility with Cloudflare Workers
    // https://github.com/cloudflare/workers-sdk/pull/9891
    ...("rolldownVersion" in vite
      ? {
          optimizeDeps: {
            esbuildOptions: {
              platform: "neutral",
            },
          },
        }
      : {}),
  },
});
