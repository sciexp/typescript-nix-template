{ inputs, ... }:
{
  imports = [
    # flake-parts.flakeModules.modules deferred until needed for complex module composition
    # nix-unit will be added in Phase 3
  ];
}
