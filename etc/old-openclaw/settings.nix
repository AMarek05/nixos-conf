{
  lib,
  ...
}:
let
  # Path to the directory containing your module files
  modulesDir = ./modules;

  # Function to get all .nix files in a directory
  getNixFiles =
    dir:
    map (name: dir + "/${name}") (
      lib.attrNames (
        lib.filterAttrs (
          name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
        ) (builtins.readDir dir)
      )
    );

in
{
  imports = getNixFiles modulesDir;
}
