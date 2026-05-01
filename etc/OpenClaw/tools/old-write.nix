{ pkgs, ... }:

let
  write-binary = pkgs.stdenv.mkDerivation {
    pname = "openclaw-write-binary";
    version = "1.2.0";

    # Point to the local file
    src = ./Rust/write.rs;

    nativeBuildInputs = [ pkgs.rustc ];

    dontUnpack = true;

    # Compile the source file
    buildPhase = ''
      rustc -O $src -o write-bin
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp write-bin $out/bin/write-bin
    '';
  };

in
{
  name = "old-write";
  description = "Safe, but unnecessary, binary-level file writer for OpenClaw - example for Rust tool.";
  permissions = "0750";
  usage = "write <filepath> <content> [--append]";

  arguments = [
    {
      name = "filepath";
      desc = "Absolute path. MUST start with /var/lib/openclaw/.";
      default = "required";
    }
    {
      name = "content";
      desc = "The string content to write.";
      default = "required";
    }
    {
      name = "--append";
      desc = "Append content instead of overwriting.";
      default = "false";
    }
  ];

  examples = [
    "write /var/lib/openclaw/notes.txt 'Hello World'"
    "write /var/lib/openclaw/notes.txt 'from Claw!' --append"
  ];

  dependencies = [
    write-binary
  ];

  script = ''
    #!/usr/bin/env bash
    set -euo pipefail
    exec ${write-binary}/bin/write-bin "$@"
  '';
}
