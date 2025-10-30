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
      system,
      ...
    }:
    let
      # Playwright driver from versioned flake (synced with package.json)
      playwrightDriver = inputs.playwright-web-flake.packages.${system}.playwright-driver;
    in
    {
      devShells = {
        default = pkgs.mkShell {
          name = "typescript-nix-template-dev";
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
            gitleaks

            # CI/CD tools
            gh
            act
            cachix

            # E2E testing browsers from playwright-web-flake (pinned to 1.56.1)

            # Git environment setup
            config.packages.set-git-env
          ];

          shellHook = ''
            export REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            set-git-env

            # Playwright browser configuration (version-locked via flake input)
            export PLAYWRIGHT_BROWSERS_PATH="${playwrightDriver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true

            printf "\n$GIT_REPO_NAME $GIT_REF $GIT_SHA_SHORT\n\n"
          '';
        };
      };
    };
}
