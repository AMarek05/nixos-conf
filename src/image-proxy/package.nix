{ lib, rustPlatform }:
let
  source = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };
in
rustPlatform.buildRustPackage {
  pname = "image-proxy";
  version = "0.1.0";

  src = source;
  cargoLock.lockFile = "${source}/Cargo.lock";

  meta = {
    description = "Translates SillyTavern OpenAI image calls to MiniMax.";
    license = lib.licenses.mit0;
    mainProgram = "image-proxy";
  };
}
