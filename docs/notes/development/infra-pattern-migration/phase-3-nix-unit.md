---
title: "Phase 3: nix-unit testing"
description: Add nix-unit for testing nix expressions via flake checks
---

This phase adds nix-unit for testing nix expressions, integrated with `nix flake check`.

## Current state

**Nix testing**: None

The template currently has no mechanism to test nix expressions.
Errors are only discovered during evaluation or build time.

## Target state

**modules/checks/nix-unit.nix**:
```nix
{ inputs, self, ... }:
{
  perSystem = { system, ... }: {
    nix-unit.inputs = {
      inherit (inputs) nixpkgs flake-parts;
      inherit self;
    };

    nix-unit.tests = {
      # Metadata tests
      testFlakeHasPackages = {
        expr = builtins.hasAttr "packages" self;
        expected = true;
      };

      testFlakeHasDevShells = {
        expr = builtins.hasAttr "devShells" self;
        expected = true;
      };

      # System-specific tests
      testPackagesForSystem = {
        expr = builtins.hasAttr system self.packages;
        expected = true;
      };
    };
  };
}
```

**Benefits**:
- Tests run as part of `nix flake check`
- Pure nix expressions (no side effects)
- Fast feedback on structural changes
- Documents expected flake behavior

## Migration steps

### Step 1: Add nix-unit input

Edit `flake.nix` inputs section:

```nix
inputs = {
  # ... existing inputs ...

  nix-unit.url = "github:nix-community/nix-unit";
  nix-unit.inputs.nixpkgs.follows = "nixpkgs";
  nix-unit.inputs.flake-parts.follows = "flake-parts";
  nix-unit.inputs.treefmt-nix.follows = "treefmt-nix";
};
```

### Step 2: Register nix-unit module

Update `modules/flake-parts.nix`:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.nix-unit.modules.flake.default
  ];
}
```

### Step 3: Create checks directory

```bash
mkdir -p modules/checks
```

### Step 4: Create nix-unit.nix

Create `modules/checks/nix-unit.nix`:

```nix
{ inputs, self, ... }:
{
  perSystem =
    { system, ... }:
    {
      nix-unit.inputs = {
        inherit (inputs) nixpkgs flake-parts;
        inherit self;
      };

      nix-unit.tests = {
        # TC-001: Metadata - flake outputs exist
        testMetadataFlakeOutputsExist = {
          expr =
            (builtins.hasAttr "packages" self)
            && (builtins.hasAttr "devShells" self)
            && (builtins.hasAttr "checks" self);
          expected = true;
        };

        # TC-002: System-specific outputs
        testSystemPackagesExist = {
          expr = builtins.hasAttr system self.packages;
          expected = true;
        };

        testSystemDevShellsExist = {
          expr = builtins.hasAttr system self.devShells;
          expected = true;
        };

        # TC-003: Default outputs accessible
        testDefaultDevShellExists = {
          expr = builtins.hasAttr "default" self.devShells.${system};
          expected = true;
        };

        # TC-004: Template exports
        testTemplateExists = {
          expr = builtins.hasAttr "templates" self;
          expected = true;
        };
      };
    };
}
```

### Step 5: Update flake.lock

```bash
nix flake update nix-unit
```

### Step 6: Run tests

```bash
nix flake check --impure
```

## Test patterns

### Pattern 1: Attribute existence

```nix
testAttributeExists = {
  expr = builtins.hasAttr "key" someAttrSet;
  expected = true;
};
```

### Pattern 2: List membership

```nix
testListContains = {
  expr = builtins.elem "item" someList;
  expected = true;
};
```

### Pattern 3: Sorted comparison

```nix
testExpectedKeys = {
  expr = builtins.sort builtins.lessThan (builtins.attrNames config);
  expected = [ "bar" "baz" "foo" ];
};
```

### Pattern 4: Type checking

```nix
testIsFunction = {
  expr = builtins.isFunction someModule;
  expected = true;
};
```

## Verification

### V1: nix-unit tests pass

```bash
nix flake check --impure 2>&1 | grep -A 5 "test result"
```

Expected: `test result: ok. N passed; 0 failed`

### V2: Tests appear in checks output

```bash
nix flake show 2>&1 | grep -A 3 "checks"
```

Expected: Shows checks for each system.

### V3: Individual test runnable

```bash
nix build .#checks.x86_64-linux.nix-unit-tests --print-build-logs
```

Expected: Build succeeds with test output.

## Rollback

If verification fails:

```bash
git checkout HEAD -- modules/flake-parts.nix flake.nix
rm -rf modules/checks/
nix flake update
```

## Adding more tests

### Shell-based validation checks

Create `modules/checks/validation.nix` for more complex validations:

```nix
{ self, config, ... }:
{
  perSystem = { pkgs, ... }: {
    checks = {
      example-validation = pkgs.runCommand "example-validation" { } ''
        echo "Running validation..."
        ${if builtins.hasAttr "packages" self then
          ''echo "OK: packages found"''
        else
          ''echo "ERROR: packages not found" >&2 && exit 1''
        }
        touch $out
      '';
    };
  };
}
```

### Test code allocation

Reserve test code ranges for organization:
- TC-001 to TC-010: Metadata tests
- TC-011 to TC-020: Structure tests
- TC-021 to TC-030: Feature tests
- TC-031+: Custom tests

## Dependencies

- Phase 1 (import-tree) must be complete
- Phase 2 (treefmt-nix) recommended for consistency

## Blocked by

- Phase 1

## Blocks

- Phase 4 (CI refactor) - needs working `nix flake check`

## Notes

nix-unit warnings during `nix flake check` are expected and harmless:
- "unknown setting allowed-users/trusted-users"
- "--gc-roots-dir not specified"
- "input has an override for non-existent input self"

These are internal nix-unit mechanisms and do not indicate problems.

Tests should be pure nix expressions without side effects.
For tests requiring shell execution, use `pkgs.runCommand` in a separate check.
