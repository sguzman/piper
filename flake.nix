{
  description = "A Nix flake for building the piper TTS package from local sources";

  inputs = {
    # Pinning nixpkgs to a specific version for reproducibility.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # A list of systems to support. You can add or remove systems here.
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # A helper function to generate outputs for each supported system.
      forEachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

    in
    {
      # `packages` defines the buildable outputs of the flake.
      packages = forEachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };

          # Import the package definition from your default.nix.txt
          piperPackageOriginal = pkgs.callPackage ./default.nix.txt { };

        in
        {
          # This overrides the `src` attribute of the original package
          # to point to your local source code directory instead of fetching
          # it from GitHub.
          piper = piperPackageOriginal.overrideAttrs (oldAttrs: {
            # Use the local './src' directory as the source.
            src = ./src;

            # The original derivation has a `hash` for the fetched source.
            # We set it to null because we are using local files.
            # Nix's purity checks are still maintained as the source
            # is now the flake itself.
            hash = null;
          });
        });

      # The `defaultPackage` is a convenient alias for `nix build` and `nix run`.
      defaultPackage = forEachSystem (system: self.packages.${system}.piper);

      # `devShells` defines development environments.
      devShells = forEachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          # This default shell provides all the build-time dependencies
          # required to work on the piper package.
          default = pkgs.mkShell {
            # Pulls in all build inputs from the piper derivation.
            inputsFrom = [ self.packages.${system}.piper ];
          };
        });
    };
}
