# List all recipes
default:
    @just --list

# Contents
## CI/CD
## Docs
## Nix

## CI/CD

# Run pre-commit hooks
[group('CI/CD')]
pre-commit:
  pre-commit run --all-files

## Docs

# Start development server
[group('docs')]
dev:
  bun run dev

# Build the documentation site
[group('docs')]
build:
  bun run build

# Preview the built site
[group('docs')]
preview:
  bun run preview

# Install dependencies
[group('docs')]
install:
  bun install

## Nix

# Enter the Nix development shell
[group('nix')]
nix-dev:
    nix develop

# Validate the Nix flake configuration
[group('nix')]
flake-check:
    nix flake check --impure

# Update all flake inputs to their latest versions
[group('nix')]
flake-update:
    nix flake update --impure

# Build the documentation package with Nix
[group('nix')]
nix-build:
    nix build .#docs
