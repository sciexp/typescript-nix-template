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
          gitleaks = {
            enable = true;
            name = "gitleaks";
            entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged --verbose --redact";
            language = "system";
            pass_filenames = false;
          };
        };
      };
    };
}
