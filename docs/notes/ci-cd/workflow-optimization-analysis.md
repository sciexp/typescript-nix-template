# CI/CD Workflow Optimization Analysis

Comprehensive analysis of `.github/workflows/ci.yaml` and dependencies for DRY opportunities and third-party action elimination.

## Third-Party Actions Inventory

### Workflow-Level Actions

| Action | Usage Count | Locations | Eliminable? |
|--------|-------------|-----------|-------------|
| `actions/checkout@v4` | 6x | scan, nix, test, build (ci.yaml); build, deploy (deploy-docs.yaml) | ❌ Core GitHub action |
| `actions/upload-artifact@v4` | 4x | test (2x), build (ci.yaml); build (deploy-docs.yaml) | ❌ Core GitHub action |
| `actions/download-artifact@v4` | 1x | deploy (deploy-docs.yaml) | ❌ Core GitHub action |
| `GitGuardian/ggshield-action@v1.37.0` | 1x | scan (ci.yaml) | ✅ YES - can use ggshield CLI via nix |
| `mxschmitt/action-tmate@v3` | 2x | nix (ci.yaml), build (deploy-docs.yaml) | ⚠️ Keep - useful debug tool (conditional) |

### Composite Action Dependencies (setup-nix)

| Action | Condition | Eliminable? |
|--------|-----------|-------------|
| `wimpysworld/nothing-but-nix@main` | Linux + installer=full | ✅ Could implement as bash |
| `DeterminateSystems/nix-installer-action@main` | installer=full | ⚠️ Keep - Nix experts maintain this |
| `nixbuild/nix-quick-install-action@master` | installer=quick | ⚠️ Keep - Fast alternative |
| `srz-zumix/post-run-action@v2` | macOS + installer=full | ✅ Could use cleanup job |

**Total External Dependencies**: 9 actions (5 in workflows, 4 in composite actions)

## Critical DRY Violations

### 1. Repeated Setup Pattern (HIGHEST PRIORITY)

**Location**: ci.yaml lines 151-165 (nix), 194-207 (test), 244-257 (build)

**Duplication**: Exact same 3-step sequence repeated 3 times:

```yaml
- uses: actions/checkout@v4
- name: Setup Nix
  uses: ./.github/actions/setup-nix
  with:
    installer: ${{ inputs.nix_installer || 'quick' }}
    system: x86_64-linux
- name: Setup cachix for binary cache
  env:
    SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}
  run: |
    nix develop -c sops exec-env vars/shared.yaml '
      cachix use "$CACHIX_CACHE_NAME"
      cachix use nix-community
    '
```

**Impact**: 13 lines × 3 jobs = 39 lines of duplicated code

**Solution**: Create `setup-project` composite action

### 2. Redundant Build Execution (HIGH PRIORITY)

**Problem**: The same `nix develop -c just build` runs twice:
- Line 213 (test job): Build for E2E tests
- Line 261 (build job): Build for deployment artifact

**Impact**:
- Wastes ~1-2 minutes of CI time
- Doubles Nix store usage
- Increases runner costs

**Current Flow**:
```
test job:  checkout → setup → install → test-unit → BUILD → test-e2e → upload test results
build job: checkout → setup → install → BUILD → upload dist
```

**Solution Options**:

#### Option A: Upload artifact from test job
```yaml
test:
  steps:
    - run: nix develop -c just build
    - run: nix develop -c just test-e2e
    - uses: actions/upload-artifact@v4
      with:
        name: dist
        path: dist/

build:
  needs: test
  steps:
    - uses: actions/download-artifact@v4  # Reuse test's build
```

#### Option B: Consolidate jobs
Merge test and build into single job, split E2E tests to separate job if desired.

### 3. Cachix Setup Variation (MEDIUM PRIORITY)

**Duplication**: Cachix setup repeated 3 times with slight variation:

- **nix job** (lines 157-165): Auth + use (for pushing)
- **test job** (lines 200-207): Only use (pull-only)
- **build job** (lines 250-257): Only use (pull-only)

**Solution**: Create `setup-cachix` composite action with optional auth parameter

### 4. Conditional Logic Duplication (LOW PRIORITY)

**Pattern repeated 5 times** (scan, set-variables, nix, test, build, deploy):

```yaml
if: |
  !cancelled() &&
  needs.set-variables.outputs.skip_ci != 'true' &&
  (github.event_name != 'workflow_dispatch' ||
   inputs.job == '' ||
   inputs.job == '<JOB-NAME>')
```

**Impact**: Hard to maintain, error-prone

**Solution**:
- Use reusable workflow with job selection
- Or: Extract to YAML template (when GitHub supports)

## Recommended Optimizations

### Priority 1: Create setup-project Composite Action

**File**: `.github/actions/setup-project/action.yml`

```yaml
name: Setup project environment
description: Checkout code, setup Nix, and configure cachix

inputs:
  nix-installer:
    description: Nix installer strategy (full or quick)
    default: quick
  cachix-auth:
    description: Authenticate with cachix for pushing
    default: 'false'

runs:
  using: composite
  steps:
    - uses: actions/checkout@v4

    - name: Setup Nix
      uses: ./.github/actions/setup-nix
      with:
        installer: ${{ inputs.nix-installer }}
        system: x86_64-linux

    - name: Setup cachix (with auth)
      if: inputs.cachix-auth == 'true'
      shell: bash
      run: |
        nix develop -c sops exec-env vars/shared.yaml '
          cachix authtoken "$CACHIX_AUTH_TOKEN"
          cachix use "$CACHIX_CACHE_NAME"
          cachix use nix-community
        '

    - name: Setup cachix (read-only)
      if: inputs.cachix-auth != 'true'
      shell: bash
      run: |
        nix develop -c sops exec-env vars/shared.yaml '
          cachix use "$CACHIX_CACHE_NAME"
          cachix use nix-community
        '
```

**Usage**:
```yaml
# nix job (needs push access)
- uses: ./.github/actions/setup-project
  with:
    nix-installer: ${{ inputs.nix_installer || 'quick' }}
    cachix-auth: 'true'
  env:
    SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}

# test/build jobs (read-only)
- uses: ./.github/actions/setup-project
  with:
    nix-installer: ${{ inputs.nix_installer || 'quick' }}
  env:
    SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}
```

**Impact**: Eliminates 39 lines of duplication, improves maintainability

### Priority 2: Eliminate Redundant Build ✅ COMPLETED

**Status**: Implemented in commit 74938d1

**Modify test job** to upload dist artifact:

```yaml
test:
  steps:
    # ... existing steps ...
    - name: Build for E2E tests
      run: nix develop -c just build
    - name: Run E2E tests
      run: nix develop -c just test-e2e
    - name: Upload build artifacts
      uses: actions/upload-artifact@v4
      with:
        name: dist
        path: dist/
        retention-days: 7
        include-hidden-files: true
```

**Modify build job** to download instead of rebuild:

```yaml
build:
  needs: [set-variables, test]  # Add test dependency
  steps:
    - uses: actions/checkout@v4  # Still need for git context
    - uses: actions/download-artifact@v4
      with:
        name: dist
        path: dist/
    # Artifact already built by test job
```

**Alternative**: Consolidate entirely into test job, remove build job.

**Impact**: Saves 1-2 minutes per run, reduces redundancy

### Priority 3: Replace GitGuardian Action with CLI

**Add to devShell** (nix/modules/devshell.nix):

```nix
packages = with pkgs; [
  # ... existing packages ...
  ggshield  # GitGuardian CLI
];
```

**Replace action** (ci.yaml scan job):

```yaml
scan:
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - uses: ./.github/actions/setup-nix
      with:
        installer: quick

    - name: GitGuardian scan
      env:
        GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}
      run: |
        nix develop -c ggshield secret scan ci
```

**Impact**: Eliminates 1 third-party action, consistent with nix-first approach

### Priority 4: Consider Eliminating nothing-but-nix Action

The `wimpysworld/nothing-but-nix` action could be replaced with our own disk cleanup script:

```yaml
# In setup-nix composite action
- name: Reclaim disk space (Linux)
  if: runner.os == 'Linux' && inputs.installer == 'full'
  shell: bash
  run: |
    # Remove unnecessary tools
    sudo rm -rf /opt/hostedtoolcache
    sudo rm -rf /usr/share/dotnet
    sudo rm -rf /usr/local/lib/android
    # ... etc
```

**Benefits**: One less external dependency
**Tradeoffs**: We maintain the cleanup logic instead of relying on nothing-but-nix

## Summary of Optimizations

| Optimization | Priority | Lines Saved | Actions Removed | CI Time Saved |
|--------------|----------|-------------|-----------------|---------------|
| setup-project composite action | High | ~39 | 0 | 0 min |
| Eliminate redundant build | High | ~20 | 0 | 1-2 min |
| GitGuardian → ggshield CLI | Medium | ~5 | 1 | 0 min |
| Replace nothing-but-nix | Low | 0 | 1 | 0 min |
| Replace post-run-action | Low | ~10 | 1 | 0 min |

**Total Potential**:
- **~74 lines** of code reduction
- **1-3 third-party actions** eliminated
- **1-2 minutes** faster CI runs
- **Significant maintainability improvement**

## Recommendations

### Immediate (Do Now):
1. ✅ Create `setup-project` composite action
2. ✅ Eliminate redundant build in test/build jobs

### Soon (Next Week):
3. Add `ggshield` to devShell, replace GitGuardian action
4. Consider consolidating test + build jobs entirely

### Later (When Time Permits):
5. Replace nothing-but-nix with custom cleanup
6. Extract conditional logic patterns

### Never:
- Don't eliminate: actions/checkout, upload/download-artifact (core GitHub)
- Don't eliminate: DeterminateSystems/nix-installer (Nix experts maintain)
- Keep: mxschmitt/action-tmate (useful debug tool, conditional only)
