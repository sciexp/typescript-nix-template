{ inputs, ... }:
{
  imports = [
    (inputs.git-hooks + /flake-module.nix)
  ];
  perSystem =
    {
      config,
      self',
      pkgs,
      lib,
      ...
    }:
    {
      pre-commit.settings = {
        hooks = {
          nixfmt-rfc-style.enable = true;
          biome.enable = true;
        };
      };
    };
}
