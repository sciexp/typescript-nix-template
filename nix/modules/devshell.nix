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
      devShells = {
        default = pkgs.mkShell {
          name = "test-starlight-dev";
          inputsFrom = [ config.pre-commit.devShell ];
          packages = with pkgs; [
            # Core development tools
            bun
            nodejs
            just
            git

            # Secrets management
            age
            sops
            ssh-to-age

            # CI/CD tools
            gh
            act

            # Git environment setup
            config.packages.set-git-env
          ];

          shellHook = ''
            export REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            set-git-env
            printf "\n$GIT_REPO_NAME $GIT_REF $GIT_SHA_SHORT\n\n"
          '';
        };
      };
    };
}
