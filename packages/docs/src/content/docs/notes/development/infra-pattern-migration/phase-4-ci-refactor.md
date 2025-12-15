---
title: "Phase 4: CI workflow refactor"
description: Restructure CI to use category-based builds and eliminate omnix dependency
---

This phase restructures the CI workflow to match the infra repository patterns, eliminating the omnix dependency and ensuring local-CI equivalence.

## Current state

**CI approach**: Uses omnix for flake discovery and building

**Current ci.yaml pattern**:
```yaml
- name: Install omnix
  run: nix --accept-flake-config profile install "github:juspay/omnix"

- name: Run flake CI and push to cachix
  run: |
    nix develop -c sops exec-env vars/shared.yaml '
      om ci run | tee /dev/stderr | cachix push "$CACHIX_CACHE_NAME"
    '
```

**setup-nix action**: Uses `nix-community/cache-nix-action`

**Issues**:
- External dependency on omnix
- Implicit output discovery (harder to debug)
- No category-based distribution for disk space management
- Different cache action than infra

## Target state

**CI approach**: Direct nix commands with category-based matrix

**Target ci.yaml pattern**:
```yaml
- name: Build category
  run: |
    nix develop --accept-flake-config -c just ci-build-category "${{ matrix.system }}" "${{ matrix.category }}"
```

**setup-nix action**: Uses `DeterminateSystems/magic-nix-cache-action`

**Benefits**:
- No external tool dependencies
- Explicit control over what builds
- Better disk space management via categories
- Easier debugging (build failures are clear)
- Local-CI equivalence via just recipes

## Migration steps

### Step 1: Update setup-nix action

Replace `.github/actions/setup-nix/action.yml`:

```yaml
name: setup-nix
description: Setup Nix environment with caching

inputs:
  installer:
    description: "'full' for space reclamation + cache, 'quick' for minimal"
    default: 'full'
  system:
    description: 'Target nix system'
    required: true
  enable-cachix:
    description: 'Enable Cachix binary cache'
    default: 'false'
  cachix-name:
    description: 'Cachix cache name'
    default: ''
  cachix-auth-token:
    description: 'Cachix authentication token'
    default: ''

runs:
  using: composite
  steps:
    # Space reclamation (Linux only, full installer)
    - name: Reclaim disk space
      if: runner.os == 'Linux' && inputs.installer == 'full'
      uses: wimpysworld/nothing-but-nix@main
      with:
        hatchet-protocol: cleave
        space-reserve-megabytes: 4096
        space-reserve-path: /mnt

    # Install Nix
    - name: Install Nix
      uses: cachix/install-nix-action@v31
      with:
        install_url: https://releases.nixos.org/nix/nix-2.32.4/install
        extra_nix_config: |
          accept-flake-config = true
          experimental-features = nix-command flakes

    # Create build directory (workaround for nothing-but-nix)
    - name: Create nix build directory
      if: runner.os == 'Linux' && inputs.installer == 'full'
      shell: bash
      run: sudo mkdir -p /nix/build

    # Magic Nix Cache
    - name: Setup magic-nix-cache
      if: inputs.installer == 'full'
      uses: DeterminateSystems/magic-nix-cache-action@main
      with:
        use-flakehub: false

    # Cachix (optional)
    - name: Setup Cachix
      if: inputs.enable-cachix == 'true'
      uses: cachix/cachix-action@v16
      with:
        name: ${{ inputs.cachix-name }}
        authToken: ${{ inputs.cachix-auth-token }}
      continue-on-error: true
```

### Step 2: Create ci-build-category script

Create `scripts/ci/ci-build-category.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SYSTEM="${1:-}"
CATEGORY="${2:-}"

if [[ -z "$SYSTEM" || -z "$CATEGORY" ]]; then
  echo "Usage: ci-build-category.sh <system> <category>"
  echo "Categories: packages, checks, devshells"
  exit 1
fi

echo "Building category: $CATEGORY for $SYSTEM"
echo "Disk space before:"
df -h / | tail -1

case "$CATEGORY" in
  packages)
    OUTPUTS=$(nix eval ".#packages.$SYSTEM" --apply 'builtins.attrNames' --json | jq -r '.[]')
    ;;
  checks)
    OUTPUTS=$(nix eval ".#checks.$SYSTEM" --apply 'builtins.attrNames' --json | jq -r '.[]')
    ;;
  devshells)
    OUTPUTS=$(nix eval ".#devShells.$SYSTEM" --apply 'builtins.attrNames' --json | jq -r '.[]')
    ;;
  *)
    echo "Unknown category: $CATEGORY"
    exit 1
    ;;
esac

echo "Outputs to build:"
echo "$OUTPUTS" | while read -r out; do echo "  - $out"; done

for output in $OUTPUTS; do
  echo "::group::Building $CATEGORY.$output"
  nix build ".#${CATEGORY}.$SYSTEM.$output" -L --no-link
  echo "::endgroup::"
done

echo "Disk space after:"
df -h / | tail -1
echo "Category $CATEGORY completed successfully"
```

### Step 3: Update CI workflow structure

Replace main nix job in `.github/workflows/ci.yaml`:

```yaml
nix:
  needs: [secrets-scan, set-variables]
  runs-on: ${{ matrix.runner }}
  strategy:
    fail-fast: false
    matrix:
      include:
        - system: x86_64-linux
          runner: ubuntu-latest
          category: packages
        - system: x86_64-linux
          runner: ubuntu-latest
          category: checks
        - system: x86_64-linux
          runner: ubuntu-latest
          category: devshells
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - id: cache
      uses: ./.github/actions/cached-ci-job
      with:
        check-name: ${{ github.job }} (${{ matrix.category }}, ${{ matrix.system }})
        hash-sources: '**/*.nix flake.lock justfile'
        force-run: ${{ inputs.force_run || false }}

    - if: steps.cache.outputs.should-run == 'true'
      uses: ./.github/actions/setup-nix
      with:
        system: ${{ matrix.system }}
        enable-cachix: true
        cachix-name: ${{ vars.CACHIX_CACHE_NAME }}
        cachix-auth-token: ${{ secrets.CACHIX_AUTH_TOKEN }}

    - if: steps.cache.outputs.should-run == 'true'
      name: Build category
      run: |
        nix develop --accept-flake-config -c just ci-build-category "${{ matrix.system }}" "${{ matrix.category }}"
```

### Step 4: Remove omnix references

Remove from ci.yaml:
- `nix --accept-flake-config profile install "github:juspay/omnix"`
- `om ci run`
- `om show .`

### Step 5: Add flake-validation job

Add to `.github/workflows/ci.yaml`:

```yaml
flake-validation:
  needs: [secrets-scan]
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - uses: ./.github/actions/setup-nix
      with:
        installer: quick
        system: x86_64-linux

    - name: Validate justfile recipes
      run: |
        just --summary | grep -q "check" || (echo "Missing 'check' recipe" && exit 1)
        just --summary | grep -q "lint" || (echo "Missing 'lint' recipe" && exit 1)
        echo "Required recipes found"

    - name: Run flake check
      run: nix develop --accept-flake-config -c just check
```

### Step 6: Update environment variables

Change from secrets to vars where appropriate:

```yaml
env:
  CACHIX_CACHE_NAME: ${{ vars.CACHIX_CACHE_NAME }}
```

## Verification

### V1: CI workflow syntax valid

```bash
act --list
```

Expected: Lists all jobs without syntax errors.

### V2: Local category build works

```bash
nix develop -c just ci-build-category x86_64-linux checks
```

Expected: Builds all checks for system.

### V3: No omnix references remain

```bash
grep -r "omnix\|om ci\|om show" .github/
```

Expected: No matches.

### V4: setup-nix action works

```bash
# Test locally via act (if available)
act -j nix --matrix system:x86_64-linux --matrix category:checks
```

Expected: Job completes successfully.

### V5: Flake validation passes

```bash
nix develop -c just check
```

Expected: All checks pass.

## Rollback

If verification fails:

```bash
git checkout HEAD -- .github/
```

## Job dependency graph

```
secrets-scan
    │
set-variables
    │
    ├── flake-validation
    │
    └── nix (matrix)
            │
        test (matrix)
            │
        deploy
```

## Dependencies

- Phase 1 (import-tree) - stable flake structure
- Phase 2 (treefmt-nix) - treefmt check in flake
- Phase 3 (nix-unit) - unit tests in flake check

## Blocked by

- Phases 1, 2, 3

## Blocks

- Phase 5 (justfile sync) - CI structure determines required recipes

## Notes

The key pattern is `nix develop --accept-flake-config -c just [recipe]`.
This ensures identical behavior between local development and CI.

Category-based matrix jobs prevent disk exhaustion on GitHub runners.
Each category builds a subset of outputs, allowing parallel execution.

The `magic-nix-cache-action` is more modern than `cache-nix-action` and integrates better with the Nix ecosystem.
