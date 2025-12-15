{ inputs, self, ... }:
{
  perSystem =
    { system, ... }:
    {
      nix-unit.inputs = {
        inherit (inputs)
          nixpkgs
          flake-parts
          treefmt-nix
          import-tree
          ;
        inherit self;
      };

      nix-unit.tests = {
        # Metadata Tests

        # TC-001: Flake Structure Smoke Test
        # Validates flake has required top-level outputs
        testMetadataFlakeOutputsExist = {
          expr =
            (builtins.hasAttr "devShells" self)
            && (builtins.hasAttr "checks" self)
            && (builtins.hasAttr "templates" self);
          expected = true;
        };

        # System-Specific Tests

        # TC-002: System Packages Exist
        # Validates system-specific devShells output exists
        testSystemDevShellsExist = {
          expr = builtins.hasAttr system self.devShells;
          expected = true;
        };

        # TC-003: Default DevShell Exists
        # Validates default devShell is accessible for current system
        testDefaultDevShellExists = {
          expr = builtins.hasAttr "default" self.devShells.${system};
          expected = true;
        };

        # TC-004: System Checks Exist
        # Validates system-specific checks output exists
        testSystemChecksExist = {
          expr = builtins.hasAttr system self.checks;
          expected = true;
        };

        # Feature Tests

        # TC-005: Template Exports
        # Validates templates output exists and is not empty
        testTemplateExists = {
          expr =
            builtins.hasAttr "templates" self && (builtins.length (builtins.attrNames self.templates) > 0);
          expected = true;
        };

        # TC-006: Formatter Available
        # Validates formatter is configured for current system
        testFormatterExists = {
          expr = builtins.hasAttr system self.formatter;
          expected = true;
        };
      };
    };
}
