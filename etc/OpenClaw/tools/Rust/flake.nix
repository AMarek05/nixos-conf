{
  description = "Dev environment for OpenClaw Rust tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      utils,
      ...
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustc
            rustfmt
            rust-analyzer
            clippy
          ];

          shellHook = ''
            echo "🦀 Rust Dev Environment Loaded"
          '';
        };
      }
    );
}
