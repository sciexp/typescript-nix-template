---
title: "Phase 5: justfile synchronization"
description: Align justfile recipes with CI jobs for local-CI equivalence
---

This phase ensures every CI job has a corresponding `just` recipe that produces identical results locally.

## Current state

**Justfile groups**:
- Workspace, CI/CD, Cloudflare, Docs, Nix, Release, Secrets, Testing

**CI pattern**: Mixed - some use `nix develop -c just`, some use direct commands

**Missing alignment**:
- No `ci-build-category` recipe
- No `validate-flake` recipe
- Some CI commands not wrapped in just recipes

## Target state

**Core pattern**: Every CI step that runs code uses:
```bash
nix develop --accept-flake-config -c just [recipe]
```

**Required recipes** (must exist for CI):
- `check` - runs `nix flake check`
- `lint` - runs pre-commit/treefmt
- `ci-build-category` - builds nix outputs by category
- `validate-flake` - validates flake structure and recipes
- `list-packages-json` - generates package matrix for CI

## Migration steps

### Step 1: Add CI-specific recipes

Add to justfile:

```just
## CI/CD

# Build specific nix category (for CI matrix distribution)
[group('CI/CD')]
ci-build-category system category:
  @./scripts/ci/ci-build-category.sh "{{system}}" "{{category}}"

# Validate flake structure and required recipes
[group('CI/CD')]
validate-flake:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Validating flake structure..."

  REQUIRED_RECIPES="check lint format test"
  JUST_RECIPES=$(just --summary)

  for recipe in $REQUIRED_RECIPES; do
    if echo "$JUST_RECIPES" | grep -qw "$recipe"; then
      echo "OK: '$recipe' recipe found"
    else
      echo "ERROR: '$recipe' recipe not found"
      exit 1
    fi
  done

  echo "Running nix flake check..."
  nix flake check --impure

# List packages in JSON format for CI matrix
[group('CI/CD')]
list-packages-json:
  #!/usr/bin/env bash
  cd packages
  packages=()
  for dir in */; do
    pkg_name="${dir%/}"
    if [ -f "$dir/package.json" ]; then
      packages+=("{\"name\":\"$pkg_name\",\"path\":\"packages/$pkg_name\"}")
    fi
  done
  echo "[$(IFS=,; echo "${packages[*]}")]"

# List all recipe names (for discovery)
[group('CI/CD')]
list-recipes:
  @just --list

# Trigger CI workflow and watch result
[group('CI/CD')]
ci-run workflow="ci.yaml":
  #!/usr/bin/env bash
  set -euo pipefail
  gh workflow run {{workflow}} --ref $(git branch --show-current)
  sleep 5
  RUN_ID=$(gh run list --workflow={{workflow}} --limit 1 --json databaseId --jq '.[0].databaseId')
  echo "Watching run: $RUN_ID"
  gh run watch "$RUN_ID" --exit-status

# View latest CI run status
[group('CI/CD')]
ci-status workflow="ci.yaml":
  @gh run list --workflow={{workflow}} --limit 5

# View latest CI run logs
[group('CI/CD')]
ci-logs workflow="ci.yaml":
  @RUN_ID=$(gh run list --workflow={{workflow}} --limit 1 --json databaseId --jq '.[0].databaseId'); \
  gh run view "$RUN_ID" --log
```

### Step 2: Update nix recipes

Ensure these exist:

```just
## Nix

# Validate flake configuration (all checks)
[group('nix')]
check:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Running nix flake check..."
  echo ""
  echo "Note: nix-unit warnings are expected and harmless:"
  echo "  - 'unknown setting allowed-users/trusted-users'"
  echo "  - '--gc-roots-dir not specified'"
  echo ""
  nix flake check --impure

# Fast check (exclude heavy tests if any)
[group('nix')]
check-fast:
  nix flake check --impure

# Format all files with treefmt
[group('nix')]
fmt:
  nix fmt

# Check formatting without modifying
[group('nix')]
fmt-check:
  treefmt --check .

# Update flake inputs
[group('nix')]
flake-update:
  nix flake update

# Enter development shell
[group('nix')]
dev:
  nix develop
```

### Step 3: Update testing recipes

Ensure CI-compatible test recipes:

```just
## Testing

# Run all tests (CI-compatible)
[group('testing')]
test:
  bun run --filter '@typescript-nix-template/*' test

# Run tests for specific package
[group('testing')]
test-pkg package:
  bun run --filter '@typescript-nix-template/{{package}}' test

# Run unit tests only
[group('testing')]
test-unit:
  bun run --filter '@typescript-nix-template/docs' test:unit

# Run E2E tests only
[group('testing')]
test-e2e:
  bun run --filter '@typescript-nix-template/docs' test:e2e

# Generate coverage report
[group('testing')]
test-coverage:
  bun run --filter '@typescript-nix-template/docs' test:coverage
```

### Step 4: Remove obsolete recipes

Review and remove if present:
- Any omnix-related recipes
- Recipes that duplicate CI commands without wrapping
- Unused infrastructure-specific recipes

### Step 5: Verify recipe alignment

Create a mapping table and verify each CI step has a recipe:

| CI Job | CI Command | Just Recipe |
|--------|------------|-------------|
| flake-validation | `just check` | `check` |
| nix (packages) | `just ci-build-category x86_64-linux packages` | `ci-build-category` |
| nix (checks) | `just ci-build-category x86_64-linux checks` | `ci-build-category` |
| test | `just test` | `test` |
| lint | `just lint` | `lint` |

## Verification

### V1: All required recipes exist

```bash
just --summary | grep -E "check|lint|test|ci-build-category|validate-flake"
```

Expected: All recipes found.

### V2: list-packages-json outputs valid JSON

```bash
just list-packages-json | jq .
```

Expected: Valid JSON array of package objects.

### V3: ci-build-category works locally

```bash
nix develop -c just ci-build-category x86_64-linux checks
```

Expected: Builds all checks.

### V4: validate-flake passes

```bash
nix develop -c just validate-flake
```

Expected: All required recipes found, flake check passes.

### V5: Local matches CI behavior

```bash
# Run locally
nix develop -c just check

# Compare with CI log
just ci-logs | grep -A 20 "flake check"
```

Expected: Same output structure.

## Rollback

If verification fails:

```bash
git checkout HEAD -- justfile
```

## Recipe groups summary

Final organization:

```
## Workspace    # install, update, clean
## CI/CD        # ci-build-category, validate-flake, list-packages-json, ci-run, ci-status
## Cloudflare   # cf-deploy-preview, cf-deploy-production, cf-versions
## Docs         # docs-dev, docs-build, docs-test, docs-linkcheck
## Nix          # check, check-fast, fmt, fmt-check, flake-update, dev
## Release      # test-release, preview-version
## Secrets      # show-secrets, edit-secrets, validate-secrets
## Testing      # test, test-pkg, test-unit, test-e2e, test-coverage
```

## Dependencies

- Phase 4 (CI refactor) - determines required recipes

## Blocked by

- Phase 4

## Blocks

- Nothing (final phase)

## Notes

The core principle: if it runs in CI, it should be a just recipe.

This enables:
1. **Local debugging**: Run the exact CI command locally
2. **Consistency**: No divergence between local and CI behavior
3. **Documentation**: `just --list` shows all available operations
4. **Composition**: Complex operations built from simple recipes

Always use `nix develop --accept-flake-config -c just [recipe]` in CI.
The `--accept-flake-config` flag bypasses interactive prompts.
