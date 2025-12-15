---
title: "Phase 2: treefmt-nix integration"
description: Add unified formatting with treefmt-nix for nix and TypeScript files
---

This phase adds treefmt-nix for unified code formatting, integrating with the existing biome configuration.

## Current state

**Formatting approach**: biome via pre-commit hooks

**nix/modules/pre-commit.nix (current)**:
```nix
{ inputs, ... }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem = { pkgs, ... }: {
    pre-commit.settings = {
      hooks = {
        nixfmt-rfc-style.enable = true;
        biome.enable = true;
        gitleaks.enable = true;
      };
    };
  };
}
```

**biome.json**: External configuration for TypeScript/JSON formatting

**Limitations**:
- No `nix fmt` command available
- No `treefmt` check in `nix flake check`
- Formatting tools not unified under single command

## Target state

**modules/formatting.nix (target)**:
```nix
{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks.flakeModule
  ];

  perSystem = { pkgs, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.nixfmt.enable = true;
      programs.biome = {
        enable = true;
        includes = [ "*.ts" "*.tsx" "*.js" "*.json" "*.astro" ];
      };
    };

    pre-commit.settings = {
      hooks.treefmt.enable = true;
      hooks.gitleaks.enable = true;
    };
  };
}
```

**Benefits**:
- `nix fmt` formats entire project
- `treefmt` available in devshell
- Automatic `checks.treefmt` in `nix flake check`
- Single configuration point for all formatters

## Migration steps

### Step 1: Add treefmt-nix input

Edit `flake.nix` inputs section:

```nix
inputs = {
  # ... existing inputs ...

  treefmt-nix.url = "github:numtide/treefmt-nix";
  treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
};
```

### Step 2: Create formatting.nix

Create `modules/formatting.nix`:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks.flakeModule
  ];

  perSystem = { pkgs, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";

      # Nix formatting
      programs.nixfmt.enable = true;

      # TypeScript/JavaScript/JSON via biome
      programs.biome = {
        enable = true;
        includes = [
          "*.ts"
          "*.tsx"
          "*.js"
          "*.jsx"
          "*.json"
          "*.astro"
        ];
      };
    };

    pre-commit.settings = {
      hooks.treefmt.enable = true;
      hooks.gitleaks.enable = true;
    };
  };
}
```

### Step 3: Update devshell integration

Ensure `modules/dev-shell.nix` inherits pre-commit:

```nix
{
  perSystem = { pkgs, config, ... }: {
    devShells.default = pkgs.mkShell {
      inputsFrom = [
        config.pre-commit.devShell
      ];
      # ... packages ...
    };
  };
}
```

### Step 4: Remove old pre-commit module

Delete `nix/modules/pre-commit.nix` (if not already removed in Phase 1).

### Step 5: Update flake.lock

```bash
nix flake update treefmt-nix
```

### Step 6: Test formatting

```bash
nix fmt
treefmt --check .
```

## Verification

### V1: treefmt check passes

```bash
nix flake check --impure
```

Expected: `checks.x86_64-linux.treefmt` passes (or your system).

### V2: nix fmt works

```bash
nix fmt
```

Expected: Formats all nix and TypeScript files.

### V3: treefmt available in devshell

```bash
nix develop -c treefmt --help
```

Expected: Shows treefmt help.

### V4: Pre-commit hook works

```bash
nix develop -c pre-commit run treefmt --all-files
```

Expected: Runs treefmt on all files.

### V5: biome.json still respected

```bash
nix develop -c biome check packages/docs/src/
```

Expected: Uses biome.json configuration.

## Rollback

If verification fails:

```bash
git checkout HEAD -- modules/formatting.nix flake.nix
nix flake update
```

## Configuration options

### Option A: Keep biome.json separate (recommended)

treefmt invokes biome which reads `biome.json`.
No changes to biome.json needed.

### Option B: Inline biome config in nix

```nix
programs.biome = {
  enable = true;
  settings = {
    formatter = {
      indentStyle = "space";
      indentWidth = 2;
    };
  };
};
```

Not recommended - keeps two config locations.

### Option C: treefmt-only (remove biome hook)

If biome is only used for formatting (not linting), treefmt handles it entirely.
The `hooks.biome` in pre-commit can be removed.

## Dependencies

- Phase 1 (import-tree) must be complete

## Blocked by

- Phase 1

## Blocks

- Phase 4 (CI refactor) - needs treefmt check for CI validation

## Notes

The infra repo uses a minimal treefmt config with just `nixfmt` enabled.
For typescript-nix-template, we extend this with biome for TypeScript.

treefmt-nix automatically:
- Creates `formatter` output for `nix fmt`
- Creates `checks.treefmt` for `nix flake check`
- Provides `treefmt` in devshell via pre-commit integration

The `projectRootFile = "flake.nix"` ensures treefmt finds the project root correctly across worktrees.
