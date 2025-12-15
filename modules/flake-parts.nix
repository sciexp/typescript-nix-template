{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules # Enable flake.modules merging
    inputs.nix-unit.modules.flake.default
  ];
}
