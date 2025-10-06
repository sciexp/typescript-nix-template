# Contributing to typescript-nix-template

Thank you for contributing to this project!

## Conventional commits

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for commit messages to enable automated semantic versioning.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature (triggers minor version bump)
- `fix`: Bug fix (triggers patch version bump)
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring without feature/fix
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes
- `build`: Build system changes

### Scopes

Use package names as scopes:
- `starlight-docs`: for changes to the starlight-docs package
- `sqlrooms-hf-ducklake`: for changes to the sqlrooms-hf-ducklake package (when added)

For cross-cutting changes affecting multiple packages, you can omit the scope or use multiple scopes separated by commas.

### Breaking changes

To trigger a major version bump, include `BREAKING CHANGE:` in the footer or use `!` after the type/scope:

```
feat(starlight-docs)!: migrate to Astro 5

BREAKING CHANGE: Astro 5 requires Node 18+
```

### Examples

```bash
# Feature in specific package
feat(starlight-docs): add search functionality

# Bug fix with scope
fix(starlight-docs): handle null values in query results

# Breaking change
feat(starlight-docs)!: migrate to Astro 5

BREAKING CHANGE: Astro 5 requires Node 18+

# Multiple scopes affected
refactor(starlight-docs,sqlrooms-hf-ducklake): update typescript to 5.9

# Documentation
docs(starlight-docs): update installation guide

# Chore without scope
chore: update dependencies
```

## Development workflow

### Install dependencies

```bash
bun install
```

### Run tests

```bash
# Run all tests in all packages
just test

# Run tests for specific package
just test-pkg starlight-docs

# Run unit tests
just test-unit

# Run E2E tests
just test-e2e
```

### Build

```bash
# Build specific package
just build

# Or use bun directly
bun run --filter '@sciexp/starlight-docs' build
```

### Code quality

```bash
# Format code
just format

# Lint code
just lint

# Check and fix
just check
```

## Release process

Releases are automated using semantic-release:

1. Push conventional commits to the `main` branch
2. semantic-release analyzes commits and determines version bump
3. Generates CHANGELOG.md
4. Creates GitHub release with notes
5. Creates version tags
6. Commits CHANGELOG.md back with `[skip ci]`

To test a release locally:

```bash
# Test at root level
bun run test-release

# Test at package level
cd packages/starlight-docs
bun run test-release
```

## Pull requests

1. Create a feature branch from `main`
2. Make your changes following conventional commit format
3. Ensure tests pass locally
4. Push your branch and create a pull request
5. CI will run tests and checks
6. After approval and merge, semantic-release will handle versioning

## Questions?

Feel free to open an issue for questions or discussions.
