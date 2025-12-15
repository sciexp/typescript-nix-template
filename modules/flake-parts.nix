{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    # nix-unit will be added in Phase 3
  ];
}
