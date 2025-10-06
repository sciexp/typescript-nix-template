# Handoff Prompt: Package Renaming Implementation

## Context

**Repository**: `/Users/crs58/projects/nix-workspace/starlight-nix-template`
**Current branch**: `01-refactor-monorepo-migration`
**Status**: Monorepo migration complete and validated, CI passing

## What Was Decided

Comprehensive naming strategy analysis completed with ultrathink reasoning.
All analysis documents committed to branch.

**Decision**: Rename `@sciexp/starlight-docs` → `@sciexp/docs` for framework-agnostic template naming.

**Key rationale:**
- Removes framework-specific naming (Starlight/Astro)
- Works for both sciexp deployment and forkable template
- Follows python-nix-template conventions
- Preserves top-level subdomain namespace

## Changes Required

### Package naming
- **Current**: `@sciexp/starlight-docs`
- **New**: `@sciexp/docs`

### Directory structure
- **Current**: `packages/starlight-docs/`
- **New**: `packages/docs/`

### Wrangler configuration
- **Worker name**: `ts-nix-docs`
- **Route**: `ts-nix.scientistexperience.net` (was `starlight.scientistexperience.net`)

### Rationale for subdomain
The `docs.*` subdomain is reserved for org-wide documentation, not individual project templates.
Using `ts-nix.*` preserves namespace and identifies this specific template project.

## Files Requiring Updates

**Total**: 11 files (plus 1 directory rename)

### Critical files
1. `packages/starlight-docs/` → `packages/docs/` (directory rename)
2. `packages/docs/package.json`
3. `packages/docs/wrangler.jsonc`
4. `packages/docs/README.md`

### Documentation files
5. `README.md`
6. `CONTRIBUTING.md`
7. `docs/notes/migration/monorepo-migration-plan.md`

### Build/CI files
8. `justfile`
9. `.github/workflows/ci.yaml`
10. `.github/workflows/release.yaml`
11. `.github/workflows/deploy-docs.yaml`

## Detailed Implementation Steps

### Step 1: Rename directory

```bash
git mv packages/starlight-docs packages/docs
git add -A
git commit -m "refactor(docs): rename package directory

- Rename packages/starlight-docs → packages/docs
- Aligns with framework-agnostic package naming strategy"
```

### Step 2: Update packages/docs/package.json

**File**: `packages/docs/package.json`

**Changes:**
1. Line 2: `"name": "@sciexp/starlight-docs"` → `"name": "@sciexp/docs"`
2. Line 5: `"description": "Starlight documentation site for sciexp projects"` → `"description": "Documentation site for sciexp projects"`
3. Lines 107-108 in `release.plugins` array, find `semantic-release-major-tag`:
   ```json
   "customTags": [
     "starlight-docs-v${major}",
     "starlight-docs-v${major}.${minor}"
   ]
   ```
   Replace with:
   ```json
   "customTags": [
     "docs-v${major}",
     "docs-v${major}.${minor}"
   ]
   ```

**Commit:**
```bash
git add packages/docs/package.json
git commit -m "refactor(docs): update package name and release tags

- Change package name: @sciexp/starlight-docs → @sciexp/docs
- Update description to be framework-agnostic
- Update semantic-release tags: docs-v* instead of starlight-docs-v*"
```

### Step 3: Update packages/docs/wrangler.jsonc

**File**: `packages/docs/wrangler.jsonc`

**Changes:**
1. Line 7: `"name": "starlight-nix-template"` → `"name": "ts-nix-docs"`
2. Line 25: `"pattern": "starlight.scientistexperience.net"` → `"pattern": "ts-nix.scientistexperience.net"`

**Result should be:**
```json
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "ts-nix-docs",
  "main": "./dist/_worker.js/index.js",
  "compatibility_date": "2025-10-06",
  "compatibility_flags": ["nodejs_compat", "global_fetch_strictly_public"],
  "assets": {
    "binding": "ASSETS",
    "directory": "./dist"
  },
  "observability": {
    "enabled": true
  },
  "dev": {
    "port": 4321
  },
  "workers_dev": false,
  "preview_urls": true,
  "routes": [
    {
      "pattern": "ts-nix.scientistexperience.net",
      "custom_domain": true
    }
  ]
}
```

**Commit:**
```bash
git add packages/docs/wrangler.jsonc
git commit -m "refactor(docs): update wrangler deployment config

- Worker name: ts-nix-docs
- Route: ts-nix.scientistexperience.net
- Preserves docs.* namespace for org-wide documentation"
```

### Step 4: Update packages/docs/README.md

**File**: `packages/docs/README.md`

**Changes:**
1. Line 1: `# @sciexp/starlight-docs` → `# @sciexp/docs`
2. Line 5: Keep existing description or update if it mentions "Starlight" in a way that feels too specific
3. Line 45: `bun run --filter '@sciexp/starlight-docs' dev` → `bun run --filter '@sciexp/docs' dev`
4. Line 50: `bun run --filter '@sciexp/starlight-docs' build` → `bun run --filter '@sciexp/docs' build`

**Search and replace pattern**: `@sciexp/starlight-docs` → `@sciexp/docs`

**Commit:**
```bash
git add packages/docs/README.md
git commit -m "docs(docs): update package references in README

- Update package name throughout
- Update filter patterns in examples"
```

### Step 5: Update README.md (root)

**File**: `README.md`

**Changes:**
1. Line 11: `[@sciexp/starlight-docs](./packages/starlight-docs)` → `[@sciexp/docs](./packages/docs)`
2. Line 18: `    └── starlight-docs/` → `    └── docs/`
3. Line 64: `just pkg starlight-docs` → `just pkg docs`
4. Lines 93-95: Update all filter patterns:
   - `bun run --filter '@sciexp/starlight-docs' dev` → `bun run --filter '@sciexp/docs' dev`
   - `bun run --filter '@sciexp/starlight-docs' build` → `bun run --filter '@sciexp/docs' build`
   - `bun run --filter '@sciexp/starlight-docs' test` → `bun run --filter '@sciexp/docs' test`

**Search and replace patterns:**
- `@sciexp/starlight-docs` → `@sciexp/docs`
- `./packages/starlight-docs` → `./packages/docs`
- `packages/starlight-docs/` → `packages/docs/`
- `starlight-docs` (as package name) → `docs`

**Commit:**
```bash
git add README.md
git commit -m "docs: update root README with new package name

- Update package references and links
- Update directory paths
- Update all filter pattern examples"
```

### Step 6: Update CONTRIBUTING.md

**File**: `CONTRIBUTING.md`

**Changes:**
Update all scope examples throughout:
- Line 35: `- \`starlight-docs\`: for changes` → `- \`docs\`: for changes`
- Line 54: `feat(starlight-docs): add` → `feat(docs): add`
- Line 57: `fix(starlight-docs): handle` → `fix(docs): handle`
- Line 60: `feat(starlight-docs)!: migrate` → `feat(docs)!: migrate`
- Line 65: `refactor(starlight-docs,sqlrooms` → `refactor(docs,sqlrooms`
- Line 68: `docs(starlight-docs): update` → `docs(docs): update` (or just `docs: update`)
- Line 89: `just test-pkg starlight-docs` → `just test-pkg docs`
- Line 105: `bun run --filter '@sciexp/starlight-docs' build` → `bun run --filter '@sciexp/docs' build`

**Search and replace pattern**: `starlight-docs` → `docs` (but check context for scope vs package)

**Commit:**
```bash
git add CONTRIBUTING.md
git commit -m "docs: update CONTRIBUTING with new scope examples

- Update commit scope examples: starlight-docs → docs
- Update command examples with new package name"
```

### Step 7: Update justfile

**File**: `justfile`

**Changes:**
Search and replace ALL occurrences of `'@sciexp/starlight-docs'` with `'@sciexp/docs'`

**Specific lines** (approximate, verify actual line numbers):
- Line 256: `bun run --filter '@sciexp/starlight-docs' preview`
- Line 261: `bun run --filter '@sciexp/starlight-docs' deploy`
- Line 324: `bun run --filter '@sciexp/starlight-docs' dev`
- Line 329: `bun run --filter '@sciexp/starlight-docs' build`
- Line 334: `bun run --filter '@sciexp/starlight-docs' preview`
- Line 565: `bun run --filter '@sciexp/starlight-docs' test:unit`
- Line 570: `bun run --filter '@sciexp/starlight-docs' test:e2e`
- Line 575: `bun run --filter '@sciexp/starlight-docs' test:watch`
- Line 580: `bun run --filter '@sciexp/starlight-docs' test:ui`
- Line 585: `bun run --filter '@sciexp/starlight-docs' test:coverage`

**Also update comments if they reference the old name.**

**Commit:**
```bash
git add justfile
git commit -m "refactor(docs): update justfile filter patterns

- Replace all @sciexp/starlight-docs → @sciexp/docs
- Update all task commands with new package name"
```

### Step 8: Update .github/workflows/ci.yaml

**File**: `.github/workflows/ci.yaml`

**Changes:**
Find the matrix definition (around line 45-48):
```yaml
matrix:
  package:
    - name: starlight-docs
      path: packages/starlight-docs
```

Replace with:
```yaml
matrix:
  package:
    - name: docs
      path: packages/docs
```

**Note**: The workflow already uses `${{ matrix.package.name }}` variables, so most references will automatically update. Only the matrix definition needs changing.

**Commit:**
```bash
git add .github/workflows/ci.yaml
git commit -m "ci: update test matrix with new package name

- Update matrix package name: starlight-docs → docs
- Update package path: packages/starlight-docs → packages/docs"
```

### Step 9: Update .github/workflows/release.yaml

**File**: `.github/workflows/release.yaml`

**Changes:**
Find the matrix definition (around line 19-21):
```yaml
matrix:
  package:
    - name: starlight-docs
      path: packages/starlight-docs
```

Replace with:
```yaml
matrix:
  package:
    - name: docs
      path: packages/docs
```

**Commit:**
```bash
git add .github/workflows/release.yaml
git commit -m "ci: update release matrix with new package name

- Update matrix package name: starlight-docs → docs
- Update package path: packages/starlight-docs → packages/docs"
```

### Step 10: Update .github/workflows/deploy-docs.yaml

**File**: `.github/workflows/deploy-docs.yaml`

**Changes:**
Find the build command (around line 83):
```yaml
run: nix develop -c bun run --filter '@sciexp/starlight-docs' build
```

Replace with:
```yaml
run: nix develop -c bun run --filter '@sciexp/docs' build
```

**Also check for any path references to `packages/starlight-docs` and update to `packages/docs`.**

**Commit:**
```bash
git add .github/workflows/deploy-docs.yaml
git commit -m "ci: update deploy workflow with new package name

- Update filter pattern: @sciexp/starlight-docs → @sciexp/docs
- Update any path references to packages/docs"
```

### Step 11: Update docs/notes/migration/monorepo-migration-plan.md

**File**: `docs/notes/migration/monorepo-migration-plan.md`

**Changes:**
This file has MANY references. Use search and replace:

**Search patterns and replacements:**
1. `@sciexp/starlight-docs` → `@sciexp/docs`
2. `packages/starlight-docs/` → `packages/docs/`
3. `"name": "starlight-docs"` → `"name": "docs"` (in matrix examples)
4. `path: packages/starlight-docs` → `path: packages/docs`
5. `starlight-docs-v${major}` → `docs-v${major}` (in tag examples)
6. `feat(starlight-docs):` → `feat(docs):` (in commit examples)
7. `fix(starlight-docs):` → `fix(docs):` (in commit examples)
8. `docs(starlight-docs):` → `docs(docs):` or just `docs:` (in commit examples)

**Be thorough** - this file is comprehensive documentation.

**Commit:**
```bash
git add docs/notes/migration/monorepo-migration-plan.md
git commit -m "docs(migration): update plan with final package names

- Replace all starlight-docs references with docs
- Update all directory paths
- Update all commit scope examples
- Update all tag examples"
```

## Testing and Verification

After all commits are complete, run these verification steps:

### 1. Verify workspace resolution

```bash
bun install
```

**Expected**: No errors, workspace resolves `@sciexp/docs` correctly.

### 2. Run build

```bash
just build
# or
bun run --filter '@sciexp/docs' build
```

**Expected**: Build succeeds, output in `packages/docs/dist/`

### 3. Run tests

```bash
just test-unit
just test-e2e
# or
just test
```

**Expected**: All tests pass.

### 4. Verify Nix flake

```bash
nix flake check --impure
```

**Expected**: All checks pass.

### 5. Test semantic-release

```bash
bun run test-release
# or from package directory
cd packages/docs && bun run test-release
```

**Expected**: Dry run succeeds, shows new tag format `docs-v*`.

### 6. Format and lint

```bash
just format
just lint
```

**Expected**: No issues.

### 7. Verify no missed references

```bash
# Search for any remaining old references
grep -r "starlight-docs" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
  --exclude-dir=docs/notes/naming .
```

**Expected**: Only hits in `docs/notes/naming/` (our strategy docs showing the change).

## Success Criteria

- ✅ All 11 files updated
- ✅ Directory renamed: packages/docs/
- ✅ Package name: @sciexp/docs
- ✅ Wrangler: ts-nix-docs @ ts-nix.scientistexperience.net
- ✅ Build succeeds
- ✅ Tests pass (unit + E2E)
- ✅ Nix flake check passes
- ✅ Semantic-release dry run works
- ✅ No old references remain (except strategy docs)
- ✅ Each change committed atomically

## Final Commit Summary

After all commits, provide summary:

```bash
# Get commit hash from start of this session
START_HASH="c8897dc"  # From gitStatus

# Get current HEAD
END_HASH=$(git rev-parse HEAD)

# Show all commits from this session
git log --oneline $START_HASH..$END_HASH
```

## Reference Documentation

All detailed analysis and rationale in:
- `docs/notes/naming/ultrathink-analysis-summary.md` - Comprehensive strategy analysis
- `docs/notes/naming/naming-strategy-implementation.md` - Detailed implementation guide
- `docs/notes/naming/subdomain-strategy.md` - Subdomain strategy and rationale
- `docs/notes/naming/action-plan.md` - Quick reference checklist

## Important Notes

### User's Git Preferences

From user's preferences (`.claude/commands/preferences/git-version-control.md`):
- **Create atomic commits after each file edit** without waiting for instruction
- **Stage and commit immediately** after each edit
- Never stage all files at once - stage each file individually
- Use succinct conventional commit messages
- Test locally when reasonable (do all tests at the end)

### Commit Message Format

```
<type>(<scope>): <subject>

<body>
```

Types: refactor, docs, ci
Scope: docs, migration
Keep messages concise and descriptive.

### Edge Cases

1. If grep shows references in other docs (not in strategy docs), evaluate if they need updating
2. The directory rename must happen FIRST before updating paths
3. Workflow matrix variables (`${{ matrix.package.name }}`) automatically adapt, only matrix definitions need updates
4. Some docs mention "starlight-nix-template" as the old repo name - these are historical context, don't update unless they're actively used configuration

## Questions You Might Have

**Q: Should I update nix/modules/devshell.nix `name = "starlight-nix-template-dev"`?**
A: Optional. It's just an internal shell name. If you do, use `"ts-nix-dev"` and commit separately.

**Q: Should I update docs/notes/ci/ci-docs-deploy.md with new package name?**
A: Optional. It has example GitHub URLs but they're in user instructions for the old structure. Can leave as-is or update in a separate commit.

**Q: What about the naming strategy docs themselves?**
A: DO NOT update `docs/notes/naming/*.md` - these document the change from old to new.

**Q: What if I find more files with references?**
A: Evaluate if they're:
- Active configuration (update)
- Historical documentation (probably leave)
- Generated files (don't commit)
Commit any additional updates separately with descriptive messages.

## Ready to Execute

All information provided. You can now execute the renaming implementation autonomously.

Follow the 11-step plan, commit atomically after each file, then run verification tests.

If all tests pass, push the branch and report completion with commit summary.
