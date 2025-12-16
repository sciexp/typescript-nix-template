# typescript-nix-template

TypeScript project template with Nix flake-parts, Bun workspaces, and semantic-release.

## Overview

This is a monorepo workspace combining TypeScript packages with a Nix flake that uses deferred module composition via import-tree.
The architecture provides reproducible development environments, unified formatting with treefmt-nix, and comprehensive testing including nix-unit tests for flake validation.

## Packages

- **[@typescript-nix-template/docs](./packages/docs)**: Astro Starlight documentation site [![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

## Project structure

```
typescript-nix-template/
├── modules/                     # Nix flake-parts modules (import-tree)
│   ├── checks/
│   │   └── nix-unit.nix         # Flake validation tests
│   ├── dev-shell.nix            # Development environment
│   ├── flake-parts.nix          # Module composition
│   ├── formatting.nix           # treefmt-nix configuration
│   ├── packages.nix             # Nix package definitions
│   ├── systems.nix              # Supported system architectures
│   └── template.nix             # Flake template definition
├── packages/
│   └── docs/                    # Astro Starlight documentation site
│       ├── src/
│       ├── public/
│       ├── e2e/
│       ├── tests/
│       └── package.json
├── package.json                 # Workspace root configuration
├── tsconfig.json                # Shared TypeScript configuration
├── flake.nix                    # Nix flake entrypoint
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

## Nix architecture

This template uses flake-parts with import-tree for deferred module composition.
Modules in the `modules/` directory are automatically discovered and composed, separating concerns by aspect rather than bundling everything in `flake.nix`.

Key modules:
- **formatting.nix**: treefmt-nix configuration with biome (TypeScript/JSON) and nixfmt (Nix)
- **dev-shell.nix**: Development tools (bun, biome, playwright, semantic-release, etc.)
- **packages.nix**: Nix package definitions for the docs site
- **checks/nix-unit.nix**: Flake validation tests ensuring outputs conform to expected structure

### Formatting

All formatting runs through treefmt-nix, providing a single command for all file types:

```bash
nix fmt                    # Format all files
just fmt                   # Alias via just
just fmt-check             # Check without modifying
```

Formatters configured: biome (TypeScript, JSON, JavaScript), nixfmt (Nix files).

### Flake validation

```bash
nix flake check --impure   # Run all checks including nix-unit tests
just check                 # Alias via just
just validate-flake        # Validate flake structure and required recipes
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
just docs-dev

# Build docs
just docs-build

# Run tests
just test

# Run unit tests
just docs-test-unit

# Run E2E tests
just docs-test-e2e
```

### Using bun directly

```bash
# Run command in specific package
bun run --filter '@typescript-nix-template/docs' dev
bun run --filter '@typescript-nix-template/docs' build
bun run --filter '@typescript-nix-template/docs' test

# Run command in all packages
bun run --filter '@typescript-nix-template/*' test
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
just docs-deploy-preview <branch>

# Deploy to production
just docs-deploy-production
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

## CI/CD

GitHub Actions workflows use category-based matrix builds for efficient parallelization:

- **nix**: Flake checks and builds distributed across `packages`, `checks`, `devShells`, and `formatter` categories
- **package-test**: Unit tests, coverage, and E2E tests for each package
- **deploy-docs**: Preview and production deployments to Cloudflare Workers

### Local CI equivalence

Any CI job can be reproduced locally using the same commands:

```bash
nix develop -c just check              # Flake validation
nix develop -c just ci-build-category aarch64-darwin packages  # Build specific category
nix develop -c just scan-secrets       # Security scanning
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines and conventional commit format.

## License

MIT
