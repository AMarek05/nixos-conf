# OpenClaw Tool: list-dir
#
# Lists directory contents within the OpenClaw workspace.
# Returns structured JSON with file metadata.

{
  pkgs,
  ...
}:

{
  name = "list-dir";
  description = "List directory contents in the OpenClaw workspace";
  permissions = "0750";

  usage = "list-dir [path] [--recursive|-r] [--hidden|-a] [--long|-l]";

  arguments = [
    {
      name = "path";
      desc = "Directory to list";
      default = "workspace root";
    }
    {
      name = "--recursive";
      desc = "Traverse subdirectories";
      default = "false";
    }
    {
      name = "--hidden";
      desc = "Show hidden files (excluding config)";
      default = "false";
    }
    {
      name = "--long";
      desc = "Include size, permissions, and timestamps";
      default = "false";
    }
  ];

  examples = [
    "list-dir my-project"
    "list-dir my-project/src --recursive"
    "list-dir . --long --hidden"
  ];

  dependencies = with pkgs; [
    coreutils
    jq
    fd
  ];

  script = ./Bash/list-dir.sh;
}
