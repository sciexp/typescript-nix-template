# Naming strategy implementation plan

## Overview

This document outlines the implementation of the framework-agnostic naming strategy for `typescript-nix-template`.

## Changes required

### 1. Directory restructure

```bash
mv packages/starlight-docs packages/docs
```

### 2. Package configuration updates

#### packages/docs/package.json

```json
{
  "name": "@sciexp/docs",
  "description": "Documentation site for sciexp projects",
  // ... rest of config
  "release": {
    "plugins": [
      // ...
      [
        "semantic-release-major-tag",
        {
          "customTags": [
            "docs-v${major}",
            "docs-v${major}.${minor}"
          ]
        }
      ]
    ]
  }
}
```

#### packages/docs/wrangler.jsonc

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

### 3. Documentation updates

#### Root README.md

- Update package name: `@sciexp/docs`
- Update path: `packages/docs`
- Update commit scope examples: `feat(docs): ...`

#### packages/docs/README.md

- Update package name throughout
- Update title to `# @sciexp/docs`
- Update build/test commands if needed

#### CONTRIBUTING.md

- Update scope examples: `starlight-docs` → `docs`
- Update commit examples

#### docs/notes/migration/monorepo-migration-plan.md

- Update all references to package name
- Update tag strategy section
- Update deployment pattern

### 4. Workflow updates

#### .github/workflows/ci.yaml

```yaml
matrix:
  package:
    - name: docs
      path: packages/docs
```

Update all filter patterns:
```bash
bun run --filter '@sciexp/docs' ...
```

#### .github/workflows/release.yaml

```yaml
matrix:
  package:
    - name: docs
      path: packages/docs
```

#### .github/workflows/deploy-docs.yaml

Update paths:
```yaml
- name: Build
  run: |
    cd packages/docs
    nix develop -c bunx astro build
```

### 5. Justfile updates

Update all references:
```justfile
# From
test-unit:
  bun run --filter '@sciexp/starlight-docs' test:unit

# To
test-unit:
  bun run --filter '@sciexp/docs' test:unit
```

### 6. Additional file updates

Check and update these files if they reference the old package name:
- `.github/actions/*/action.yaml`
- Any scripts in `scripts/`
- Package-specific README files

## Testing checklist

After making changes:

- [ ] `bun install` - verify workspace resolution
- [ ] `just build` - verify build succeeds
- [ ] `just test-unit` - verify unit tests pass
- [ ] `just test-e2e` - verify E2E tests pass
- [ ] `nix flake check --impure` - verify nix configuration
- [ ] `bun run test-release` - verify semantic-release dry run
- [ ] Check CI passes on PR

## Template user experience

When users fork this template:

### Manual approach

1. Clone/fork repository
2. Update root `package.json`: name, repository.url, description
3. Rename `packages/docs/` to their package name
4. Update `packages/{name}/package.json`: name, description
5. Update `packages/{name}/wrangler.jsonc`: name, routes
6. Update `CONTRIBUTING.md` scope examples
7. Update workflow matrices if package name changed

### Omnix approach (future)

```bash
om init --template github:sciexp/typescript-nix-template myproject
# Prompted for:
# - Package scope: @myorg
# - Git org: myorg
# - Example package name: docs
# - Include GitHub CI: yes
```

## Deployment pattern

### For sciexp

- Package: `@sciexp/docs`
- Worker: `sciexp-docs`
- Route: `docs.scientistexperience.net`

Future packages:
- `@sciexp/sqlrooms` → `sciexp-sqlrooms` → `sqlrooms.scientistexperience.net`

### For template users

Recommended pattern:
- Package: `@{scope}/{name}`
- Worker: `{scope}-{name}`
- Route: `{name}.{domain}` or `{subdomain}.{domain}`

Example:
- `@acme/docs` → `acme-docs` → `docs.acme.com`
- `@acme/app` → `acme-app` → `app.acme.com`

## Success criteria

- ✅ No framework-specific names (Starlight, Astro) in package names
- ✅ Template is immediately useful when forked
- ✅ Clear, minimal customization path documented
- ✅ Pattern scales to multiple packages
- ✅ Professional for public deployment
- ✅ Aligns with semantic-release conventional commits
- ✅ Namespace-safe (doesn't collide with existing projects)
