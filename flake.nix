{
  description = "typescript-nix-template: TypeScript monorepo with Astro, Bun, and Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.flake = false;

    # playwright browsers pinned to match package.json (@playwright/test version)
    # sync this when upgrading @playwright/test in packages/docs/package.json
    playwright-web-flake.url = "github:pietdevries94/playwright-web-flake/1.56.1";
    playwright-web-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = with builtins; map (fn: ./nix/modules/${fn}) (attrNames (readDir ./nix/modules));
    };
}
