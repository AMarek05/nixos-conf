{ lib }:
let
  toLua =
    v:
    if builtins.isBool v then
      (if v then "true" else "false")
    else if builtins.isString v then
      "\"${lib.replaceStrings [ "\\" "\"" "\n" ] [ "\\\\" "\\\"" "\\n" ] v}\""
    else if builtins.isInt v || builtins.isFloat v then
      toString v
    else if builtins.isList v then
      "{ " + lib.concatMapStringsSep ", " toLua v + " }"
    else if builtins.isAttrs v then
      "{ "
      + lib.concatStringsSep ", " (
        lib.mapAttrsToList (n: val: "${n} = ${toLua val}") (lib.filterAttrs (n: v: v != null) v)
      )
      + " }"
    else
      "nil";
in
toLua
