{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
    pname = "image-proxy";
    version = "0.1.0";

    src = lib.cleanSource ./.;
    cargoLock.lockFile = ./Cargo.lock;

    meta = {
        description = "Translates SillyTavern OpenAI image calls to MiniMax.";
        license = lib.licenses.mit;
        mainProgram = "image-proxy";
    };
}
