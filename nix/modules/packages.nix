{
  inputs,
  ...
}:
{
  perSystem =
    {
      config,
      self',
      pkgs,
      lib,
      ...
    }:
    {
      # nix build
      packages = rec {
        # Inherit set-git-env from git-env module
        inherit (config.packages) set-git-env;

        # Default package - will add docs build later
        default = set-git-env;
      };
    };
}
