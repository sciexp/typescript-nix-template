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
      packages = {
        # Default package - will add docs build later
        # For now, set-git-env is available from git-env module
      };
    };
}
