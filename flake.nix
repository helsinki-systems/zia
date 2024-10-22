{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
          inherit (pkgs) rustPackages;
        in
        {
          packages = {
            zia-client = pkgs.callPackage ./derivation.nix {
              cargoToml = ./zia-client/Cargo.toml;
            };

            zia-server = pkgs.callPackage ./derivation.nix {
              cargoToml = ./zia-server/Cargo.toml;
            };
          };
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              # Compiler and linker
              rustPackages.rustc
              clang_15
              llvmPackages.lld
              # Native dependencies
              pkg-config
              rustPackages.cargo
              # Utilities
              cargo-deny
              cargo-outdated
              rustPackages.clippy
              rustPackages.rustfmt
            ];

            RUST_SRC_PATH = "${rustPackages.rustPlatform.rustLibSrc}";
            CI_COMMIT_SHA = builtins.getEnv "CI_COMMIT_SHA";
          };
        }
      ) // {
      overlays.default = _: prev: {
        inherit (self.packages."${prev.system}") zia-client zia-server;
      };

      nixosModules = {
        zia-server = import ./nixos-modules/zia-server.nix;
      };
    };
}
