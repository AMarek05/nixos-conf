# OpenClaw Tool: delete-file
#
# Safely deletes files or directories within the OpenClaw workspace.
# Defaults to trash (recoverable) instead of permanent deletion.
{
  pkgs,
  cfg,
  ...
}:

{
  name = "delete-file";
  description = "Delete files or directories in the OpenClaw workspace (trashes by default)";
  permissions = "0750";
  usage = "delete-file <path> [--recursive|-r] [--force|-f] [--permanent]";
  arguments = [
    {
      name = "path";
      desc = "Path to file or directory to delete";
      default = "required";
    }
    {
      name = "--recursive";
      desc = "Required to delete directories";
      default = "false";
    }
    {
      name = "--force";
      desc = "Skip confirmation prompt for directories";
      default = "false";
    }
    {
      name = "--permanent";
      desc = "Permanently delete instead of trashing (irreversible!)";
      default = "false";
    }
  ];
  examples = [
    "delete-file my-project/old-script.py"
    "delete-file abandoned-project --recursive"
    "delete-file sensitive-data.log --permanent --force"
  ];

  dependencies = with pkgs; [
    coreutils
    jq
    trash-cli
  ];

  script = ./Bash/delete-file.sh;
}
