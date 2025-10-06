# Template naming strategy: ultrathink analysis summary

## Executive summary

**Recommendation**: Rename `@sciexp/starlight-docs` → `@sciexp/docs` with corresponding updates to directory structure, wrangler configuration, and documentation.

**Rationale**: Framework-agnostic naming that serves both as a working sciexp deployment and a forkable template, following the pattern established by python-nix-template.

## The core problem

This repository serves two simultaneous purposes:

1. **Live deployment** for sciexp demonstrating semantic-release
2. **Forkable template** for others to use as a TypeScript monorepo starting point

Current naming (`starlight-docs`) is framework-specific, making it:
- Tied to Astro Starlight implementation details
- Less reusable as a template
- Awkward for users to understand what to customize

## Solution: Generic, purpose-based naming

Following python-nix-template's approach, use names that work for both purposes.

### Recommended naming changes

| Component | Current | New | Rationale |
|-----------|---------|-----|-----------|
| Package name | `@sciexp/starlight-docs` | `@sciexp/docs` | Generic, framework-agnostic, legitimate for both uses |
| Directory | `packages/starlight-docs/` | `packages/docs/` | Matches package name |
| Wrangler name | `starlight-nix-template` | `sciexp-docs` | Professional deployment name |
| Route | `starlight.scientistexperience.net` | `docs.scientistexperience.net` | Clean subdomain pattern |
| Commit scope | `starlight-docs` | `docs` | Shorter, framework-independent |
| Tags | `starlight-docs-v1.0.0` | `docs-v1.0.0` | Matches package name |

### Why `@sciexp/docs` is optimal

1. **Template perspective**: Most projects need documentation - this is immediately useful
2. **Sciexp perspective**: Legitimately serves as general sciexp documentation
3. **Framework independence**: No mention of Astro/Starlight
4. **Brevity**: Shortest meaningful name
5. **Pattern clarity**: `@{scope}/{purpose}` scales to multiple packages
6. **Namespace safety**: Common enough not to collide, generic enough to be flexible

## Deployment pattern

### Recommended pattern for monorepo packages

```
Package: @{scope}/{name}
Worker:  {scope}-{name}
Route:   {name}.{domain}
```

### Examples

**For sciexp:**
- `@sciexp/docs` → worker: `sciexp-docs` → `docs.scientistexperience.net`
- `@sciexp/sqlrooms` → worker: `sciexp-sqlrooms` → `sqlrooms.scientistexperience.net`

**For template users:**
- `@acme/docs` → worker: `acme-docs` → `docs.acme.com`
- `@acme/app` → worker: `acme-app` → `app.acme.com`

This pattern is:
- Consistent across all deployments
- Easy to understand and replicate
- Professional for production use
- Scalable to many packages

## Template user experience

### Current approach (manual customization)

When users fork `typescript-nix-template`:

1. Clone/fork the repository
2. Update root `package.json` (name, repo URL, description)
3. Rename `packages/docs/` to their package name
4. Update `packages/{name}/package.json` (name, description, release tags)
5. Update `packages/{name}/wrangler.jsonc` (name, routes)
6. Update `CONTRIBUTING.md` (scope examples)
7. Update workflow matrices if package names changed

**Assessment**: Manageable but multiple touchpoints. Clear documentation needed.

### Enhanced approach (with omnix)

Created `nix/modules/template.nix` following python-nix-template pattern:

```bash
om init --template github:sciexp/typescript-nix-template myproject
```

Users prompted for:
- Package scope (e.g., `@myorg`)
- Git organization
- Author information
- Optional features (GitHub CI, etc.)

**Benefits**:
- Single command initialization
- Automatic placeholder replacement
- Conditional inclusion of components
- Reduced manual configuration

## Omnix integration analysis

### What omnix templates provide

From python-nix-template analysis:

1. **Parameterization**: Replace package names, organization, author info automatically
2. **Conditional paths**: Include/exclude directories based on user choices
3. **Template tests**: Verify template instantiation works correctly
4. **Welcome text**: Guide users through initial setup

### Implementation for typescript-nix-template

Created `nix/modules/template.nix` with:

**Parameters:**
- `package-scope`: npm package scope (default: `@sciexp`)
- `git-org`: GitHub organization (default: `sciexp`)
- `author`: Author name
- `author-email`: Author email
- `project-description`: Project description

**Conditional paths:**
- `github-ci`: Include/exclude `.github` directory
- `nix-template`: Keep/remove template metadata

**Tests:**
- Verify essential files present
- Check package builds successfully
- Ensure template metadata removed when requested

### Benefits of omnix integration

1. **Better template UX**: One command vs multiple manual steps
2. **Follows conventions**: Aligns with python-nix-template
3. **Reduces errors**: Automated replacement prevents missing updates
4. **Discoverable**: Listed in omnix template catalog
5. **Testable**: Template tests ensure it works correctly

## Dummy release strategy

### Current state

- `npmPublish: false` - not publishing to npm
- Releases create GitHub releases and tags only
- CHANGELOG.md generated and committed back
- Demonstrates semantic-release workflow

### Recommendation: Keep current approach

**Rationale:**
1. Template is for demonstration, not publication
2. Shows semantic versioning workflow effectively
3. Illustrates per-package tagging in monorepos
4. Models proper conventional commit patterns

**Do not add dummy second package**:
- Adds confusion without value
- Wait for real second package (`@sciexp/sqlrooms-hf-ducklake`)
- Current single-package setup is sufficient demonstration
- Migration plan already documents multi-package pattern excellently

## Implementation plan

### Phase 1: Rename package (before merge)

**Priority: Complete before merging 01-refactor-monorepo-migration**

1. Rename directory:
   ```bash
   git mv packages/starlight-docs packages/docs
   ```

2. Update package configuration:
   - `packages/docs/package.json`: name, description, tags
   - `packages/docs/wrangler.jsonc`: name, routes

3. Update documentation:
   - Root `README.md`: package references, examples
   - `packages/docs/README.md`: title, package name
   - `CONTRIBUTING.md`: scope examples
   - `docs/notes/migration/monorepo-migration-plan.md`: all references

4. Update workflows:
   - `.github/workflows/ci.yaml`: matrix, filter patterns
   - `.github/workflows/release.yaml`: matrix
   - `.github/workflows/deploy-docs.yaml`: paths

5. Update justfile:
   - All filter patterns: `@sciexp/starlight-docs` → `@sciexp/docs`

6. Test locally:
   ```bash
   bun install
   just build
   just test-unit
   just test-e2e
   nix flake check --impure
   bun run test-release
   ```

7. Commit changes:
   ```bash
   git add .
   git commit -m "refactor(docs): rename to framework-agnostic package name

   - Rename @sciexp/starlight-docs → @sciexp/docs
   - Update directory: packages/starlight-docs → packages/docs
   - Update wrangler: sciexp-docs @ docs.scientistexperience.net
   - Update all documentation and workflow references
   - Update commit scope examples in CONTRIBUTING.md

   This change makes the template more framework-agnostic and easier
   to fork while remaining a legitimate deployment for sciexp."
   ```

8. Push and verify CI

### Phase 2: Omnix integration (after merge, optional)

**Priority: Optional enhancement, can be done later**

1. Template already created: `nix/modules/template.nix`

2. Test template:
   ```bash
   # From outside the repo
   nix flake init --template github:sciexp/typescript-nix-template
   # or with omnix
   om init --template github:sciexp/typescript-nix-template test-project
   ```

3. Verify parameterization works correctly

4. Add to omnix template catalog (if desired)

5. Document in README:
   ```markdown
   ## Using as a template

   ### Option 1: GitHub template
   Click "Use this template" on GitHub

   ### Option 2: Nix flake
   nix flake init --template github:sciexp/typescript-nix-template

   ### Option 3: Omnix (recommended)
   om init --template github:sciexp/typescript-nix-template myproject
   ```

### Phase 3: Add second package (future)

**Priority: Wait for real package need**

When adding `@sciexp/sqlrooms-hf-ducklake`:

1. Create package structure following pattern:
   ```bash
   mkdir -p packages/sqlrooms
   ```

2. Follow multi-package pattern from migration plan

3. Update workflow matrices

4. Demonstrates multi-package semantic-release

## Files created/modified in this analysis

### Created

1. `docs/notes/naming/naming-strategy-implementation.md` - Detailed implementation plan
2. `docs/notes/naming/ultrathink-analysis-summary.md` - This document
3. `nix/modules/template.nix` - Omnix template configuration

### To be modified (Phase 1)

1. `packages/starlight-docs/` → `packages/docs/` (directory rename)
2. `packages/docs/package.json` - name, tags
3. `packages/docs/wrangler.jsonc` - name, routes
4. `packages/docs/README.md` - package references
5. Root `README.md` - package references
6. `CONTRIBUTING.md` - scope examples
7. `docs/notes/migration/monorepo-migration-plan.md` - update all references
8. `.github/workflows/ci.yaml` - matrix, filters
9. `.github/workflows/release.yaml` - matrix
10. `.github/workflows/deploy-docs.yaml` - paths
11. `justfile` - filter patterns

## Success criteria

All criteria met by this strategy:

- ✅ **Framework independence**: No "Starlight" or "Astro" in names
- ✅ **Template reusability**: `@sciexp/docs` works for template users
- ✅ **Clarity**: Purpose-based naming is immediately understandable
- ✅ **Brevity**: Shortest meaningful names
- ✅ **Omnix alignment**: Follows python-nix-template conventions
- ✅ **Demonstrates semantic-release**: Current setup is sufficient
- ✅ **Namespace safety**: Generic enough not to collide
- ✅ **Scalable pattern**: Extends naturally to multiple packages
- ✅ **Professional deployment**: Clean, production-ready naming

## Questions addressed

### 1. Package name?

**Answer**: `@sciexp/docs`

**Why not alternatives**:
- `@sciexp/starlight-docs` - Framework-specific
- `@sciexp/template-docs` - Awkward, unclear meaning
- `@sciexp/monorepo-docs` - Self-referential
- `@sciexp/example-site` - Less specific than "docs"

### 2. Directory name?

**Answer**: `packages/docs/`

Matches package name for consistency.

### 3. Wrangler deployment?

**Answer**:
- Name: `sciexp-docs`
- Route: `docs.scientistexperience.net`

Pattern: `{scope}-{package}` for name, `{package}.{domain}` for route

### 4. Dummy release strategy?

**Answer**: Keep current approach (GitHub releases only, no npm publish)

Do not add dummy second package - wait for real need.

### 5. Second package pattern?

**Answer**: Follow same pattern when needed
- `@sciexp/sqlrooms` → `sciexp-sqlrooms` → `sqlrooms.scientistexperience.net`

## Comparison with alternatives considered

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| Keep `starlight-docs` | No work, honest about implementation | Framework-specific, poor template UX | ❌ Reject |
| Use `template-docs` | Clear it's an example | Awkward naming, must rename | ❌ Reject |
| Use `monorepo-docs` | Describes purpose | Self-referential, framework still visible | ❌ Reject |
| Use `example-site` | Generic, clear | Too vague, "site" is still specific | ❌ Reject |
| Use `docs` | Generic, brief, works for both | Requires renaming "starlight" references | ✅ **Recommended** |

## Alignment with omnix standards

Python-nix-template establishes the pattern:

1. **Template works as-is**: python-nix-template is a real, deployed project
2. **Generic naming**: Package is `python-nix-template`, not `python-pytest-mkdocs-template`
3. **Purpose-based**: Describes what it does, not how it does it
4. **Parameterized**: Users customize through omnix or manual edits
5. **Conditional components**: Optional features via omnix paths

Our approach follows all five principles:

1. ✅ Works as-is: `typescript-nix-template` with `@sciexp/docs` is deployed
2. ✅ Generic naming: No framework names (Starlight/Astro) in package name
3. ✅ Purpose-based: "docs" describes purpose, not implementation
4. ✅ Parameterized: Created `template.nix` with parameters
5. ✅ Conditional: GitHub CI, template metadata are optional

## Next steps

1. **Immediate (before merge)**:
   - Execute Phase 1 renaming
   - Test locally
   - Verify CI passes
   - Merge `01-refactor-monorepo-migration` branch

2. **Short-term (after merge)**:
   - Test omnix template initialization
   - Document template usage in README
   - Consider adding to omnix catalog

3. **Medium-term (when needed)**:
   - Add second real package (e.g., `@sciexp/sqlrooms`)
   - Demonstrate multi-package semantic-release
   - Refine template based on usage

## Conclusion

The recommendation to rename `@sciexp/starlight-docs` → `@sciexp/docs` with corresponding infrastructure updates achieves all objectives:

- Framework-independent naming that ages well
- Works as both a template and a real deployment
- Follows omnix template conventions
- Clear, minimal customization path for users
- Professional naming for public deployment
- Scalable pattern for multiple packages

The omnix integration (`nix/modules/template.nix`) enhances template UX while remaining optional.

This strategy positions `typescript-nix-template` as a high-quality, reusable template following the same standards as `python-nix-template`.
