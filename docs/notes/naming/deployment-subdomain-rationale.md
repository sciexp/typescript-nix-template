# Subdomain strategy for sciexp organization

## Problem

Initial recommendation of `docs.scientistexperience.net` was too prominent for a template demonstration repository.
The `docs.*` subdomain should be reserved for actual sciexp organization documentation, not consumed by template projects.

## Solution

Use project-based subdomain pattern: `{project}.scientistexperience.net`

## Sciexp subdomain hierarchy

### Top-level (reserved, precious namespace)

```
scientistexperience.net           # main org site
www.scientistexperience.net       # main org site
docs.scientistexperience.net      # org-wide documentation
api.scientistexperience.net       # org-wide API gateway
blog.scientistexperience.net      # org blog
```

### Project level (scalable)

```
{project}.scientistexperience.net              # project main site
{component}.{project}.scientistexperience.net  # project components (optional)
```

## For typescript-nix-template

| Component | Value |
|-----------|-------|
| Package | `@typescript-nix-template/docs` |
| Worker | `ts-nix-docs` |
| Route | `ts-nix.scientistexperience.net` |

### Rationale

1. **Namespace preservation**: Doesn't claim `docs.*` root subdomain
2. **Clear identity**: `ts-nix` identifies typescript-nix-template project
3. **Brevity**: Short, memorable (only 6 chars for project identifier)
4. **Room to grow**: Can add `api.ts-nix.*` if template expands
5. **Realistic model**: Shows how real projects would deploy
6. **Consistency**: Aligns with project naming conventions

### Alternative considered

**Route**: `docs.ts-nix.scientistexperience.net`

**Pros:**
- More explicit that this is docs component
- Demonstrates nested subdomain pattern

**Cons:**
- Longer URL
- Potentially overkill for single-package template

**Decision**: Use simpler `ts-nix.scientistexperience.net` because:
- The docs package IS the only/main site
- Users can learn nested pattern when they need multiple components
- Shorter is better for a demonstration site

## Examples for real sciexp projects

### Single-site projects

```
sqlrooms.scientistexperience.net
```

Package structure:
- `@sciexp/sqlrooms` - main application
- Worker: `sqlrooms`
- Route: `sqlrooms.scientistexperience.net`

### Multi-component projects

```
myproject.scientistexperience.net       # main web app
api.myproject.scientistexperience.net   # API backend
docs.myproject.scientistexperience.net  # documentation
```

Package structure:
- `@sciexp/web` - main app (worker: `myproject-web`)
- `@sciexp/api` - API backend (worker: `myproject-api`)
- `@typescript-nix-template/docs` - documentation (worker: `myproject-docs`)

## Pattern for template users

When users fork `typescript-nix-template`, they choose their deployment pattern based on needs.

### Option A: Single-package (simple)

```
myproject.example.com
```

Configuration:
- Package: `@myorg/docs`
- Worker: `myproject`
- Route: `myproject.example.com`

Use when:
- Single public-facing site
- Docs are the main site
- Simple deployment preferred

### Option B: Multi-package (explicit)

```
docs.myproject.example.com
api.myproject.example.com
www.myproject.example.com
```

Configuration:
- Package: `@myorg/docs` → Worker: `myproject-docs` → `docs.myproject.example.com`
- Package: `@myorg/api` → Worker: `myproject-api` → `api.myproject.example.com`
- Package: `@myorg/web` → Worker: `myproject-web` → `www.myproject.example.com`

Use when:
- Multiple public-facing sites
- Clear component separation needed
- Professional multi-service architecture

## Technical notes

### Cloudflare Workers custom domains

Cloudflare Workers support both:
- Simple subdomains: `project.example.com`
- Nested subdomains: `component.project.example.com`

Configuration in `wrangler.jsonc`:
```json
{
  "name": "worker-name",
  "routes": [
    {
      "pattern": "subdomain.example.com",
      "custom_domain": true
    }
  ]
}
```

### DNS requirements

For nested subdomains like `docs.ts-nix.scientistexperience.net`:
1. Create CNAME record: `docs.ts-nix` → Cloudflare Worker
2. Or use Cloudflare dashboard to add custom domain
3. Wrangler can automate this with `custom_domain: true`

## Summary

**For typescript-nix-template:**
- Worker: `ts-nix-docs`
- Route: `ts-nix.scientistexperience.net`

This preserves top-level namespace while providing a clear, professional demonstration deployment.
