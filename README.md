# typescript-nix-template

TypeScript project template with Nix, Bun workspaces, and semantic-release.

## Overview

This is a monorepo workspace containing TypeScript packages managed with Bun workspaces, Nix for development environments, and semantic-release for automated versioning.

## Packages

- **[@sciexp/docs](./packages/docs)**: Astro Starlight documentation site [![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

## Project structure

```
typescript-nix-template/
├── packages/
│   └── docs/                    # Astro Starlight documentation site
│       ├── src/
│       ├── public/
│       ├── e2e/
│       ├── tests/
│       └── package.json
├── package.json                 # Workspace root configuration
├── tsconfig.json                # Shared TypeScript configuration
├── flake.nix                    # Nix development environment
├── justfile                     # Task runner commands
└── CONTRIBUTING.md              # Contribution guidelines
```

## Getting started

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [direnv](https://direnv.net/) (recommended)

### Setup

```bash
# Clone the repository
git clone https://github.com/sciexp/typescript-nix-template.git
cd typescript-nix-template

# Enter Nix development shell
nix develop

# Install dependencies
bun install
```

## Development

### Workspace commands

```bash
# Install all workspace dependencies
just install

# Clean all build artifacts
just clean

# Run command in specific package
just pkg docs <command>

# Run command in docs (shorthand)
just docs <command>
```

### Package-specific commands

```bash
# Start dev server for docs
just dev

# Build docs
just build

# Run tests
just test

# Run unit tests
just test-unit

# Run E2E tests
just test-e2e
```

### Using bun directly

```bash
# Run command in specific package
bun run --filter '@sciexp/docs' dev
bun run --filter '@sciexp/docs' build
bun run --filter '@sciexp/docs' test

# Run command in all packages
bun run --filter '@sciexp/*' test
```

## Testing

Comprehensive testing with Vitest and Playwright:

| Command                | Action                                    |
| :--------------------- | :---------------------------------------- |
| `just test`            | Run all tests in all packages             |
| `just test-pkg <name>` | Run tests in specific package             |
| `just test-unit`       | Run unit tests in docs                    |
| `just test-e2e`        | Run E2E tests in docs                     |
| `just test-watch`      | Run Vitest in watch mode                  |
| `just test-ui`         | Run Playwright in UI mode                 |
| `just test-coverage`   | Generate test coverage report             |

## Deployment

### Cloudflare Workers

The docs package deploys to Cloudflare Workers:

```bash
# Preview locally
just cf-preview

# Deploy preview for branch
just cf-deploy-preview <branch>

# Deploy to production
just cf-deploy-production
```

## Releases

This project uses [semantic-release](https://semantic-release.gitbook.io/) with [conventional commits](https://www.conventionalcommits.org/) for automated versioning.

### Commit format

```
<type>(<scope>): <subject>
```

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

### Testing releases

```bash
# Test release for specific package
just test-release docs

# Test release for all packages
just test-release-all
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines and conventional commit format.

## License

MIT
