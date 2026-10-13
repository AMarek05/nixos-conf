{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.hmModules.user.util;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cargo
      rustc
      rust-analyzer
      clippy
      rustfmt
    ];

    home.sessionVariables = {
      RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };
  };
}
