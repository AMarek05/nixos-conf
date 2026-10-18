{
  lib,
  inputs,
  ...
}:

lib.my.mkHostModules {
  namespace = "hmModules";
  basePath = "${inputs.self}/modules/hm";
  entries = [
    {
      name = "user";
      sub = [
        "env"
        "git"
        "ssh"
        "util"
      ];
    }
    {
      name = "apps";
      sub = [
        "dolphin"
        "forge"
        "nvf"
        "stylix"
        {
          name = "packages";
          sub = [
            "browsers"
            "gaming"
            "media"
            "productivity"
            "system"
          ];
        }
      ];
    }
    {
      name = "caelestia";
      createOption = false;
    }
    {
      name = "hyprland";
      sub = [
        "onStart"
      ];
    }
    {
      name = "shell";
      sub = [
        "links"
        {
          name = "starship";
          optional = true;
        }
        "zsh"
      ];
    }
    {
      name = "terminal";
      sub = [
        "ghostty"
        "man"
        "tmux"
      ];
    }
  ];
}
