---
title: Verification checklist
description: Cross-cutting verification steps for migration validation
---

This document provides a comprehensive checklist to verify successful migration across all phases.

## Pre-migration baseline

Before starting migration, capture the current working state:

```bash
# Ensure current state works
nix flake check --impure
nix develop -c echo "DevShell works"
just --list
```

Document any failures - they should not be introduced by migration.

## Phase completion gates

Each phase must pass its verification steps before proceeding to the next.
Record pass/fail status as you complete each phase.

### Phase 1: import-tree adoption

| Check | Command | Expected | Status |
|-------|---------|----------|--------|
| Flake evaluates | `nix flake check --impure` | No eval errors | |
| DevShell accessible | `nix develop -c echo "ok"` | Prints "ok" | |
| Outputs exist | `nix flake show` | Shows packages, devShells | |
| import-tree in inputs | `grep import-tree flake.nix` | Found | |
| Old modules removed | `ls nix/modules 2>/dev/null` | Not found | |

### Phase 2: treefmt-nix integration

| Check | Command | Expected | Status |
|-------|---------|----------|--------|
| treefmt check passes | `nix flake check --impure \| grep treefmt` | Builds | |
| nix fmt works | `nix fmt -- --check .` | Exits 0 or shows diff | |
| treefmt in devshell | `nix develop -c treefmt --help` | Shows help | |
| pre-commit hook | `nix develop -c pre-commit run treefmt` | Runs | |
| treefmt-nix in inputs | `grep treefmt-nix flake.nix` | Found | |

### Phase 3: nix-unit testing

| Check | Command | Expected | Status |
|-------|---------|----------|--------|
| Tests pass | `nix flake check --impure 2>&1 \| grep "test result"` | All pass | |
| Checks visible | `nix flake show \| grep checks` | Shows checks | |
| nix-unit in inputs | `grep nix-unit flake.nix` | Found | |
| Test file exists | `ls modules/checks/nix-unit.nix` | Found | |

### Phase 4: CI workflow refactor

| Check | Command | Expected | Status |
|-------|---------|----------|--------|
| No omnix refs | `grep -r "omnix\|om ci" .github/` | No matches | |
| setup-nix updated | `grep magic-nix-cache .github/actions/setup-nix/` | Found | |
| Category script exists | `ls scripts/ci/ci-build-category.sh` | Found | |
| Local build works | `nix develop -c just ci-build-category x86_64-linux checks` | Succeeds | |
| Workflow valid | `act --list` | No syntax errors | |

### Phase 5: justfile synchronization

| Check | Command | Expected | Status |
|-------|---------|----------|--------|
| check recipe | `just --summary \| grep check` | Found | |
| lint recipe | `just --summary \| grep lint` | Found | |
| ci-build-category | `just --summary \| grep ci-build-category` | Found | |
| list-packages-json | `just list-packages-json \| jq .` | Valid JSON | |
| validate-flake | `nix develop -c just validate-flake` | Passes | |

## End-to-end verification

After all phases complete, run these comprehensive checks:

### Local development workflow

```bash
# Enter development environment
nix develop

# Format code
just fmt

# Run linting
just lint

# Run tests
just test

# Run all checks
just check

# Build docs
just docs-build
```

All commands should succeed.

### CI simulation

```bash
# Simulate CI category builds
nix develop -c just ci-build-category x86_64-linux packages
nix develop -c just ci-build-category x86_64-linux checks
nix develop -c just ci-build-category x86_64-linux devshells

# Simulate test job
nix develop -c just test
```

All builds should succeed.

### Remote CI validation

```bash
# Trigger CI and watch
just ci-run ci.yaml

# Or check status
just ci-status
```

CI should pass all jobs.

## Regression checks

Verify these still work after migration:

| Feature | Command | Expected |
|---------|---------|----------|
| Template works | `nix flake init -t .` | Creates project |
| Docs build | `just docs-build` | Builds site |
| Docs preview | `just docs-dev` | Starts server |
| E2E tests | `just test-e2e` | Pass |
| Deploy preview | `just cf-deploy-preview` | Succeeds |

## Success criteria summary

Migration is complete when all of the following are true:

1. `nix flake check --impure` passes with all new checks (treefmt, nix-unit)
2. `nix fmt` formats all files (nix and TypeScript)
3. `just check` runs flake check via devshell
4. CI workflow completes without omnix dependency
5. Every CI job has a corresponding `just` recipe
6. `nix develop -c just [recipe]` produces same result as CI

## Troubleshooting

### Evaluation errors after Phase 1

Check module syntax:
```bash
nix eval .#debug 2>&1 | head -20
```

Common issues:
- Missing `{ ... }:` at module start
- Incorrect attribute paths
- Circular imports

### treefmt not finding files

Check projectRootFile:
```bash
cat modules/formatting.nix | grep projectRootFile
```

Ensure it points to `flake.nix`.

### nix-unit tests failing

Check test syntax:
```bash
nix eval .#checks.x86_64-linux --apply 'builtins.attrNames'
```

Verify tests exist and have correct structure.

### CI cache misses

Check hash-sources alignment:
```bash
grep hash-sources .github/workflows/ci.yaml
```

Ensure critical files are included.

### Local-CI divergence

Ensure using `--accept-flake-config`:
```bash
grep "accept-flake-config" .github/workflows/ci.yaml
```

Every `nix develop` in CI needs this flag.

## Sign-off

When migration is complete:

```bash
# Final verification
nix flake check --impure && \
nix develop -c just validate-flake && \
echo "Migration verified successfully"
```

Record completion:
- Date: ____
- Verified by: ____
- CI run: ____
