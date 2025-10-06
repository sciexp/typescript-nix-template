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

    # https://omnix.page/om/init.html#spec
    om.templates.typescript-nix-template = {
      template = templates.default;
      params = [
        {
          name = "package-scope";
          description = "npm package scope (e.g., @myorg)";
          placeholder = "@sciexp";
        }
        {
          name = "git-org";
          description = "GitHub organization or user name";
          placeholder = "sciexp";
        }
        {
          name = "author";
          description = "Author name";
          placeholder = "Your Name";
        }
        {
          name = "author-email";
          description = "Author email";
          placeholder = "your.email@example.com";
        }
        {
          name = "project-description";
          description = "Project description for documentation";
          placeholder = "TypeScript project template with Nix, Bun workspaces, and semantic-release";
        }
        {
          name = "github-ci";
          description = "Include GitHub Actions workflow configuration";
          paths = [ ".github" ];
          value = true;
        }
        {
          name = "nix-template";
          description = "Keep the flake template in the project";
          paths = [
            "**/template.nix"
          ];
          value = false;
        }
      ];
      tests = {
        default = {
          params = {
            package-scope = "@example";
            git-org = "example-org";
            author = "Jane Doe";
            author-email = "jane@example.com";
          };
          asserts = {
            source = {
              "package.json" = true;
              "flake.nix" = true;
              ".github/workflows/ci.yaml" = true;
              "packages/docs/package.json" = true;
              "nix/modules/template.nix" = false;
            };
            packages.default = { };
          };
        };
      };
    };
  };
}
