# OpenClaw Tool: sed-inplace
#
# In-place line editing via GNU sed.
# Delete, replace, insert, or substitute without rewriting entire files.

{
  pkgs,
  ...
}:

{
  name = "sed-inplace";
  description = "In-place line editing via GNU sed. Delete/replace/insert without rewriting entire files.";
  permissions = "0750";

  usage = "sed-inplace <file> <--delete <range> | --replace <pat> <rep> | --insert <line> <text> | --substitute <expr>>";

  arguments = [
    {
      name = "file";
      desc = "The target file to edit (relative to workspace or absolute)";
      default = "required";
    }
    {
      name = "--delete";
      desc = "Delete a specific line or range of lines (e.g., '5' or '5,10')";
      default = "optional";
    }
    {
      name = "--replace";
      desc = "Globally replace a string pattern with a replacement string";
      default = "optional";
    }
    {
      name = "--insert";
      desc = "Insert text exactly at the specified line number";
      default = "optional";
    }
    {
      name = "--substitute";
      desc = "Execute a raw GNU sed expression for advanced edits";
      default = "optional";
    }
  ];

  examples = [
    "sed-inplace src/config.js --delete 10,15"
    "sed-inplace README.md --replace \"old-text\" \"new-text\""
    "sed-inplace app.py --insert 42 \"import os\""
    "sed-inplace index.html --substitute \"s/<title>.*<\\/title>/<title>New<\\/title>/g\""
  ];

  dependencies = with pkgs; [
    gnused
    coreutils
    jq
  ];

  script = ./Bash/sed-inplace.sh;
}
