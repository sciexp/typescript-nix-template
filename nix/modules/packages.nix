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
        docs = pkgs.buildNpmPackage {
          pname = "test-starlight-docs";
          version = "0.0.1";

          src = ../..;

          buildInputs = with pkgs; [
            vips
          ];

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          npmDepsHash = lib.fakeSha256;

          installPhase = ''
            runHook preInstall
            cp -pr --reflink=auto dist $out/
            runHook postInstall
          '';
        };

        default = docs;
      };
    };
}
