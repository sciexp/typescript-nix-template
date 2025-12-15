{ inputs, ... }:

{
  flake = rec {
    templates.default = {
      description = "A TypeScript monorepo template with Nix, Bun workspaces, and semantic-release";
      path = builtins.path { path = inputs.self; };
      welcomeText = ''
        Welcome to typescript-nix-template!

        If you're reusing a preexisting directory for PROJECT_DIRECTORY you
        may need to run `direnv revoke $PROJECT_DIRECTORY` to unload the environment
        before proceeding.

        Otherwise, don't forget to `cd` into your new project directory.

        Quick start:

        ```bash
        # If you don't have nix and direnv installed
        make -n bootstrap

        # Initialize git repository and load nix environment
        git init && git commit --allow-empty -m "initial commit (empty)" && git add . && direnv allow

        # Enter development shell
        nix develop

        # Install dependencies
        bun install

        # Start development server
        just dev

        # Run tests
        just test
        ```

        Customization:

        To adapt this template for your project:

        1. Update root package.json:
           - Change "name" to your project name
           - Update "repository.url" to your repository
           - Update "description"

        2. Customize packages:
           - Rename packages/docs/ to your package name
           - Update packages/{name}/package.json (name, description)
           - Update packages/{name}/wrangler.jsonc (name, routes)

        3. Update documentation:
           - Update README.md with your package list
           - Update CONTRIBUTING.md with your scope examples

        4. Update CI workflows (if package names changed):
           - Update .github/workflows/ci.yaml matrix
           - Update .github/workflows/release.yaml matrix

        See README.md for full documentation.
      '';
    };
  };
}
