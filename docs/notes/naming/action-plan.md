# Naming strategy: immediate action plan

## Decision summary

**Rename**: `@sciexp/starlight-docs` → `@sciexp/docs`

**Rationale**: Framework-agnostic naming that works for both sciexp deployment and as a forkable template.

## Immediate actions (before merge)

### 1. Rename directory

```bash
git mv packages/starlight-docs packages/docs
```

### 2. Update packages/docs/package.json

Find and replace:
- `"name": "@sciexp/starlight-docs"` → `"name": "@sciexp/docs"`
- `"description": "Starlight documentation site for sciexp projects"` → `"description": "Documentation site for sciexp projects"`
- In `release.plugins`, find `semantic-release-major-tag` config:
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

### 3. Update packages/docs/wrangler.jsonc

```json
{
  "name": "sciexp-docs",
  "routes": [
    {
      "pattern": "docs.scientistexperience.net",
      "custom_domain": true
    }
  ]
}
```

### 4. Update packages/docs/README.md

- Line 1: `# @sciexp/starlight-docs` → `# @sciexp/docs`
- Line 5: Update description if it mentions "Starlight"
- Line 45: `bun run --filter '@sciexp/starlight-docs' dev` → `bun run --filter '@sciexp/docs' dev`
- Line 50: Similar for build command
- Search for any other `starlight-docs` references

### 5. Update root README.md

- Line 11: `[@sciexp/starlight-docs](./packages/starlight-docs)` → `[@sciexp/docs](./packages/docs)`
- Line 18: `└── starlight-docs/` → `└── docs/`
- Line 64: `just pkg starlight-docs` → `just pkg docs`
- Lines 94, 95: Filter patterns `@sciexp/starlight-docs` → `@sciexp/docs`
- Line 134: Similar updates in test commands

### 6. Update CONTRIBUTING.md

Replace all scope examples:
- Line 35: `starlight-docs:` → `docs:`
- Line 36: `sqlrooms-hf-ducklake:` (keep as is for future)
- Line 54: `feat(starlight-docs):` → `feat(docs):`
- Line 57: `fix(starlight-docs):` → `fix(docs):`
- Line 60: `feat(starlight-docs)!:` → `feat(docs)!:`
- Line 65: `refactor(starlight-docs,sqlrooms-hf-ducklake):` → `refactor(docs,sqlrooms-hf-ducklake):`
- Line 68: `docs(starlight-docs):` → `docs(docs):` (might want to change to just `docs:` or use different scope)
- Line 89: `just test-pkg starlight-docs` → `just test-pkg docs`
- Line 105: `bun run --filter '@sciexp/starlight-docs' build` → `bun run --filter '@sciexp/docs' build`
- Line 134: Test commands

### 7. Update .github/workflows/ci.yaml

Find the matrix definition:
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

Also update filter patterns:
- `bun run --filter '@sciexp/${{ matrix.package.name }}'` (already uses variable, should work)
- Check any hardcoded references to `starlight-docs`

### 8. Update .github/workflows/release.yaml

Similar matrix update:
```yaml
matrix:
  package:
    - name: docs
      path: packages/docs
```

### 9. Update .github/workflows/deploy-docs.yaml

Find references to `packages/starlight-docs` and update to `packages/docs`:
- Path references in `cd` commands
- Filter patterns in bun commands

### 10. Update justfile

Find and replace all:
- `'@sciexp/starlight-docs'` → `'@sciexp/docs'`
- `starlight-docs` → `docs` (in commands and comments)

Specific lines to check:
- `test-unit`, `test-e2e` commands
- `dev`, `build`, `preview` commands
- Any comments referencing the package

### 11. Update docs/notes/migration/monorepo-migration-plan.md

This file has many references. Search and replace:
- `@sciexp/starlight-docs` → `@sciexp/docs`
- `packages/starlight-docs/` → `packages/docs/`
- `starlight-docs` → `docs` (in scopes, tags, etc.)
- Update wrangler config examples
- Update tag examples: `starlight-docs-v1.0.0` → `docs-v1.0.0`

## Testing checklist

After making all changes:

```bash
# Verify workspace resolution
bun install

# Build
just build

# Tests
just test-unit
just test-e2e

# Nix checks
nix flake check --impure

# Semantic-release dry run
bun run test-release

# Check CI will pass
just format
just lint
```

## Commit the changes

```bash
git add -A
git commit -m "refactor(docs): rename to framework-agnostic package name

- Rename @sciexp/starlight-docs → @sciexp/docs
- Update directory: packages/starlight-docs → packages/docs
- Update wrangler: sciexp-docs @ docs.scientistexperience.net
- Update all documentation and workflow references
- Update commit scope examples in CONTRIBUTING.md

This change makes the template more framework-agnostic and easier
to fork while remaining a legitimate deployment for sciexp."
```

## Push and verify

```bash
git push
```

Monitor GitHub Actions to ensure:
- All workflows pass
- No broken references
- Deployment works (if auto-deployed)

## Optional: Update Cloudflare DNS

If DNS needs updating for new subdomain:
- Add CNAME: `docs.scientistexperience.net` → Cloudflare Worker
- Update custom domain in Cloudflare Workers dashboard
- Or this might be handled automatically by wrangler

## Files for reference

- Full analysis: `docs/notes/naming/ultrathink-analysis-summary.md`
- Implementation details: `docs/notes/naming/naming-strategy-implementation.md`
- Omnix template: `nix/modules/template.nix`
