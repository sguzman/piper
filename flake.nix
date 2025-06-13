{
  description = "A Nix flake for building the piper TTS package using default.nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # Use flake-utils to simplify supporting multiple systems
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Import nixpkgs for the specific system
        pkgs = import nixpkgs { inherit system; };

        # Import the package from your default.nix file
        piper-import = pkgs.callPackage ./default.nix { };
      in
      {
        # The 'default' package is built when you run `nix build`
        packages.default = piper-import.overrideAttrs (oldAttrs: {
          # This is the key change: instead of fetching from GitHub,
          # we use the local source code in the current directory.
          src = ./.;

          # The original derivation has a `hash` for the fetched source.
          # We remove it because we are using local, trusted files.
          hash = null;
          
          # We can also override the version to indicate a local build
          version = "local-dev";
        });

        # Default package for `nix run`
        defaultPackage = self.packages.${system}.default;

        # Development shell for `nix develop`
        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
        };
      });
}

