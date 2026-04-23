# OpenClaw Tool: read-file
#
# Safely reads a file within the OpenClaw workspace.
# Supports text files with optional encoding detection.
# Returns file contents as JSON for easy parsing by the agent.

{
  pkgs,
  ...
}:

{
  name = "read-file";
  description = "Read a file from the OpenClaw workspace";
  permissions = "0750";

  usage = "read-file <path> [--lines=N] [--offset=N] [--encoding=ENC]";

  arguments = [
    {
      name = "path";
      desc = "Relative or absolute path to file";
      default = "required";
    }
    {
      name = "--lines";
      desc = "Read only N lines";
      default = "1000";
    }
    {
      name = "--offset";
      desc = "Start from line N (requires --lines)";
      default = "0";
    }
    {
      name = "--encoding";
      desc = "Force encoding: utf-8, base64, hex, auto";
      default = "auto";
    }
  ];

  examples = [
    "read-file my-project/TODO.md"
    "read-file my-project/data.json --lines=50"
    "read-file my-project/large.log --lines=50 --offset=100"
    "read-file my-project/image.png --encoding=base64"
  ];

  dependencies = with pkgs; [
    coreutils
    file
    jq
    xxd
  ];

  script = ./Bash/read-file.sh;
}
