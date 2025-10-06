# CI/CD Optimization Analysis

## Executive Summary

This document analyzes CI/CD patterns across three repositories (nix-config, python-nix-template, starlight-nix-template) and provides recommendations for optimizing GitHub Actions workflows with a focus on:

1. Standardized nix setup with disk space optimization
2. Modular reusable workflows
3. Local/CI parity via `nix develop -c just [command]` pattern
4. Testability via `gh workflow run` CLI

## Cross-Repository Pattern Analysis

### Disk Space Optimization

#### nix-config (best practice)

Uses a composite action (`.github/actions/setup-nix/action.yml`) with:

**Linux:**
- `wimpysworld/nothing-but-nix@main` with `hatchet-protocol: rampage`
- Aggressive cleanup of unused GitHub Actions runner software
- Reclaims ~30-50GB on ubuntu-latest runners

**macOS:**
- Custom cleanup script removing:
  - `/Applications/Xcode_*`
  - `/Library/Developer/CoreSimulator`
  - `/Users/runner/.dotnet`, `.rustup`, `Library/Android`, `Library/Caches`
  - `/Users/runner/hostedtoolcache`
- Background deletion to maximize available space during builds
- Disables Spotlight indexing (`mdutil`, `mds.plist`)

**Post-setup:**
- Uses `srz-zumix/post-run-action@v2` to report disk usage after completion

#### python-nix-template (partial implementation)

Manual cleanup in specific workflows:
- Removes `/usr/local/lib/android` and `/opt/hostedtoolcache/CodeQL`
- Shows disk space with `df -h` before/after
- No consistent pattern across workflows

#### starlight-nix-template (current state)

No disk space optimization:
- Only runs `sudo apt-get clean` after installing dependencies
- No nothing-but-nix usage
- May face disk pressure on large builds

### Workflow Architecture

#### nix-config (modular jobs)

```yaml
on:
  workflow_dispatch:
    inputs:
      job:
        description: specific job to run (leave empty to run all)
```

- Each job has conditional: `if: inputs.job == '' || inputs.job == 'job-name'`
- Allows testing individual jobs via `gh workflow run ci.yaml -f job=bootstrap-verification`
- Uses composite action for consistent nix setup across all jobs
- Pattern: `nix develop --command [tool] [args]`

**Key Jobs:**
1. `bootstrap-verification` - Tests Makefile bootstrap on clean system
2. `config-validation` - Tests nix config evaluation
3. `autowiring-validation` - Verifies nixos-unified module discovery
4. `secrets-workflow` - Tests sops-nix with ephemeral keys
5. `justfile-activation` - Tests just recipe dry-runs
6. `nix` - Matrix build across x86_64-linux, aarch64-linux, aarch64-darwin

#### python-nix-template (reusable workflows)

**Modular reusable workflows:**
1. `deploy-docs.yaml` - Both `workflow_call` and `workflow_dispatch`
2. `python-test.yaml` - Reusable test runner
3. `package-release.yaml` - Semantic release with container build support

**deploy-docs.yaml pattern:**
```yaml
on:
  workflow_dispatch:
    inputs:
      debug_enabled: { type: string }
      branch: { type: string }
  workflow_call:
    inputs:
      debug_enabled: { type: string }
      branch: { type: string }

jobs:
  build-docs:
    # Build step
  deploy-docs:
    needs: build-docs
    # Deploy step uses artifacts
```

**Key benefits:**
- Separation of build and deploy enables preview/production split
- Testable via `gh workflow run deploy-docs.yaml -f branch=feature-x`
- Reusable from main CI workflow via `uses: ./.github/workflows/deploy-docs.yaml`
- Pattern: `nix develop --accept-flake-config -c just docs-build`

#### starlight-nix-template (current monolithic)

**Single ci.yaml with jobs:**
1. `scan` - GitGuardian
2. `set-variables` - Conditional logic
3. `nixci` - omnix ci run
4. `test` - Unit and E2E tests
5. `build` - Documentation build
6. `deploy` - Cloudflare deployment

**Limitations:**
- Can't easily test individual jobs in isolation
- No reusable workflows
- Pattern: `nix develop --command bash -c "bun run [script]"`
- Direct coupling between test execution and workflow logic

### Just Recipe Integration

#### nix-config (nix-focused)

```just
# Test dry-run builds
test-build branch=`git branch --show-current`:
  nix develop --command just -n check
  nix develop --command just -n lint
```

- Recipes callable via `nix develop -c just [recipe]`
- Dry-run testing with `-n` flag
- Focus on nix operations (activate, check, lint)

#### python-nix-template (comprehensive CI management)

```just
# Build docs (used in CI)
docs-build: data-sync docs-reference
  quarto render docs

# Trigger workflow remotely
gh-docs-build branch=`git branch --show-current` debug="false":
  gh workflow run deploy-docs.yaml \
    --ref "{{branch}}" \
    --field debug_enabled="{{debug}}" \
    --field branch="{{branch}}"

# Watch workflow
gh-docs-watch run_id="":
  # Gets latest run if no ID provided
```

**Pattern:**
- CI workflow calls: `nix develop -c just docs-build`
- Local development: `just docs-build` (same command)
- Rich gh CLI wrapper recipes for workflow management
- Dependencies between recipes (docs-build depends on data-sync)

#### starlight-nix-template (current hybrid)

**Current state:**
- CI calls: `nix develop --command bash -c "bun run build"`
- Just recipes: Mostly wrap `bun run [script]` commands
- Good gh workflow management recipes (similar to python-nix-template)

**Gap:**
- No just recipes for core CI operations (test, build, lint)
- Can't easily run CI commands identically locally and in GitHub Actions
- Extra bash -c layer adds complexity

## Recommendations

### 1. Create setup-nix Composite Action

**Location:** `.github/actions/setup-nix/action.yml`

**Benefits:**
- Consistent nix setup across all jobs
- Disk space optimization via nothing-but-nix
- Single source of truth for nix installation config
- Easier to update nix-installer version

**Implementation:**
```yaml
name: setup-nix
inputs:
  system:
    description: nix system (e.g., x86_64-linux)
    type: string
    default: x86_64-linux
runs:
  using: composite
  steps:
    - name: Reclaim space (linux)
      if: runner.os == 'Linux'
      uses: wimpysworld/nothing-but-nix@main
      with:
        hatchet-protocol: rampage

    - name: Install Nix
      uses: DeterminateSystems/nix-installer-action@main
      with:
        extra-conf: |
          system-features = nixos-test benchmark big-parallel kvm
          system = ${{ inputs.system }}
```

**Usage in workflows:**
```yaml
- uses: ./.github/actions/setup-nix
  with:
    system: x86_64-linux
```

### 2. Refactor to `nix develop -c just [command]` Pattern

**Current state:**
```yaml
- name: Run unit tests
  run: nix develop --command bash -c "bun run test:unit"
```

**Proposed state:**

**Add to justfile:**
```just
# Run unit tests
[group('testing')]
test-unit:
  bun run test:unit

# Run E2E tests
[group('testing')]
test-e2e:
  bun run test:e2e

# Build docs
[group('docs')]
build:
  bun run build

# Lint code
[group('CI/CD')]
lint:
  bun run lint
```

**Update workflow:**
```yaml
- name: Run unit tests
  run: nix develop -c just test-unit
```

**Benefits:**
- Identical commands work locally and in CI
- Just recipes document available operations
- Can compose recipes (e.g., `test: test-unit test-e2e`)
- Easier to debug CI failures locally

### 3. Create Reusable Workflows

#### 3.1 Deploy Docs Workflow

**Location:** `.github/workflows/deploy-docs.yaml`

**Structure:**
```yaml
name: Deploy docs

on:
  workflow_dispatch:
    inputs:
      debug_enabled: { type: string, default: "false" }
      branch: { type: string, required: true }
      environment: { type: string, default: "preview" }
  workflow_call:
    inputs:
      debug_enabled: { type: string, default: "false" }
      branch: { type: string, required: true }
      environment: { type: string, default: "production" }

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ inputs.branch }}
      - uses: ./.github/actions/setup-nix
      - uses: cachix/cachix-action@master
        with:
          name: ${{ vars.CACHIX_CACHE_NAME }}
      - name: Build
        run: nix develop -c just build
      - uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.run_id }}
          path: result/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: ${{ inputs.environment }}
      url: https://starlight-nix-template.pages.dev
    steps:
      - uses: actions/download-artifact@v4
      - name: Deploy
        run: nix develop -c just cf-deploy
```

**Testing:**
```bash
# Preview deployment
just gh-docs-build branch=feature-x

# Or via gh CLI directly
gh workflow run deploy-docs.yaml \
  -f branch=feature-x \
  -f environment=preview
```

#### 3.2 Test Workflow

**Location:** `.github/workflows/test.yaml`

```yaml
name: Test

on:
  workflow_dispatch:
    inputs:
      test-type: { type: string, default: "all" }
      debug_enabled: { type: boolean, default: false }
  workflow_call:
    inputs:
      test-type: { type: string, default: "all" }
      debug_enabled: { type: string, default: "false" }

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-nix
      - uses: cachix/cachix-action@master
      - name: Install dependencies
        run: nix develop -c just install
      - name: Run tests
        run: |
          case "${{ inputs.test-type }}" in
            unit) nix develop -c just test-unit ;;
            e2e) nix develop -c just test-e2e ;;
            *) nix develop -c just test ;;
          esac
```

**Usage in main CI:**
```yaml
test:
  uses: ./.github/workflows/test.yaml
  with:
    test-type: all
    debug_enabled: ${{ needs.set-variables.outputs.debug }}
```

**Testing:**
```bash
# Test just unit tests
gh workflow run test.yaml -f test-type=unit

# Test with debug
gh workflow run test.yaml -f test-type=e2e -f debug_enabled=true
```

### 4. Enhanced Justfile Recipes

**Add test recipes:**
```just
# Run all tests (used in CI)
[group('testing')]
test: test-unit test-e2e
  @echo "All tests passed"

# Build for deployment (used in CI)
[group('docs')]
build-deploy: build
  @echo "Build ready for deployment"

# Lint and check (used in CI)
[group('CI/CD')]
ci-check: lint check
  @echo "CI checks passed"
```

**Add gh workflow testing recipes:**
```just
# Test deploy workflow locally with act
[group('CI/CD')]
test-deploy-local branch=`git branch --show-current`:
  @sops exec-env vars/shared.yaml 'act workflow_dispatch \
    -W .github/workflows/deploy-docs.yaml \
    -s CLOUDFLARE_API_TOKEN -s CLOUDFLARE_ACCOUNT_ID \
    -s GITHUB_TOKEN="$(gh auth token)" \
    --var CACHIX_CACHE_NAME \
    --input branch={{branch}} \
    --input environment=preview'

# Run deploy workflow on GitHub
[group('CI/CD')]
gh-deploy branch=`git branch --show-current` env="preview":
  gh workflow run deploy-docs.yaml \
    -f branch={{branch}} \
    -f environment={{env}}
```

### 5. Workflow Job Modularity

**Add job selection to ci.yaml:**
```yaml
on:
  workflow_dispatch:
    inputs:
      job:
        description: "Specific job to run (leave empty for all)"
        type: string
        required: false
      debug_enabled:
        type: boolean
        default: false

jobs:
  nixci:
    if: |
      github.event_name != 'workflow_dispatch' ||
      inputs.job == '' ||
      inputs.job == 'nixci'
    # ... existing job

  test:
    if: |
      github.event_name != 'workflow_dispatch' ||
      inputs.job == '' ||
      inputs.job == 'test'
    # ... existing job
```

**Testing:**
```bash
# Test just the nixci job
gh workflow run ci.yaml -f job=nixci

# Test just the test job with debug
gh workflow run ci.yaml -f job=test -f debug_enabled=true
```

## Implementation Priority

### Phase 1: Foundation (High Impact, Low Risk)
1. Create `.github/actions/setup-nix` composite action
2. Add disk space optimization
3. Update all workflows to use composite action
4. Test disk space improvements

### Phase 2: Local/CI Parity (High Impact, Medium Risk)
1. Add core CI recipes to justfile (test, lint, build)
2. Update ci.yaml to use `nix develop -c just [command]`
3. Test locally to verify parity
4. Document common workflows

### Phase 3: Modular Workflows (Medium Impact, Medium Risk)
1. Extract deploy-docs to reusable workflow
2. Add workflow_dispatch with testing inputs
3. Test via gh CLI
4. Update main CI to use reusable workflow

### Phase 4: Enhanced Testing (Low Impact, Low Risk)
1. Add job selection to ci.yaml
2. Create test.yaml reusable workflow
3. Add gh workflow management recipes to justfile
4. Document testing procedures

## Trade-offs and Considerations

### `nix develop -c just [command]` vs Direct Commands

**Pros:**
- Perfect local/CI parity
- Self-documenting via `just --list`
- Composable recipes
- Easier to test CI failures locally

**Cons:**
- Extra layer of indirection
- Need to learn just syntax
- Slightly more verbose in justfile

**Recommendation:** Adopt for all CI operations. Benefits outweigh costs.

### Reusable Workflows vs Monolithic CI

**Pros:**
- Testable in isolation via `gh workflow run`
- Reusable across branches/repos
- Clearer separation of concerns
- Can have different permissions per workflow

**Cons:**
- More files to maintain
- Slightly more complex workflow_call/workflow_dispatch setup
- Need to pass secrets explicitly

**Recommendation:** Use for:
- Docs deployment (preview vs production)
- Release workflows
- Long-running or expensive operations

Keep in main CI:
- Quick checks (lint, format)
- GitGuardian scan
- Variable setup

### Disk Space Optimization Trade-offs

**nothing-but-nix (aggressive):**
- **Pros:** Reclaims 30-50GB, prevents disk pressure
- **Cons:** Takes 2-3 minutes, removes potentially useful tools
- **Recommendation:** Use on ubuntu-latest for nix builds

**Manual cleanup (selective):**
- **Pros:** Fast (~30s), targeted removal
- **Cons:** Less space reclaimed (~10-20GB)
- **Recommendation:** Use for non-nix jobs if needed

### Composite Actions vs Workflow Templates

**Composite Actions:**
- **Pros:** Reusable steps, no duplication, versioned via git
- **Cons:** Can't set job-level config (runs-on, etc.)
- **Use for:** Setup steps, common patterns

**Reusable Workflows:**
- **Pros:** Complete job definitions, workflow-level features
- **Cons:** More complex, require workflow_call setup
- **Use for:** Complete workflows (test, deploy, release)

## Success Metrics

1. **Disk Space:** No failures due to disk pressure
2. **Build Time:** Baseline and compare after optimization
3. **Local/CI Parity:** Can reproduce CI failures locally via just recipes
4. **Testing Velocity:** Can test individual jobs via gh CLI
5. **Maintenance:** Easier updates to nix setup via composite action

## Next Steps

1. Create implementation plan with specific PRs
2. Set up feature branch for changes
3. Implement Phase 1 (setup-nix composite action)
4. Measure baseline build times and disk usage
5. Iterate through phases with testing
6. Document new workflow patterns
