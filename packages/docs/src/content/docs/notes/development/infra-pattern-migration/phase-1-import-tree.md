---
title: "Phase 1: import-tree adoption"
description: Migrate from inline readDir to import-tree for deferred module composition
---

This phase migrates the module discovery mechanism from inline `builtins.readDir` to the import-tree pattern used in the infra repository.

## Current state

**flake.nix (current)**:
```nix
outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;
    imports = with builtins;
      map (fn: ./nix/modules/${fn}) (attrNames (readDir ./nix/modules));
  };
```

**Module path**: `nix/modules/` (5 flat files)

**Current modules**:
- `devshell.nix`
- `packages.nix`
- `template.nix`
- `git-env.nix`
- `pre-commit.nix`

## Target state

**flake.nix (target)**:
```nix
outputs = inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
```

**Module path**: `modules/` (hierarchical)

**Target structure**:
```
modules/
├── flake-parts.nix      # Foundational flake-parts imports
├── systems.nix          # System declarations
├── dev-shell.nix        # perSystem devShells.default
├── formatting.nix       # treefmt + pre-commit (Phase 2)
├── packages.nix         # perSystem packages (or use pkgs-by-name)
├── template.nix         # Flake template export
├── checks/              # nix-unit tests (Phase 3)
│   └── nix-unit.nix
└── lib/                 # Custom lib extensions (optional)
    └── default.nix
```

## Migration steps

### Step 1: Add import-tree input

Edit `flake.nix` inputs section:

```nix
inputs = {
  # ... existing inputs ...

  import-tree.url = "github:vic/import-tree";
};
```

### Step 2: Create modules directory

```bash
mkdir -p modules
```

### Step 3: Create flake-parts.nix

Create `modules/flake-parts.nix`:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    # nix-unit will be added in Phase 3
  ];
}
```

### Step 4: Create systems.nix

Create `modules/systems.nix`:

```nix
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
```

### Step 5: Migrate existing modules

Move and adapt existing modules from `nix/modules/` to `modules/`:

| Source | Destination | Changes needed |
|--------|-------------|----------------|
| `nix/modules/devshell.nix` | `modules/dev-shell.nix` | Minor path updates |
| `nix/modules/packages.nix` | `modules/packages.nix` | None expected |
| `nix/modules/template.nix` | `modules/template.nix` | None expected |
| `nix/modules/git-env.nix` | Merge into `dev-shell.nix` | Consolidate |
| `nix/modules/pre-commit.nix` | `modules/formatting.nix` | Refactor in Phase 2 |

### Step 6: Update flake.nix outputs

Replace the outputs section:

```nix
outputs = inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
```

### Step 7: Remove old module directory

```bash
rm -rf nix/modules
rmdir nix  # if empty
```

### Step 8: Update flake.lock

```bash
nix flake update import-tree
```

## Verification

### V1: Flake evaluates without errors

```bash
nix flake check --impure
```

Expected: No evaluation errors. Checks may fail if dependent phases not complete.

### V2: DevShell accessible

```bash
nix develop -c echo "DevShell works"
```

Expected: Shell enters successfully, echoes message.

### V3: Flake outputs exist

```bash
nix flake show
```

Expected: Shows `devShells`, `packages`, `templates` outputs.

### V4: Module auto-discovery works

```bash
nix eval .#debug --apply 'x: builtins.attrNames x' 2>/dev/null || echo "No debug attr yet"
```

Expected: Demonstrates that import-tree discovered modules.

## Rollback

If verification fails:

```bash
git checkout HEAD -- flake.nix nix/
git restore --staged .
rm -rf modules/
```

## Dependencies

- None (this is the foundation phase)

## Blocked by

- Nothing

## Blocks

- Phase 2 (treefmt-nix) - needs module structure
- Phase 3 (nix-unit) - needs flake-parts.nix for imports
- Phase 4 (CI refactor) - needs stable flake structure
- Phase 5 (justfile) - needs working `nix flake check`

## Notes

The import-tree pattern provides automatic module discovery without explicit imports.
Every `.nix` file in `modules/` becomes a flake-parts module.
Subdirectories are recursively discovered.

Key convention: `default.nix` in a subdirectory makes that directory a module container where all sibling `.nix` files are also imported.
