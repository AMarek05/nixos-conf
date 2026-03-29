{
  description = "C/C++ devel flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      stdenv = pkgs.stdenv;
      # stdenv = pkgs.clangStdenv;
    in
    {
      devShells.${system}.default = pkgs.mkShell.override { inherit stdenv; } {
        nativeBuildInputs = with pkgs; [
          cmake
          ninja
          gnumake
          clang-tools
          gdb
          ccache
          pkg-config

          gcc
        ];

        buildInputs = with pkgs; [
          boost
          openssl
          fmt
          eigen

          glew
          glfw
          glm
        ];

        shellHook = ''
          export CPATH="$(${stdenv.cc}/bin/c++ -E -x c++ - -v < /dev/null 2>&1 \
                     | sed -n '/^ /p' \
                     | sed 's/^ //' \
                     | tr '\n' ':')"

          export CPLUS_INCLUDE_PATH="$CPATH"

          # Point clangd to the correct driver (the wrapper)
          export CLANGD_FLAGS="--query-driver=${stdenv.cc}/bin/c++,$(which ${stdenv.cc.targetPrefix}c++)"
        '';
      };
    };
}
