# OpenClaw Tool: search-files
#
# Searches for files or content within the OpenClaw workspace.
# Uses ripgrep for fast, efficient searching.

{
  pkgs,
  ...
}:

{
  name = "search-files";
  description = "Search for files or content in the OpenClaw workspace";
  permissions = "0750";

  usage = "search-files <pattern> [--path <dir>] [--type <type>] [--max-results <n>] [--content|-c] [--case-sensitive|-s]";

  arguments = [
    {
      name = "pattern";
      desc = "Search pattern (regex supported)";
      default = "required";
    }
    {
      name = "--path";
      desc = "Directory to search (relative to workspace)";
      default = "workspace root";
    }
    {
      name = "--type";
      desc = "Filter by type: file, dir, symlink (only applies to filename search)";
      default = "all";
    }
    {
      name = "--max-results";
      desc = "Maximum results to return";
      default = "100";
    }
    {
      name = "--content|-c";
      desc = "Search inside file contents instead of filenames";
      default = "false";
    }
    {
      name = "--case-sensitive|-s";
      desc = "Enforce case matching";
      default = "false";
    }
  ];

  examples = [
    "search-files \"\\.txt$\""
    "search-files \"error\" --content --path=logs"
    "search-files \"TODO\" --content --max-results=50"
  ];

  dependencies = with pkgs; [
    fd
    coreutils
    ripgrep
    jq
  ];

  script = ./Bash/search-files.sh;
}
