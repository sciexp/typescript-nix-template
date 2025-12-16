# typescript-nix-template

TypeScript project template with Nix flake-parts, Bun workspaces, and semantic-release.

## Overview

This is a monorepo workspace combining TypeScript packages with a Nix flake that uses deferred module composition via import-tree.
The architecture provides reproducible development environments, unified formatting with treefmt-nix, and comprehensive testing including nix-unit tests for flake validation.

## Template usage

You can use [omnix](https://omnix.page/om/init.html)[^omnix] to initialize this template:

```sh
nix --accept-flake-config run github:juspay/omnix -- \
  init github:sciexp/typescript-nix-template -o my-project
```

[^omnix]: If you have omnix installed you just need `om init ...` and not `nix run ... -- init`

You can run `direnv allow` to enter the shell environment that contains development dependencies or `nix develop` to enter (or add `-c command` to execute individual commands within) the development shell.

<details><summary>Instantiate with full parameters</summary>

```sh
PROJECT_DIRECTORY=my-project && \
PARAMS=$(cat <<EOF
{
  "project-name": "$PROJECT_DIRECTORY",
  "npm-scope": "@$PROJECT_DIRECTORY",
  "git-org": "myorg",
  "author": "Your Name",
  "author-email": "you@example.com",
  "project-description": "My TypeScript project with Nix",
  "cloudflare-worker-name": "my-project-docs",
  "production-url": "my-project.example.com",
  "github-ci": true,
  "vscode": true,
  "docs": true,
  "nix-template": false
}
EOF
) && \
nix --accept-flake-config run github:juspay/omnix/v1.3.0 -- \
  init github:sciexp/typescript-nix-template/main \
  -o "$PROJECT_DIRECTORY" --non-interactive --params "$PARAMS" && \
cd "$PROJECT_DIRECTORY" && \
git init && \
git commit --allow-empty -m "initial commit (empty)" && \
git add . && \
direnv allow && \
bun install && \
bun test
```

</details>

<details><summary>Instantiate without docs (minimal)</summary>

For projects that do not need a documentation site or Cloudflare deployment:

```sh
PROJECT_DIRECTORY=my-project && \
PARAMS=$(cat <<EOF
{
  "project-name": "$PROJECT_DIRECTORY",
  "npm-scope": "@$PROJECT_DIRECTORY",
  "git-org": "myorg",
  "author": "Your Name",
  "author-email": "you@example.com",
  "project-description": "My TypeScript project with Nix",
  "cloudflare-worker-name": "",
  "production-url": "",
  "github-ci": true,
  "vscode": true,
  "docs": false,
  "nix-template": false
}
EOF
) && \
nix --accept-flake-config run github:juspay/omnix/v1.3.0 -- \
  init github:sciexp/typescript-nix-template/main \
  -o "$PROJECT_DIRECTORY" --non-interactive --params "$PARAMS" && \
cd "$PROJECT_DIRECTORY" && \
git init && \
git commit --allow-empty -m "initial commit (empty)" && \
git add . && \
direnv allow && \
bun install && \
bun test
```

</details>

<details><summary>Version pinning options</summary>

You may want to update the git ref/rev of the template if you need to pin to a particular version:

- `github:sciexp/typescript-nix-template/main`
- `github:sciexp/typescript-nix-template/v0.1.0`
- `github:sciexp/typescript-nix-template/3289dla`
- `github:sciexp/typescript-nix-template/devbranch`

</details>

<details><summary>Template parameters</summary>

| Parameter | Description |
| :-------- | :---------- |
| `project-name` | Project/repository name (kebab-case) |
| `npm-scope` | npm package scope (include the `@` prefix) |
| `git-org` | GitHub organization or username |
| `author` | Package author name |
| `author-email` | Package author email |
| `project-description` | Short description of the project |
| `cloudflare-worker-name` | Cloudflare Pages worker identifier (empty string if `docs: false`) |
| `production-url` | Production domain for docs site (empty string if `docs: false`) |
| `github-ci` | Enable GitHub Actions workflows |
| `vscode` | Include VS Code workspace configuration |
| `docs` | Include Astro Starlight documentation site |
| `nix-template` | Include template.nix for re-templating capability |

</details>

## Packages

- **[@typescript-nix-template/docs](./packages/docs)**: Astro Starlight documentation site [![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

<details><summary>Project structure</summary>

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
├── Makefile                     # Bootstrap commands (nix/direnv install)
├── justfile                     # Development task runner
└── CONTRIBUTING.md              # Contribution guidelines
```

</details>

## Getting started

### Quick start (one-liner)

Install Nix, direnv, and generate secrets keys with a single command.
First, preview what the script will do:

```bash
bash <(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/sciexp/typescript-nix-template/main/scripts/bootstrap.sh) --dry-run
```

Once you're comfortable with the actions it will take, remove `--dry-run` to execute.
Use `--help` to see all options including `--yes` for non-interactive mode.

<details>
<summary>Manual bootstrap</summary>

Alternatively, clone first and use Make targets:

```bash
git clone https://github.com/sciexp/typescript-nix-template.git
cd typescript-nix-template

# On macOS: install Xcode CLI tools and Homebrew
make bootstrap-prep-darwin

# Install Nix and direnv
make bootstrap

# Verify and generate secrets key
make verify
make setup-user
```

</details>

### Setup (Nix already installed)

```bash
git clone https://github.com/sciexp/typescript-nix-template.git
cd typescript-nix-template
nix develop
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

<details><summary>Using bun directly</summary>

```bash
# Run command in specific package
bun run --filter '@typescript-nix-template/docs' dev
bun run --filter '@typescript-nix-template/docs' build
bun run --filter '@typescript-nix-template/docs' test

# Run command in all packages
bun run --filter '@typescript-nix-template/*' test
```

</details>

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

<details><summary>Local CI equivalence</summary>

Any CI job can be reproduced locally using the same commands:

```bash
nix develop -c just check              # Flake validation
nix develop -c just ci-build-category aarch64-darwin packages  # Build specific category
nix develop -c just scan-secrets       # Security scanning
```

</details>

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines and conventional commit format.

## License

MIT
