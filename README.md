# Starlight Starter Kit: Basics

[![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

```
bun create astro@latest -- --template starlight
```

> 🧑‍🚀 **Seasoned astronaut?** Delete this file. Have fun!

## 🚀 Project Structure

Inside of your Astro + Starlight project, you'll see the following folders and files:

```
.
├── public/
├── src/
│   ├── assets/
│   ├── content/
│   │   └── docs/
│   └── content.config.ts
├── astro.config.mjs
├── package.json
└── tsconfig.json
```

Starlight looks for `.md` or `.mdx` files in the `src/content/docs/` directory. Each file is exposed as a route based on its file name.

Images can be added to `src/assets/` and embedded in Markdown with a relative link.

Static assets, like favicons, can be placed in the `public/` directory.

## 🧞 Commands

All commands are run from the root of the project, from a terminal:

| Command               | Action                                           |
| :-------------------- | :----------------------------------------------- |
| `bun install`         | Installs dependencies                            |
| `bun dev`             | Starts local dev server at `localhost:4321`      |
| `bun build`           | Build your production site to `./dist/`          |
| `bun preview`         | Preview your build locally, before deploying     |
| `bun astro ...`       | Run CLI commands like `astro add`, `astro check` |
| `bun astro -- --help` | Get help using the Astro CLI                     |

## 🧪 Testing

This project includes comprehensive testing with Vitest and Playwright.

| Command                 | Action                                    |
| :---------------------- | :---------------------------------------- |
| `just test`             | Run all tests (unit + E2E)                |
| `just test-unit`        | Run unit tests with Vitest                |
| `just test-e2e`         | Run E2E tests with Playwright             |
| `just test-watch`       | Run Vitest in watch mode                  |
| `just test-ui`          | Run Playwright in UI mode                 |
| `just test-coverage`    | Generate test coverage report             |

### Nix-Based Playwright Setup

This template uses Nix to provide Playwright browser binaries for reproducible testing.
Browsers are automatically available in the `nix develop` shell via `playwright-driver.browsers`.

**No browser installation needed** - when you run `just test-e2e`, Playwright uses the Nix-provided browsers from `/nix/store`.

This approach ensures:
- Deterministic browser versions across all developers
- Faster CI builds (no browser downloads)
- Works on NixOS without manual system dependency management
- Browsers shared across projects via Nix store

## 👀 Want to learn more?

Check out [Starlight's docs](https://starlight.astro.build/), read [the Astro documentation](https://docs.astro.build), or jump into the [Astro Discord server](https://astro.build/chat).
